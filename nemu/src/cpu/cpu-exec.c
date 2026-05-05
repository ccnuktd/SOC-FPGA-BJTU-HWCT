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

#include <cpu/cpu.h>
#include <cpu/decode.h>
#include <cpu/difftest.h>
#include <locale.h>
#include <iringbuf.h>
#include <ftrace.h>
#include <../src/monitor/sdb/sdb.h>

/* The assembly code of instructions executed is only output to the screen
 * when the number of instructions executed is less than this value.
 * This is useful when you use the `si' command.
 * You can modify this value as you want.
 */
#define MAX_INST_TO_PRINT 10
#define INST_RINGBUF_LEN 16

CPU_state cpu = {};
uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static bool g_print_step = false;

static iringbuf_node ir_buf[INST_RINGBUF_LEN];
static int iringbuf_index=0;

void device_update();

static void trace_and_difftest(Decode *_this, vaddr_t dnpc)
{
#ifdef CONFIG_ITRACE_COND
  if (CONFIG_ITRACE_COND)
  {
    log_write("%s\n", _this->logbuf);
    iringbuf_index++;
    iringbuf_index=iringbuf_index%INST_RINGBUF_LEN;
    strcpy(ir_buf[iringbuf_index].inst_log, _this->logbuf);
    ir_buf[iringbuf_index].is_bad=0;
  }
#endif
  if (g_print_step)
  {
    IFDEF(CONFIG_ITRACE, puts(_this->logbuf));
  }
  IFDEF(CONFIG_DIFFTEST, difftest_step(_this->pc, dnpc));
#ifdef CONFIG_WATCHPOINT
#ifdef CONFIG_PARALLEL_WP
  if (check_watch_points_parallel() == 0)
#endif
#ifndef CONFIG_PARALLEL_WP
  if (check_watch_points()== 0)
#endif
  {
    nemu_state.state = NEMU_STOP;
    Log("you triggered the watching points please input instruction");
  }
#endif
}

static void exec_once(Decode *s, vaddr_t pc)
{
  #ifdef CONFIG_FTRACE
  check_addr(s->pc,pc,*(&s->isa.inst));
  #endif

  s->pc = pc;
  s->snpc = pc;

  isa_exec_once(s);
  cpu.true_pc=cpu.pc;
  cpu.pc = s->dnpc;

#ifdef CONFIG_ITRACE
  char *p = s->logbuf;
  p += snprintf(p, sizeof(s->logbuf), FMT_WORD ":", s->pc);
  int ilen = s->snpc - s->pc;
  int i;
  uint8_t *inst = (uint8_t *)&s->isa.inst;
#ifdef CONFIG_ISA_x86
  for (i = 0; i < ilen; i++)
  {
#else
  for (i = ilen - 1; i >= 0; i--)
  {
#endif
    p += snprintf(p, 4, " %02x", inst[i]);
  }
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0)
    space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, s->logbuf + sizeof(s->logbuf) - p,
              MUXDEF(CONFIG_ISA_x86, s->snpc, s->pc), (uint8_t *)&s->isa.inst, ilen);
#endif
}

static void execute(uint64_t n)
{
  Decode s;
  for (; n > 0; n--)
  {
    // Increment cycle counter
    #ifdef CONFIG_ISA_riscv
    cpu.cycle++;
    #endif
    
    // Check for pending interrupts only if MIE (bit 3 of mstatus) is enabled
    // This must be done BEFORE exec_once so that the interrupt is taken
    // before the next instruction is executed
    #ifdef CONFIG_ISA_riscv
    word_t mstatus = cpu.csr_pr[2]; // MSTATUS_IDX = 2
    word_t mie = cpu.csr_pr[5];     // MIE_IDX = 5
    word_t mip = cpu.csr_pr[6];     // MIP_IDX = 6
    bool m_en = (mstatus & 0x8) != 0;      // MIE bit = bit 3
    bool mtie = (mie & 0x80) != 0;         // MTIE bit = bit 7 (machine timer interrupt enable)
    bool mtip = (mip & 0x8) != 0;          // MTIP bit = bit 3 (machine timer interrupt pending)
    
    // Check if timer interrupt is pending and enabled
    // If so, take the interrupt BEFORE executing the next instruction
    if (m_en && mtie && mtip) {  // MIE=1, MTIE=1, and MTIP=1
      vaddr_t old_pc = cpu.pc;
      word_t intr_no = isa_query_intr();
      if (intr_no != INTR_EMPTY) {
        vaddr_t intr_addr = isa_raise_intr(intr_no, old_pc);
        cpu.pc = intr_addr;  // Update PC to jump to interrupt handler
        printf("mtvec:0x%08X\n",intr_addr);
        // NOTE: We do NOT execute the next instruction, we jump directly to the handler
        // Skip exec_once and trace_and_difftest for this cycle
        g_nr_guest_inst++;
        IFDEF(CONFIG_DEVICE, device_update());
        continue;  // Skip to next iteration without executing current instruction
      }
    }
    #else
    // For non-RISC-V ISAs
    word_t intr_no = isa_query_intr();
    if (intr_no != INTR_EMPTY) {
      vaddr_t intr_addr = isa_raise_intr(intr_no, cpu.pc);
      cpu.pc = intr_addr;
    }
    #endif
    // if(cpu.pc==0x800000a4){
    //   nemu_state.state = NEMU_STOP;
    // Log("interuppt happen\n");
    // }
    exec_once(&s, cpu.pc);
    g_nr_guest_inst++;
    trace_and_difftest(&s, cpu.pc);
    if (nemu_state.state != NEMU_RUNNING)
      break;
    IFDEF(CONFIG_DEVICE, device_update());
  }
}

static void statistic()
{
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0)
    Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else
    Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}

static void iringbuf_msgs(){
  if(nemu_state.halt_ret == 1){
for(int i=0;i<INST_RINGBUF_LEN;i++){
if(i==iringbuf_index){
printf("->  ");
}
else
printf("    ");
printf("%s\n",ir_buf[i].inst_log);
  }
}
}

void assert_fail_msg()
{
  isa_reg_display();
  statistic();
}

/* Simulate how the CPU works. */
void cpu_exec(uint64_t n)
{
  g_print_step = (n < MAX_INST_TO_PRINT);
  switch (nemu_state.state)
  {
  case NEMU_END:
  case NEMU_ABORT:
  case NEMU_QUIT:
    printf("Program execution has ended. To restart the program, exit NEMU and run again.\n");
    return;
  default:
    nemu_state.state = NEMU_RUNNING;
  }

  uint64_t timer_start = get_time();

  execute(n);

  uint64_t timer_end = get_time();
  g_timer += timer_end - timer_start;

  switch (nemu_state.state)
  {
  case NEMU_RUNNING:
    nemu_state.state = NEMU_STOP;
    break;

  case NEMU_END:
  case NEMU_ABORT:
    Log("nemu: %s at pc = " FMT_WORD,
        (nemu_state.state == NEMU_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) : (nemu_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) : ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
        nemu_state.halt_pc);
    // fall through
  case NEMU_QUIT:
    statistic();
    iringbuf_msgs();
  }
}
