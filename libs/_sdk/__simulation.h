/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2021-10-29     Lyons        first version
 */

#ifndef __SIMULATION_H__
#define __SIMULATION_H__

#include "uart.h"

#define _csr_putc(val)          write_csr(mscratchcswl, val)
#define _uart_putc(val)         uart_send_wait(UART1, val)

#ifdef PRINT_STDIO_SIM 
    #define simulation(data)    \
    do { \
        _csr_putc( (1<<31)|0x1b ); _csr_putc(0); \
        _csr_putc( (1<<31)|data ); _csr_putc(0); \
    } while (0);
#else
    #define simulation(data)    \
    do { \
        _uart_putc(0x1b); \
        _uart_putc(data); \
    } while (0);
#endif // #ifdef PRINT_STDIO_SIM

#endif //#ifndef __SIMULATION_H__