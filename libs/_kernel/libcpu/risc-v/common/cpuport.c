/*
 * Copyright (c) 2006-2021, RT-Thread Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2018/10/28     Bernard      The unify RISC-V porting code.
 */

#include <rthw.h>
#include <rtthread.h>

/**
 * @brief from thread used interrupt context switch
 *
 */
volatile rt_ubase_t rt_interrupt_from_thread = 0;

/**
 * @brief to thread used interrupt context switch
 *
 */
volatile rt_ubase_t rt_interrupt_to_thread = 0;

/**
 * @brief flag to indicate context switch in interrupt or not
 *
 */
volatile rt_ubase_t rt_thread_switch_interrupt_flag = 0;

/**
 * @brief thread stack frame of saved context
 *
 */
struct rt_hw_stack_frame
{
    rt_ubase_t mepc;        /*!< mepc        - program counter                      */
    rt_ubase_t ra;          /*!< x1  - ra    - return address for jumps             */
    rt_ubase_t mstatus;     /*!< mstatus     - mstatus                              */
    rt_ubase_t _rsv0;       /*!<             - reserve 0                            */
    rt_ubase_t _rsv1;       /*!<             - reserve 1                            */
    rt_ubase_t t0;          /*!< x5  - t0    - temporary register 0                 */
    rt_ubase_t t1;          /*!< x6  - t1    - temporary register 1                 */
    rt_ubase_t t2;          /*!< x7  - t2    - temporary register 2                 */
    rt_ubase_t s0_fp;       /*!< x8  - s0/fp - saved register 0 or frame pointer    */
    rt_ubase_t s1;          /*!< x9  - s1    - saved register 1                     */
    rt_ubase_t a0;          /*!< x10 - a0    - return value or function argument 0  */
    rt_ubase_t a1;          /*!< x11 - a1    - return value or function argument 1  */
    rt_ubase_t a2;          /*!< x12 - a2    - function argument 2                  */
    rt_ubase_t a3;          /*!< x13 - a3    - function argument 3                  */
    rt_ubase_t a4;          /*!< x14 - a4    - function argument 4                  */
    rt_ubase_t a5;          /*!< x15 - a5    - function argument 5                  */
    rt_ubase_t a6;          /*!< x16 - a6    - function argument 6                  */
    rt_ubase_t a7;          /*!< x17 - s7    - function argument 7                  */
    rt_ubase_t s2;          /*!< x18 - s2    - saved register 2                     */
    rt_ubase_t s3;          /*!< x19 - s3    - saved register 3                     */
    rt_ubase_t s4;          /*!< x20 - s4    - saved register 4                     */
    rt_ubase_t s5;          /*!< x21 - s5    - saved register 5                     */
    rt_ubase_t s6;          /*!< x22 - s6    - saved register 6                     */
    rt_ubase_t s7;          /*!< x23 - s7    - saved register 7                     */
    rt_ubase_t s8;          /*!< x24 - s8    - saved register 8                     */
    rt_ubase_t s9;          /*!< x25 - s9    - saved register 9                     */
    rt_ubase_t s10;         /*!< x26 - s10   - saved register 10                    */
    rt_ubase_t s11;         /*!< x27 - s11   - saved register 11                    */
    rt_ubase_t t3;          /*!< x28 - t3    - temporary register 3                 */
    rt_ubase_t t4;          /*!< x29 - t4    - temporary register 4                 */
    rt_ubase_t t5;          /*!< x30 - t5    - temporary register 5                 */
    rt_ubase_t t6;          /*!< x31 - t6    - temporary register 6                 */
};

/**
 * This function will initialize thread stack
 *
 * @param tentry the entry of thread
 * @param parameter the parameter of entry
 * @param stack_addr the beginning stack address
 * @param texit the function will be called when thread exit
 *
 * @return stack address
 */
rt_uint8_t *rt_hw_stack_init(void       *tentry,
                             void       *parameter,
                             rt_uint8_t *stack_addr,
                             void       *texit)
{
    struct rt_hw_stack_frame *frame;
    rt_uint8_t *stk;

    stk  = stack_addr + sizeof(rt_ubase_t);
    stk  = (rt_uint8_t *)RT_ALIGN_DOWN((rt_ubase_t)stk, 4);
    stk -= sizeof(struct rt_hw_stack_frame);

    frame = (struct rt_hw_stack_frame *)stk;

    for (int i = 0; i < sizeof(struct rt_hw_stack_frame) / sizeof(rt_ubase_t); i++)
    {
        ((rt_ubase_t *)frame)[i] = 0xdeadbeef;
    }

    frame->ra       = (rt_ubase_t)texit;
    frame->a0       = (rt_ubase_t)parameter;
    frame->mepc     = (rt_ubase_t)tentry;

    frame->mstatus  = 0x1888;

    return stk;
}

/** rt_hw_context_switch_interrupt */
void rt_hw_context_switch_interrupt(rt_ubase_t from, rt_ubase_t to)
{
    rt_interrupt_from_thread = from;
    rt_interrupt_to_thread = to;
    
    rt_thread_switch_interrupt_flag = 1;

    return;
}

/** shutdown CPU */
void rt_hw_cpu_shutdown(void)
{
    rt_kprintf("shutdown...\n");

    rt_hw_interrupt_disable();

    while (1)
    {
        RT_ASSERT(0);
    }
}
