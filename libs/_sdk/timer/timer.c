/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2021-10-29     Lyons        first version
 */

#include "timer.h"

void timer_init(TIM_Type *tim, uint32_t psc, uint32_t value)
{
    (void)tim;
    (void)psc;
    (void)value;

    /* TODO: Configure timer registers according to timer.h and the RTL. */
}

void timer_control(TIM_Type *tim, uint8_t en)
{
    (void)tim;
    (void)en;

    /* TODO: Enable or disable the timer by updating the control register. */
}

void timer_clearflag(TIM_Type *tim, uint32_t flag)
{
    (void)tim;
    (void)flag;

    /* TODO: Clear timer status flags with the RTL-defined write-one rule. */
}
