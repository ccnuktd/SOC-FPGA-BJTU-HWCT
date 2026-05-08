/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2021-10-29     Lyons        first version
 */

#include "uart.h"

void uart_send(UART_Type *uart, uint8_t data)
{
    (void)uart;
    (void)data;

    /* TODO: Start one UART transmit according to uart.h and the RTL. */
}

void uart_send_wait(UART_Type *uart, uint8_t data)
{
    (void)uart;
    (void)data;

    /* TODO: Send one byte and wait until the transmit-done flag is set. */
}

uint8_t uart_read(UART_Type *uart)
{
    (void)uart;

    /* TODO: Return one received byte, or 0xFF when no byte is available. */
    return 0xFF;
}

uint8_t uart_read_wait(UART_Type *uart)
{
    (void)uart;

    /* TODO: Wait until one byte is received, then return it. */
    return 0xFF;
}
