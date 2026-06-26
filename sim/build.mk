#/*
# * Copyright {c} 2020-2021, SERI Development Team
# *
# * SPDX-License-Identifier: Apache-2.0
# *
# * Change Logs:
# * Date         Author          Notes
# * 2022-04-04   Lyons           first version
# */

# ============================================
# 项目路径配置 - 只需修改这里
# ============================================
# NEMU模拟器路径
NEMU_PATH      ?= $(abspath $(PROJPATH)/nemu)

# RTL仿真工具路径
SIM_TOOLS_PATH ?= $(abspath $(PROJPATH)/diff-tools/sim_tools_simple)
# ============================================

# Detect OS for cross-platform compatibility
DETECTED_OS := $(shell echo $$OSTYPE)
IS_LINUX := $(filter %linux%,$(DETECTED_OS))
IS_MSYS := $(filter %msys%,$(DETECTED_OS))
IS_CYGWIN := $(filter %cygwin%,$(DETECTED_OS))
ifeq ($(OS),Windows_NT)
IS_WINDOWS := Windows_NT
else
UNAME_S := $(shell uname 2>/dev/null)
IS_WINDOWS := $(or $(IS_MSYS),$(IS_CYGWIN),$(findstring MINGW,$(UNAME_S)))
endif

ifneq ($(IS_WINDOWS),)
ECHO_INFO = @echo [INFO]
ECHO_ERROR = @echo [ERROR]
else
COLORS = "\033[32m"
COLORE = "\033[0m"
ECHO_INFO = @echo -e ${COLORS}[INFO]
ECHO_ERROR = @echo -e ${COLORS}[ERROR]
endif
SIM_PATH=$(PWD)

.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf "\n"
	@printf "Usage: make <target> [MODE=b]\n"
	@printf "\n"
	@printf "Main targets:\n"
	@printf "  %-16s %s\n" "run" "Build and run with NEMU"
	@printf "  %-16s %s\n" "rtl_run" "Build and run with Verilator RTL simulation"
	@printf "  %-16s %s\n" "trace_run" "Build and run RTL simulation with waveform trace"
	@printf "  %-16s %s\n" "build" "Build riscv.elf, riscv.dump, riscv.bin and riscv.coe"
	@printf "\n"
	@printf "Utility targets:\n"
	@printf "  %-16s %s\n" "wave" "Open waveform viewer"
	@printf "  %-16s %s\n" "gtkwave" "Open waveform viewer"
	@printf "  %-16s %s\n" "rtl-sync" "Sync RTL files into diff-tools"
	@printf "  %-16s %s\n" "clean" "Clean this app and RTL simulation outputs"
	@printf "  %-16s %s\n" "clean-sim-tools" "Clean only RTL simulation outputs"
	@printf "  %-16s %s\n" "clean-all" "Clean this app, RTL simulation outputs, and NEMU"
	@printf "\n"
	@printf "Examples:\n"
	@printf "  make run\n"
	@printf "  make run MODE=b\n"
	@printf "  make rtl_run\n"
	@printf "\n"

.PHONY: build
build:
	$(ECHO_INFO) compile c/asm file ...${COLORE}
	${Q}${CC} ${INCLUDES} ${INCFILES} ${CFLAGS} ${LDFLAGS} ${LDLIBS} ${ASMFILES} ${CFILES} -o ${TARGET}.elf
	$(ECHO_INFO) create dump file ...${COLORE}
	${Q}${OBJDUMP} -D -S ${TARGET}.elf > ${TARGET}.dump
	$(ECHO_INFO) create image file ...${COLORE}
	${Q}${OBJCOPY} -S -O binary -j .init -j .text -j .data -j .bss -j .abi_section -j .abi_jump ${TARGET}.elf ${TARGET}.bin
	${Q}${BIN2COE} ${TARGET}.bin
	$(ECHO_INFO) execute done${COLORE}

.PHONY: clean
clean:
	@echo [INFO] clean project ...
	@find . -maxdepth 1 -type f ! -name "*.c" ! -name "*.h" ! -name "Makefile" ! -name "*.lds" ! -name "*.S" -delete
	@echo [INFO] execute done
ifneq ($(IS_WINDOWS),)
	@echo -e ${COLORS}[ERROR] 'clean' is only supported on Linux.${COLORE}
	@exit 1
endif

.PHONY: clean-all
clean-all: clean
	$(MAKE) -C ${NEMU_PATH} clean-all
	$(MAKE) -C ${SIM_TOOLS_PATH} clean

.PHONY: clean-sim-tools
clean-sim-tools:
	$(MAKE) -C ${SIM_TOOLS_PATH} clean

	
.PHONY: run
run: build
ifneq ($(IS_WINDOWS),)
	@echo -e ${COLORS}[ERROR] 'run' is only supported on Linux.${COLORE}
	@exit 1
endif
	@echo -e ${COLORS}[INFO] Running in nemu ...${COLORE}
	$(MAKE) -C ${NEMU_PATH} \
		SIM_PATH=$(SIM_PATH) \
		MODE=$(MODE) \
		run_auto

.PHONY: trace_run
trace_run: build
ifneq ($(IS_WINDOWS),)
	@echo -e ${COLORS}[ERROR] 'trace_run' is only supported on Linux.${COLORE}
	@exit 1
endif
	@echo -e ${COLORS}[INFO] Running in verilator ...${COLORE}
	$(MAKE) -C ${SIM_TOOLS_PATH} \
	BIN_PATH=$(SIM_PATH)/riscv.bin \
	tracerun

.PHONY: gtkwave wave
gtkwave:
ifneq ($(IS_WINDOWS),)
	@echo -e ${COLORS}[ERROR] 'gtkwave' is only supported on Linux.${COLORE}
	@exit 1
endif
	$(MAKE) -C ${SIM_TOOLS_PATH} gtkwave

wave: gtkwave

.PHONY: rtl-sync
rtl-sync:
	$(MAKE) -C $(abspath $(PROJPATH)/diff-tools) rtl-sync

rtl_run: build
ifneq ($(IS_WINDOWS),)
	@echo -e ${COLORS}[ERROR] 'rtl_run' is only supported on Linux.${COLORE}
	@exit 1
endif
	@echo -e ${COLORS}[INFO] Running in verilator ...${COLORE}
	$(MAKE) -C ${SIM_TOOLS_PATH} \
	BIN_PATH=$(SIM_PATH)/riscv.bin \
	run
