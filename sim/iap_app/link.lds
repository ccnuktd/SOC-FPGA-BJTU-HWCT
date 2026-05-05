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

    .abi_jump      :
    {
        KEEP(*(.abi_jump))
    } >iap

    .text : {
        *(.text*)
    } >iap

    .data : {
        __data_lma = LOADADDR(.data);
        __data_start = .;

        *(.rodata*)
        *(.data*)
        *(.sdata*)
        __data_end = .;
    } >iap

    .bss : {
        __bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        __bss_end = .;
    } >iap

    . = ALIGN(4);
    .stack : {
        __stack_bottom = .;
        __stack_top = ORIGIN(iap) + LENGTH(iap);
        . = __stack_top;
    } >iap

    _end = .;
}

