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
#include "rtthread.h"

extern void timer1_handler(void);
extern void soft_handler(void);

volatile int count = 0;

#define TRAP_DEBUG_CSR 1

static void trap_dump_csr(uint32_t irqno, uint32_t epc)
{
#if TRAP_DEBUG_CSR
    uint32_t mtvec = read_csr(mtvec);
    uint32_t csr_mepc = read_csr(mepc);
    uint32_t mstatus = read_csr(mstatus);
    uint32_t mscratch = read_csr(mscratch);

    rt_kprintf("trap csr: mcause=%08x epc_arg=%08x csr_mepc=%08x\n",
            irqno, epc, csr_mepc);
    rt_kprintf("          mtvec =%08x mstatus=%08x,mscratch=%08x\n", mtvec, mstatus, mscratch);

    // xprintf("          inst[-4]=%08x inst[0]=%08x inst[+4]=%08x\n",
    //         *(volatile uint32_t *)(epc - 4),
    //         *(volatile uint32_t *)epc,
    //         *(volatile uint32_t *)(epc + 4));
#endif
}

void trap_handler(uint32_t irqno, uint32_t epc)
{
    

    if (0x80000003 == irqno)
    {   
        timer1_handler();
        if (count == 100) {
            trap_dump_csr(irqno, epc);
            count = 0;
        } else {
            count ++;
        }
    } else {
        rt_kprintf("bad irq: %08x\n", irqno);
        rt_kprintf("mepc:    %08x\n", epc);
        trap_dump_csr(irqno, epc);
    }
}
