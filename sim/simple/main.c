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
#include "xprintf.h"

int main()
{
   int result = 0;

    __asm__ volatile (
        // ========== RAW hazard ==========
       
        "addi x4, x0, 1\n\t"           // x4 = 1
        "addi x5, x0, 1\n\t"           // x5 = 1
        "addi x6, x0, 1\n\t"           // x6 = 1
        "addi x8, x0, 1\n\t"           // x8 = 1
        "addi x9, x0, 2\n\t"           // x9 = 2

        "add x5, x4, x6\n\t"           // x5 = x4 + x6 = 2
        "sub x4, x5, x0\n\t"           // x4 = x5 - x0 = 2

        "add x5, x4, x6\n\t"           // x5 = x4 + x6 = 2
        "or  x7, x8, x9\n\t"           // x7 = x8 | x9 = 3
        "sub x4, x5, x0\n\t"           // x4 = x5 - x0 = 2


        // ========== Load-Use hazard ==========
        "addi x10, x0, 100\n\t"
        "sw x10, 0(x2)\n\t"
        "lw x11, 0(x2)\n\t"       
        "add x12, x11, x10\n\t"     

        // ========== Control hazard ==========
        "addi x13, x0, 100\n\t"
        "addi x14, x0, 100\n\t"
        "bne x13, x14, 1f\n\t"     
        "addi x15, zero, 111\n\t" 
        "j 2f\n\t"
        "1:\n\t"
        "addi x15, zero, 222\n\t" // skipped
        "2:\n\t"

        // 保存结果到C变量 result
        "add %[res], x14, x15\n\t" 

        : [res] "=r"(result)
    );

    xprintf("Pipeline test result = %d\n", result);

    return 0;
}
