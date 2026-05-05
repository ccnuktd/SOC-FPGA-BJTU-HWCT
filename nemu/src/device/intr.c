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
#include <cpu/cpu.h>

// Timer interrupt pending flag (device-level)
static bool timer_intr_pending = false;

void dev_raise_intr() {
  // Set the MTIP bit in MIP register when timer interrupt occurs
  cpu.csr_pr[6] |= 0x8;  // MIP_IDX = 6, MTIP = bit 3
  timer_intr_pending = true;
}

// Device-level query function. Returns interrupt number or INTR_EMPTY.
word_t dev_query_intr() {
  // Hardware timer maps to interrupt number 3
  // (matches the value checked in trap_handler: 0x80000003)
  if (timer_intr_pending) {
    timer_intr_pending = false;
    // Clear the MTIP bit in MIP
    cpu.csr_pr[6] &= ~0x8;  // MIP_IDX = 6
    return 3; // Timer interrupt (matches hardware mapping)
  }
  return INTR_EMPTY;
}

