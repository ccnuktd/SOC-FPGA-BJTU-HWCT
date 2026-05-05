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
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc)
{
  for (int i = 0; i < 32; i++)
  {
    if (ref_r->gpr[i] != cpu.gpr[i])
    {
      printf("ref:gpr[%d] is 0x%08X nemu is 0x%08X\n", i, ref_r->gpr[i], cpu.gpr[i]);
      return false;
    }
  }
  if (ref_r->pc != cpu.pc)
  {
    printf("ref_pc is 0x%08X nemu is 0x%08X\n", ref_r->pc, cpu.pc);
    return false;
  }
  for (int i = 0; i < 4; i++)
  {
    if (ref_r->csr_pr[i] != cpu.csr_pr[i])
    {
      printf("ref_csr[%d] is 0x%08X nemu is 0x%08X\n", i, ref_r->csr_pr[i], cpu.csr_pr[i]);
      return false;
    }
  }

//   0 MTVEC_CSR 
//   1 MEPC_CSR 
//   2 MSTATUS_CSR 
//   3 MCAUSE_CSR 
//   4 MSCRATCH_CSR

  return true;
}

void isa_difftest_attach()
{
}
