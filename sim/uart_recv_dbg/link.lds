OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
    ram (rwx) : ORIGIN = 0x80000000, LENGTH = 4K
    abi (rwx) : ORIGIN = 0x80001000, LENGTH = 4K
    iap (rwx) : ORIGIN = 0x80002000, LENGTH = 56K
}

SECTIONS
{
    .init           :
    {
        KEEP (*(SORT_NONE(.init)))
    } >ram

    .abi_section   :
    {
        KEEP(*(.abi_section))
    } >abi

    .text           :
    {
        . = ALIGN(4);
        __fsymtab_start = .;
        KEEP(*(FSymTab))
        __fsymtab_end = .;

        . = ALIGN(4);
        __vsymtab_start = .;
        KEEP(*(VSymTab))
        __vsymtab_end = .;

        . = ALIGN(4);
        *(.text.unlikely .text.unlikely.*)
        *(.text.startup .text.startup.*)
        *(.text .text.*)
        *(.gnu.linkonce.t.*)
    } >ram

    .data          :
    {
        __data_lma = LOADADDR(.data);
        __data_start = .;

        . = ALIGN(4);
        __rt_init_start = .;
        KEEP(*(SORT(.rti_fn*)))
        __rt_init_end = .;

        *(.rdata)
        *(.rodata .rodata.*)
        *(.gnu.linkonce.r.*)
        *(.data .data.*)
        *(.gnu.linkonce.d.*)
        *(.sdata .sdata.*)
        *(.sdata*)
        *(.gnu.linkonce.s.*)

        . = ALIGN(4);
        __data_end = .;
    } >ram

    .bss            :
    {
        __bss_start = .;

        *(.sbss .sbss.*)
        *(.gnu.linkonce.sb.*)
        *(.bss .bss.*)
        *(.gnu.linkonce.b.*)
        *(COMMON)

        . = ALIGN(4);
        __bss_end = .;
        __end = .;
    } >ram

    .stack ORIGIN(ram) + LENGTH(ram):
    {
        __stack_top = .;
    } >ram
}

