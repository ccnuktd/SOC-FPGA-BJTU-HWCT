/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
* http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <device/map.h>
#include <utils.h>
#include <stdio.h>   // 为了 getchar 等
#include <unistd.h>  // 为了 read / STDIN_FILENO
#include <fcntl.h>   // 为了 fcntl 非阻塞

/* Hardware UART Device for FPGA soft-core (RV32IM-Zicsr)
 * Base address: 0x80020000
 * Register layout:
 * 0x00: CR (Control Register) - [0]: tx_enable, [1]: rx_enable
 * 0x04: SR (Status Register) - [0]: tx_flag (写1清), [1]: rx_flag (读RXD清或写1清)
 * 0x08: BAUD (Baud Register) - baud rate (read-only)
 * 0x0c: RXD (RX Data Register) - received data (只读)
 * 0x10: TXD (TX Data Register) - data to transmit (只写)
 */
#define UART_REG_CR    0x00
#define UART_REG_SR    0x04
#define UART_REG_BAUD  0x08
#define UART_REG_RXD   0x0c
#define UART_REG_TXD   0x10

#define SR_TX_FLAG     (1u << 0)
#define SR_RX_FLAG     (1u << 1)

typedef struct {
  uint32_t cr;    // control
  uint32_t sr;    // status
  uint32_t baud;  // baud rate
  uint32_t rxd;   // rx data (缓冲一个字节)
  uint32_t txd;   // tx data
  bool     has_data;   // 是否有未读取的字符
} HWUart;

static HWUart *hwdev_uart = NULL;
static uint32_t *uart_base = NULL;

// 把字符发送到宿主终端（保持原样）
static void uart_putc(char ch) {
  MUXDEF(CONFIG_TARGET_AM, putch(ch), putc(ch, stderr));
}

// 尝试从宿主stdin非阻塞读取一个字符
// 返回：是否有新字符，*ch 存放读取到的字符（仅在返回true时有效）
static bool try_read_keyboard(char *ch) {
  // 设置stdin非阻塞（只需做一次，但这里每次都设也无所谓）
  int flags = fcntl(STDIN_FILENO, F_GETFL, 0);
  fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);

  ssize_t n = read(STDIN_FILENO, ch, 1);
  if (n == 1) {
    return true;
  }
  return false;
}

// 这个函数需要在 NEMU 的主循环中被**每条指令后**调用（类似 device_update() 的位置）
void hwdev_uart_update(void) {
  if (!hwdev_uart || !(hwdev_uart->cr & 0x2)) {  // rx 未使能
    return;
  }

  // 如果缓冲区已经有一个字符未读，就不读取新的
  if (hwdev_uart->has_data) {
    return;
  }

  char ch;
  if (try_read_keyboard(&ch)) {
    hwdev_uart->rxd = (uint32_t)(uint8_t)ch;   // 只取低8位
    hwdev_uart->has_data = true;
    hwdev_uart->sr |= SR_RX_FLAG;              // 置位 rx_flag
  }
}

static void hwdev_uart_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 4);

  switch (offset) {
    case UART_REG_CR:
      if (is_write) {
        hwdev_uart->cr = uart_base[offset / 4];
      }
      break;

    case UART_REG_SR:
      if (is_write) {
        // 写1清标志位（常见硬件行为）
        uint32_t clear = uart_base[offset / 4];
        hwdev_uart->sr &= ~(clear & (SR_TX_FLAG | SR_RX_FLAG));
      } else {
        // 读状态
        uart_base[offset / 4] = hwdev_uart->sr;
      }
      break;

    case UART_REG_BAUD:
      // 只读
      uart_base[offset / 4] = hwdev_uart->baud;
      break;

    case UART_REG_RXD:
      if (is_write) {
        // 一般RXD是只读，这里panic或忽略
        // panic("write to RXD is not allowed");
      } else {
        // 读取接收数据
        if (hwdev_uart->has_data) {
          uart_base[offset / 4] = hwdev_uart->rxd;
          // 读取后清标志（最常见的行为）
          hwdev_uart->sr &= ~SR_RX_FLAG;
          hwdev_uart->has_data = false;
        } else {
          // 没有数据，返回0（或0xff，根据你的驱动约定）
          uart_base[offset / 4] = 0;
        }
      }
      break;

    case UART_REG_TXD:
      if (is_write) {
        hwdev_uart->txd = uart_base[offset / 4] & 0xFF;
        if (hwdev_uart->cr & 0x1) { // tx enabled
          uart_putc((char)(hwdev_uart->txd));
          hwdev_uart->sr |= SR_TX_FLAG;  // set tx_flag (表示发送完成/忙)
          // 如果你想模拟“发送完成中断”，可以在这里清tx_flag，但多数简单驱动认为写完即完成
        }
      }
      break;

    default:
      panic("unsupported uart offset = 0x%x", offset);
  }
}

void init_hwdev_uart(void) {
  hwdev_uart = (HWUart *)malloc(sizeof(HWUart));
  assert(hwdev_uart);
  memset(hwdev_uart, 0, sizeof(HWUart));

  hwdev_uart->cr   = 0x3;       // 默认使能 tx + rx
  hwdev_uart->sr   = 0x0;
  hwdev_uart->baud = 115200;
  hwdev_uart->has_data = false;

  uart_base = (uint32_t *)new_space(20);  // 5个32位寄存器
  add_mmio_map("hwdev_uart", CONFIG_HWDEV_UART_MMIO, uart_base, 20, hwdev_uart_io_handler);
}