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
    int load_slot = 0;

    __asm__ volatile (
        // ========== RAW hazard ==========
       
        "addi t0, x0, 1\n\t"           // t0 = 1
        "addi t1, x0, 1\n\t"           // t1 = 1
        "addi t2, x0, 1\n\t"           // t2 = 1
        "addi t3, x0, 1\n\t"           // t3 = 1
        "addi t4, x0, 2\n\t"           // t4 = 2

        "add t1, t0, t2\n\t"           // t1 = t0 + t2 = 2
        "sub t0, t1, x0\n\t"           // t0 = t1 - x0 = 2

        "add t1, t0, t2\n\t"           // t1 = t0 + t2 = 3
        "or  t5, t3, t4\n\t"           // t5 = t3 | t4 = 3
        "sub t0, t1, x0\n\t"           // t0 = t1 - x0 = 3


        // ========== Load-Use hazard ==========
        "addi a0, x0, 100\n\t"
        "sw a0, 0(%[slot])\n\t"
        "lw a1, 0(%[slot])\n\t"       
        "add a2, a1, a0\n\t"     

        // ========== Control hazard ==========
        "addi a3, x0, 100\n\t"
        "addi a4, x0, 100\n\t"
        "bne a3, a4, 1f\n\t"     
        "addi a5, zero, 111\n\t" 
        "j 2f\n\t"
        "1:\n\t"
        "addi a5, zero, 222\n\t" // skipped
        "2:\n\t"

        // 保存结果到C变量 result
        "add %[res], a4, a5\n\t" 

        : [res] "=r"(result)
        : [slot] "r"(&load_slot)
        : "memory", "t0", "t1", "t2", "t3", "t4", "t5",
          "a0", "a1", "a2", "a3", "a4", "a5"
    );

    xprintf("Pipeline test result = %d\n", result);

    return 0;
}
