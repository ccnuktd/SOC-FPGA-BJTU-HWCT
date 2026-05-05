/*
 * Copyright (c) 2006-2018, RT-Thread Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2021/11/21     Lyons        first version
 */

/*
 * rt_base_t rt_hw_interrupt_disable(void);
 */
    .globl rt_hw_interrupt_disable
rt_hw_interrupt_disable:
    csrrci  a0, mstatus, 8
    ret

/*
 * void rt_hw_interrupt_enable(rt_base_t level);
 */
    .globl rt_hw_interrupt_enable
rt_hw_interrupt_enable:
    csrw    mstatus, a0
    ret

/*
 * void rt_hw_context_switch_to(rt_uint32 to);
 *
 * r0 --> to
 */
    .globl rt_hw_context_switch_to
rt_hw_context_switch_to:
    lw      sp, 0(a0)

    j       _thread_exit

/*
 * void rt_hw_context_switch(rt_uint32 from, rt_uint32 to);
 *
 * a0 --> from
 * a1 --> to
 */
    .globl rt_hw_context_switch
rt_hw_context_switch:
_thread_save:
    addi    sp, sp, -32*4
    sw      sp, 0(a0)

    sw      x1,   0*4(sp)
    sw      x1,   1*4(sp)

    csrr    a0, mstatus
    andi    a0, a0, 8
    beqz    a0, _thread_mpie_xx00
_thread_mpie_xx08:
    li      a0, 0x0088
    j       _thread_mpie
_thread_mpie_xx00:
    li      a0, 0
_thread_mpie:
    sw      a0,   2*4(sp)

    sw      x4,   4*4(sp)
    sw      x5,   5*4(sp)
    sw      x6,   6*4(sp)
    sw      x7,   7*4(sp)
    sw      x8,   8*4(sp)
    sw      x9,   9*4(sp)
    sw      x10, 10*4(sp)
    sw      x11, 11*4(sp)
    sw      x12, 12*4(sp)
    sw      x13, 13*4(sp)
    sw      x14, 14*4(sp)
    sw      x15, 15*4(sp)
    sw      x16, 16*4(sp)
    sw      x17, 17*4(sp)
    sw      x18, 18*4(sp)
    sw      x19, 19*4(sp)
    sw      x20, 20*4(sp)
    sw      x21, 21*4(sp)
    sw      x22, 22*4(sp)
    sw      x23, 23*4(sp)
    sw      x24, 24*4(sp)
    sw      x25, 25*4(sp)
    sw      x26, 26*4(sp)
    sw      x27, 27*4(sp)
    sw      x28, 28*4(sp)
    sw      x29, 29*4(sp)
    sw      x30, 30*4(sp)
    sw      x31, 31*4(sp)

    lw      sp, 0(a1)

_thread_exit:
    lw      a0,   0*4(sp)
    csrw    mepc, a0

    lw      x1,   1*4(sp)

    li      t0, 0x1800
    csrw    mstatus, t0
    lw      t0,   2*4(sp)
    andi    t0, t0, 0x80
    csrs    mstatus, t0

    lw      x4,   4*4(sp)
    lw      x5,   5*4(sp)
    lw      x6,   6*4(sp)
    lw      x7,   7*4(sp)
    lw      x8,   8*4(sp)
    lw      x9,   9*4(sp)
    lw      x10, 10*4(sp)
    lw      x11, 11*4(sp)
    lw      x12, 12*4(sp)
    lw      x13, 13*4(sp)
    lw      x14, 14*4(sp)
    lw      x15, 15*4(sp)
    lw      x16, 16*4(sp)
    lw      x17, 17*4(sp)
    lw      x18, 18*4(sp)
    lw      x19, 19*4(sp)
    lw      x20, 20*4(sp)
    lw      x21, 21*4(sp)
    lw      x22, 22*4(sp)
    lw      x23, 23*4(sp)
    lw      x24, 24*4(sp)
    lw      x25, 25*4(sp)
    lw      x26, 26*4(sp)
    lw      x27, 27*4(sp)
    lw      x28, 28*4(sp)
    lw      x29, 29*4(sp)
    lw      x30, 30*4(sp)
    lw      x31, 31*4(sp)

    addi    sp, sp, 32*4

    mret
    
_thread_nop_list:
    nop
    nop
    nop    
