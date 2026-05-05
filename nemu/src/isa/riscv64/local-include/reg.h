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

#ifndef __RISCV_REG_H__
#define __RISCV_REG_H__

#include <common.h>

#define MTVEC_CSR 773
#define MEPC_CSR 833
#define MSTATUS_CSR 768
#define MCAUSE_CSR 834
#define MSCRATCH_CSR 832
#define MIE_CSR 788
#define MIP_CSR 834
#define MTVAL_CSR 835
#define CYCLE_CSR 0xC00
#define CYCLEH_CSR 0xC80

enum {MTVEC_IDX, MEPC_IDX, MSTATUS_IDX, MCAUSE_IDX, MSCRATCH_IDX, MIE_IDX, MIP_IDX, MTVAL_IDX, CYCLE_IDX, CYCLEH_IDX, num};


static inline int check_reg_idx(int idx) {
  IFDEF(CONFIG_RT_CHECK, assert(idx >= 0 && idx < MUXDEF(CONFIG_RVE, 16, 32)));
  return idx;
}

static inline int check_csr_reg_idx(int idx) {
  IFDEF(CONFIG_RT_CHECK, assert(idx >= 0 && idx < num));
  return idx;
}

#define gpr(idx) (cpu.gpr[check_reg_idx(idx)])

#define csr_pr(idx) (cpu.csr_pr[check_csr_reg_idx(idx)])

static inline const char* reg_name(int idx) {
  extern const char* regs[];
  return regs[check_reg_idx(idx)];
}

#endif
