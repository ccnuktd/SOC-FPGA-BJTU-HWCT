.section .text

.global interrupt_disable
.align 2
interrupt_disable:
    csrrci  a0, mstatus, 8
    ret

.global interrupt_enable
.align 2
interrupt_enable:
    csrw    mstatus, a0
    ret

/* Macro for saving task context */
.macro save_context
    addi    sp, sp, -32*4

    sw      ra,   1*4(sp)      # offset 4: ra (save first before it's clobbered)
    csrr    x1, mepc
    sw      x1,   0*4(sp)     # offset 0: mepc
   
    li      x1, 0x0088
    sw      x1,   2*4(sp)     # offset 8: mstatus.MIE

    sw      x4,   4*4(sp)     # offset 16
    sw      x5,   5*4(sp)     # offset 20
    sw      x6,   6*4(sp)     # offset 24
    sw      x7,   7*4(sp)     # offset 28
    sw      x8,   8*4(sp)     # offset 32
    sw      x9,   9*4(sp)     # offset 36
    sw      x10, 10*4(sp)    # offset 40
    sw      x11, 11*4(sp)    # offset 44
    sw      x12, 12*4(sp)    # offset 48
    sw      x13, 13*4(sp)    # offset 52
    sw      x14, 14*4(sp)    # offset 56
    sw      x15, 15*4(sp)    # offset 60
    sw      x16, 16*4(sp)    # offset 64
    sw      x17, 17*4(sp)    # offset 68
    sw      x18, 18*4(sp)    # offset 72
    sw      x19, 19*4(sp)    # offset 76
    sw      x20, 20*4(sp)    # offset 80
    sw      x21, 21*4(sp)    # offset 84
    sw      x22, 22*4(sp)    # offset 88
    sw      x23, 23*4(sp)    # offset 92
    sw      x24, 24*4(sp)    # offset 96
    sw      x25, 25*4(sp)    # offset 100
    sw      x26, 26*4(sp)    # offset 104
    sw      x27, 27*4(sp)    # offset 108
    sw      x28, 28*4(sp)    # offset 112
    sw      x29, 29*4(sp)    # offset 116
    sw      x30, 30*4(sp)    # offset 120
    sw      x31, 31*4(sp)    # offset 124
.endm

/* Macro for restoring task context */
.macro restore_context
    lw      x1,   0*4(sp)       # offset 0: mepc
    csrw    mepc, x1
    
    lw      ra,   1*4(sp)       # offset 4: ra

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
.endm

.global trap_entry
.align 2
trap_entry:
    # Swap thread sp with the interrupt stack pointer in mscratch.
    # Do not use a GPR here; the interrupted register context is not saved yet.
    csrrw   sp, mscratch, sp
    
    j       vector_handler

vector_handler:
_save:
    save_context

#ifdef OS_ENABLE_RT_THREAD
    la      t0, rt_interrupt_nest
    li      t1, 1
    sb      t1, 0(t0)
#endif

    csrr    a0, mcause
    csrr    a1, mepc

    srli    t0, a0, 31
    
    beq     t0, x0, _is_exception
_back_process:

    call    trap_handler

    j       _is_interrupt

_is_exception:
    mv      t1, a1
    addi    a1, a1, 4
    csrw    mepc, a1
    sw      a1,   0*4(sp)
    mv      a1, t1
    j _back_process

_is_interrupt:

#ifdef OS_ENABLE_RT_THREAD
    la      s0, rt_thread_switch_interrupt_flag
    lw      s2, 0(s0)
    beqz    s2, _restore
    sw      zero, 0(s0)

    la      s0, rt_interrupt_from_thread
    lw      s1, 0(s0)

    # The C interrupt handler runs on the interrupt stack. If RT-Thread
    # requests a context switch, move this trap frame back to the interrupted
    # thread stack so the normal thread restore path can use it later.
    csrr    t2, mscratch       # interrupted thread sp before trap
    addi    t2, t2, -32*4      # new interrupted thread frame
    mv      t3, sp             # source: trap frame on interrupt stack
    mv      t4, t2             # destination: interrupted thread stack
    li      t5, 32
_copy_frame_to_thread_stack:
    lw      t6, 0(t3)
    sw      t6, 0(t4)
    addi    t3, t3, 4
    addi    t4, t4, 4
    addi    t5, t5, -1
    bnez    t5, _copy_frame_to_thread_stack

    sw      t2, 0(s1)

    # Put the free interrupt-stack top back into mscratch before restoring
    # another thread. The mret below will return with sp already being the
    # selected thread stack, so there is no later stack swap in this path.
    addi    t0, sp, 32*4
    csrw    mscratch, t0

    la      s0, rt_interrupt_to_thread
    lw      s1, 0(s0)
    lw      sp, 0(s1)
    j       _restore_switched
#endif

_restore:
#ifdef OS_ENABLE_RT_THREAD
    la      t0, rt_interrupt_nest
    sb      zero, 0(t0)
#endif

    restore_context

    # Swap back to the interrupted thread sp and keep the free interrupt stack
    # pointer in mscratch for the next trap.
    csrrw   sp, mscratch, sp
    mret

_restore_switched:
#ifdef OS_ENABLE_RT_THREAD
    la      t0, rt_interrupt_nest
    sb      zero, 0(t0)
#endif

    restore_context

    mret

_nop_list:
    nop
    nop
    nop

.weak trap_handler
trap_handler:
    ret
