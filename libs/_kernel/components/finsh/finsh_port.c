/*
 * Copyright (c) 2006-2021, RT-Thread Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 */

#include <rthw.h>
#include <rtconfig.h>

#ifndef RT_USING_FINSH
#error Please uncomment the line <#include "finsh_config.h"> in the rtconfig.h 
#endif

#ifdef RT_USING_FINSH

#include "uart.h"

RT_WEAK char rt_hw_console_getchar(void)
{
    rt_uint8_t ch;

    extern uint8_t uart_read_wait(UART_Type *uart);
    ch = uart_read_wait(UART1);

    return ch;
}

#endif /* RT_USING_FINSH */

