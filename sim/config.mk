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
IS_WINDOWS := $(or $(filter Windows_NT,$(OS)),$(IS_MSYS),$(IS_CYGWIN),$(findstring MINGW,$(shell uname 2>NUL)))

# Linux/Unix toolchain configuration
ifeq ($(IS_LINUX),)
ifneq ($(IS_WINDOWS),)
# Windows toolchain configuration.
#
# The tools may either be in PATH:
#   make build TOOLCHAIN_PREFIX=riscv-none-embed
# or under a local installation directory:
#   make build TOOLCHAIN_PATH=C:/path/to/toolchain TOOLCHAIN_PREFIX=riscv-none-embed
#
# Common prefixes are:
#   riscv-none-embed
#   riscv32-unknown-elf
TOOLCHAIN_PREFIX ?= riscv-none-embed
TOOLCHAIN_PATH   ?= C:/Users/nana4/riscv-related/teacher_training
EXEEXT           := .exe

TOOLCHAIN_ROOT  := $(subst \,/,$(TOOLCHAIN_PATH))
ifneq ($(wildcard $(TOOLCHAIN_ROOT)/$(TOOLCHAIN_PREFIX)/bin/$(TOOLCHAIN_PREFIX)-gcc$(EXEEXT)),)
TOOLCHAIN_BINDIR := $(TOOLCHAIN_ROOT)/$(TOOLCHAIN_PREFIX)/bin/
else ifneq ($(wildcard $(TOOLCHAIN_ROOT)/bin/$(TOOLCHAIN_PREFIX)-gcc$(EXEEXT)),)
TOOLCHAIN_BINDIR := $(TOOLCHAIN_ROOT)/bin/
else
TOOLCHAIN_BINDIR := $(if $(TOOLCHAIN_PATH),$(TOOLCHAIN_ROOT)/bin/,)
endif

CC              = $(TOOLCHAIN_BINDIR)$(TOOLCHAIN_PREFIX)-gcc$(EXEEXT)
OBJDUMP         = $(TOOLCHAIN_BINDIR)$(TOOLCHAIN_PREFIX)-objdump$(EXEEXT)
OBJCOPY         = $(TOOLCHAIN_BINDIR)$(TOOLCHAIN_PREFIX)-objcopy$(EXEEXT)
PYTHON          ?= python
BIN2COE         = powershell -NoProfile -ExecutionPolicy Bypass -File ${PROJPATH}/scripts/bin2coe.ps1

RM              = del /Q
CP              = copy
MV              = move

RISCV_ARCH      ?= rv32im
CFLAGS          = -march=$(RISCV_ARCH) -mabi=ilp32 -mcmodel=medlow

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
BIN2COE         = ${PYTHON} ${PROJPATH}/scripts/bin2coe.py

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

CFILES          = $(wildcard ${PROJPATH}/libs/_sdk/systick/*.c) \
                  $(wildcard ${PROJPATH}/libs/_sdk/timer/*.c) \
                  $(wildcard ${PROJPATH}/libs/_sdk/uart/*.c) \
                  $(wildcard ${PROJPATH}/libs/_abi/*.c) \
                  $(wildcard ${PROJPATH}/libs/_utilities/*.c)
