OUTPUT_ARCH( "riscv" )
ENTRY(_jump)

MEMORY
{
    iap (rwx) : ORIGIN = 0x80002000, LENGTH = 56K
}

SECTIONS
{
    .text : {
        *(.abi_jump) 
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

