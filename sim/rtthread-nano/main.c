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

#include "rthw.h"
#include "rtthread.h"
#include "timer.h"

void simple_add(void);

int main()
{
    timer_init(TIM1, CPU_FREQ_MHZ-1, (1000/RT_TICK_PER_SECOND)*1000); // tick = 1ms
    timer_control(TIM1, TIM_EN);

    while (1) {
        // rt_kprintf("Hello RT-Thread!\n");
        // simple_add();
        rt_thread_mdelay(1000);
    }

    return 0;
}

void timer1_handler(void)
{
    timer_clearflag(TIM1, TIM_SR_CLR_TUF);
    
    rt_base_t level;

    /* disable interrupt */
    level = rt_hw_interrupt_disable();

    extern void rt_os_tick_callback(void);
    rt_os_tick_callback();

    rt_hw_interrupt_enable(level);
}
