#/*
# * Copyright {c} 2020-2021, SERI Development Team
# *
# * SPDX-License-Identifier: Apache-2.0
# *
# * Change Logs:
# * Date         Author          Notes
# * 2022-04-04   Lyons           first version
# */

# Detect OS for cross-platform toolchain selection
DETECTED_OS := $(shell echo $$OSTYPE)
IS_LINUX := $(filter %linux%,$(DETECTED_OS))
IS_MSYS := $(filter %msys%,$(DETECTED_OS))
IS_CYGWIN := $(filter %cygwin%,$(DETECTED_OS))
IS_WINDOWS := $(or $(IS_MSYS),$(IS_CYGWIN),$(findstring MINGW,$(shell uname 2>/dev/null)))

# Linux/Unix toolchain configuration
ifeq ($(IS_LINUX),)
ifneq ($(IS_WINDOWS),)
# Windows (MSYS/CYGWIN) toolchain configuration
EMBTOOLPATH     = the/PATH/TO/YOU/cross-compilation-tools

EMBTOOLPREFIX   = ${EMBTOOLPATH}/bin/riscv-none-embed

CC              = ${EMBTOOLPREFIX}-gcc.exe
OBJDUMP         = ${EMBTOOLPREFIX}-objdump.exe
OBJCOPY         = ${EMBTOOLPREFIX}-objcopy.exe
PYTHON          = the/PATH/TO/YOU/PATHON.exe

RM              = rm -f
CP              = copy
MV              = mv

CFLAGS          = -march=rv32im -mabi=ilp32 -mcmodel=medlow

LDFLAGS         = -Wl,-Map,${TARGET}.map,-warn-common \
                  -Wl,--gc-sections \
                  -Wl,--no-relax \
                  -nostartfiles \
		  -static

LDLIBS          = -lm -lc -lgcc
else
# Linux/Unix toolchain configuration (same as sim_tools_new/sim/config.mk)
EMBTOOLPREFIX   = riscv32-unknown-elf

CC              = ${EMBTOOLPREFIX}-gcc
OBJDUMP         = ${EMBTOOLPREFIX}-objdump
OBJCOPY         = ${EMBTOOLPREFIX}-objcopy
PYTHON          = python3

RM              = rm -f
CP              = cp
MV              = mv

CFLAGS          = -march=rv32im_zicsr -mabi=ilp32 -mcmodel=medlow

LDFLAGS         = -Wl,-Map,${TARGET}.map,-warn-common \
                  -Wl,--gc-sections \
                  -Wl,--no-relax \
                  -nostartfiles \
                  -static
# When using a riscv64-linux-gnu cross-toolchain but targeting rv32 (ilp32),
# request a 32-bit RISC-V ELF at link time so multilibs are selected correctly.
LDFLAGS        += -Wl,-melf32lriscv

# Avoid linking host/system 64-bit libc/libm from the riscv64 toolchain sysroot
# when targeting rv32 ilp32 via multilib. Use libgcc only (embedded) to avoid
# 'file in wrong format' errors.
LDLIBS          = -lgcc
endif
endif

# for c/asm tools
INCLUDES        = 

INCFILES        = -I${PROJPATH}/libs \
                  -I${PROJPATH}/libs/_sdk \
                  -I${PROJPATH}/libs/_sdk/systick \
                  -I${PROJPATH}/libs/_sdk/timer \
                  -I${PROJPATH}/libs/_sdk/uart \
                  -I${PROJPATH}/libs/_abi \
                  -I${PROJPATH}/libs/_utilities

ASMFILES        = ${PROJPATH}/libs/_startup/start.S \
                  ${PROJPATH}/libs/_startup/trap.S

CFILES          = ${PROJPATH}/libs/_sdk/systick/*.c \
                  ${PROJPATH}/libs/_sdk/timer/*.c \
                  ${PROJPATH}/libs/_sdk/uart/*.c \
                  ${PROJPATH}/libs/_abi/*.c \
                  ${PROJPATH}/libs/_utilities/*.c
