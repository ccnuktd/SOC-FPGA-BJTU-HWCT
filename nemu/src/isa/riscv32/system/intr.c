/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <stdbool.h>

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  /* Trigger an interrupt/exception with ``NO''.
   * Then return the address of the interrupt/exception vector.
   */
  
  // Get current CSR values
  word_t mtvec = cpu.csr_pr[0];  // MTVEC_IDX = 0
  //word_t mepc = cpu.csr_pr[1];   // MEPC_IDX = 1
  word_t mstatus = cpu.csr_pr[2]; // MSTATUS_IDX = 2
  //word_t mcause = cpu.csr_pr[3];  // MCAUSE_IDX = 3
  
  // For machine-mode interrupts: mask with 0x80000000 (bit 31) to indicate interrupt
  // RISC-V MTI (Machine Timer Interrupt) = interrupt number 7
  uint32_t cause = (1 << 31) | (NO & 0x7F);
  
  // Save return address and cause
  cpu.csr_pr[1] = epc;  // MEPC = current PC
  cpu.csr_pr[3] = cause; // MCAUSE = (interrupt_bit << 31) | interrupt_number
  
  // Update MSTATUS: save MIE, clear MIE to disable interrupts during handler
  // MSTATUS layout (RV32):
  // bit 3: MIE (Machine Interrupt Enable)
  // bit 7: MPIE (Machine Previous Interrupt Enable)
  // bit 11-12: MPP (Machine Previous Privilege)
  uint32_t new_mstatus = mstatus;
  new_mstatus &= ~(0x1 << 3); // Clear MIE (disable interrupts immediately when entering handler)
  new_mstatus |= (0x1 << 7);  // Set MPIE = previous MIE (for mret to restore)
  new_mstatus |= (0x3 << 11); // Set MPP to machine mode
  cpu.csr_pr[2] = new_mstatus;
  
  // Return MTVEC as the new PC (interrupt vector)
  return mtvec;
}

word_t isa_query_intr() {
  extern word_t dev_query_intr();
  return dev_query_intr();
}

