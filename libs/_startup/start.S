

.section .init

.globl _start
.type _start,@function

_start:
.option push
.option pop
    la      t0, __stack_top
    addi    sp, t0, -1024

    # Initialize mscratch to point to interrupt stack
    la      t0, __intr_stack_top
    csrw    mscratch, t0

    la      a0, __bss_start
    la      a1, __bss_end
    bgeu    a0, a1, _bss_init_end
_bss_init_begin:
    sw      zero, 0(a0)
    addi    a0, a0, 4
    bltu    a0, a1, _bss_init_begin
_bss_init_end:

    la      a0, __data_lma
    la      a1, __data_start
    beq     a0, a1, _data_init_end
    la      a2, __data_end
    bgeu    a1, a2, _data_init_end
_data_init_begin:
    lw      t0, 0(a0)
    sw      t0, 0(a1)
    addi    a0, a0, 4
    addi    a1, a1, 4
    bltu    a1, a2, _data_init_begin
_data_init_end:

    call    init
    call    entry

loop:
    j       loop

.weak init
init:
    ret

.weak entry
entry:
    call    main
    ebreak
    ret