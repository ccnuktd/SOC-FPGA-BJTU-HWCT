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

#include <device/map.h>
#include <utils.h>

/* Hardware Timer Device for FPGA soft-core (RV32IM-Zicsr)
 * Base address: 0x80010000
 * Register layout:
 *   0x00: CR     (Control Register)      - [0]: enable
 *   0x04: SR     (Status Register)       - [0]: interrupt flag
 *   0x08: PSC    (Prescale Register)     - clock divisor (N-1)
 *   0x0c: LOAD   (Load Register)         - reload value
 *   0x10: COUNT  (Counter Register)      - current count value
 */

#define TIMER_REG_CR    0x00
#define TIMER_REG_SR    0x04
#define TIMER_REG_PSC   0x08
#define TIMER_REG_LOAD  0x0c
#define TIMER_REG_COUNT 0x10

typedef struct {
  uint32_t cr;        // control
  uint32_t sr;        // status (interrupt flag)
  uint32_t psc;       // prescale (divisor - 1)
  uint32_t load;      // load value
  uint32_t count;     // counter
  uint32_t clk_cnt;   // internal clock counter
} HWTimer;

static HWTimer *hwdev_timer = NULL;
static uint32_t *timer_base = NULL;

// Forward declaration
extern void dev_raise_intr();

void hwdev_timer_update() {
  if (!hwdev_timer) {
    return;
  }
  
  // Only check timer if it's enabled
  if (!(hwdev_timer->cr & 0x1)) {
    return; // timer disabled
  }

  // increment prescale counter
  hwdev_timer->clk_cnt++;
  
  if (hwdev_timer->clk_cnt > hwdev_timer->psc) {
    hwdev_timer->clk_cnt = 0;
    
    // decrement counter
    if (hwdev_timer->count == 0) {
      // counter reached 0, reload it
      hwdev_timer->count = hwdev_timer->load;
      hwdev_timer->sr |= 0x1; // set interrupt flag
      dev_raise_intr(); // trigger interrupt
    } else {
      hwdev_timer->count--;
    }
  }
}

static void hwdev_timer_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 4);
  
  switch (offset) {
    case TIMER_REG_CR:
      if (is_write) {
        hwdev_timer->cr = timer_base[offset / 4];
        if (!(hwdev_timer->cr & 0x1)) {
          // timer disabled, clear counter
          hwdev_timer->clk_cnt = 0;
          hwdev_timer->count = 0;
        }
      }
      break;
      
    case TIMER_REG_SR:
      if (is_write) {
        // writing 1 to bit 0 clears the interrupt flag
        if (timer_base[offset / 4] & 0x1) {
          hwdev_timer->sr = 0;
          timer_base[offset / 4] = 0;
        }
      } else {
        // read status
        timer_base[offset / 4] = hwdev_timer->sr;
      }
      break;
      
    case TIMER_REG_PSC:
      if (is_write) {
        hwdev_timer->psc = timer_base[offset / 4];
      }
      break;
      
    case TIMER_REG_LOAD:
      if (is_write) {
        hwdev_timer->load = timer_base[offset / 4];
      }
      break;
      
    case TIMER_REG_COUNT:
      if (is_write) {
        hwdev_timer->count = timer_base[offset / 4];
        hwdev_timer->clk_cnt = 0;
      } else {
        // read count
        timer_base[offset / 4] = hwdev_timer->count;
      }
      break;
      
    default:
      panic("unsupported offset = %d", offset);
  }
}

void init_hwdev_timer() {
  hwdev_timer = (HWTimer *)malloc(sizeof(HWTimer));
  assert(hwdev_timer);
  
  memset(hwdev_timer, 0, sizeof(HWTimer));
  hwdev_timer->cr = 0;
  hwdev_timer->sr = 0;
  hwdev_timer->psc = 0;
  hwdev_timer->load = 0;
  hwdev_timer->count = 0;
  hwdev_timer->clk_cnt = 0;
  
  timer_base = (uint32_t *)new_space(20); // enough space for 5 registers
  
  add_mmio_map("hwdev_timer", CONFIG_HWDEV_TIMER_MMIO, timer_base, 20, hwdev_timer_io_handler);
}
