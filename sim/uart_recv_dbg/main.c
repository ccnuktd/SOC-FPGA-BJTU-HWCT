/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2021-10-29     Lyons        first version
 */

#include "__def.h"
#include "systick.h"
#include "xprintf.h"

#define IAP_ADDR 0x80002000 // 56KB
#define PACKAGE 16

typedef void (*func)(void);

int main()
{
    func _jump;

    xprintf("begin iap program\n");

    uint32_t offset;
    offset = 0;

    while (1)
    { 
        uint8_t dummy[PACKAGE*4+2]; // A5 data32*PACKAGE 5A
        
        for (uint32_t i=0; i<sizeof(dummy); i++) {
            dummy[i] = uart_read_wait(UART1);
        }

        for (uint32_t i=0; i<sizeof(dummy); i++) {
            xprintf("%02x", dummy[i]);
            if (i % 32 == 0) xprintf("\n");
            else if (i % 8 == 0) xprintf(" ");
        }

        if (0xA6 == dummy[0]) {
            break;
        }
    
        for (uint32_t i=0; i<PACKAGE; i++) {
            *((uint32_t*)IAP_ADDR + offset + i) = (dummy[1 + 4*i + 0] << 0)
                                                + (dummy[1 + 4*i + 1] << 8)
                                                + (dummy[1 + 4*i + 2] << 16)
                                                + (dummy[1 + 4*i + 3] << 24);
        }
        
        offset += PACKAGE;

        // uart_send_wait(UART1, 0xAC);
    }
        
    xprintf("end iap program\n");

    // 检验写入的内容
    // uint32_t addr;
    // for (int i = 0; i < 150; i ++) {
    //     addr = IAP_ADDR + 4 * i;
    //     xprintf("addr:%x, val:%x\n", addr, *(uint32_t *)addr);
    // }

    _jump = (func)IAP_ADDR;
    // xprintf("addr:%x, val:%x\n", _jump, *(uint32_t *)_jump);
    _jump();

    return 0;
}
