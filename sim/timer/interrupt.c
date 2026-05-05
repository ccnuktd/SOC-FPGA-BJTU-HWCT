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

extern void timer1_handler(void);

#define TRAP_DEBUG_CSR 1

static void trap_dump_csr(uint32_t irqno, uint32_t epc)
{
#if TRAP_DEBUG_CSR
    uint32_t mtvec = read_csr(mtvec);
    uint32_t csr_mepc = read_csr(mepc);
    uint32_t mstatus = read_csr(mstatus);
    uint32_t mscratch = read_csr(mscratch);
    uint32_t mie = read_csr(mie);
    uint32_t mip = read_csr(mip);
    uint32_t mtval = read_csr(mtval);

    xprintf("trap csr: mcause=%08x epc_arg=%08x csr_mepc=%08x\n",
            irqno, epc, csr_mepc);
    xprintf("          mtvec =%08x mstatus=%08x\n", mtvec, mstatus);
    xprintf("          mscratch=%08x mie=%08x mip=%08x mtval=%08x\n",
            mscratch, mie, mip, mtval);
#endif
}

void trap_handler(uint32_t irqno, uint32_t epc)
{
    trap_dump_csr(irqno, epc);

    if (0x80000003 == irqno)
    {
        timer1_handler();
    } else {
        xprintf("bad irq: %08x\n", irqno);
        xprintf("mepc:    %08x\n", epc);
    }
}
