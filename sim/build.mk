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
IS_WINDOWS := $(or $(IS_MSYS),$(IS_CYGWIN),$(findstring MINGW,$(shell uname 2>/dev/null)))

COLORS = "\033[32m"
COLORE = "\033[0m"
SIM_PATH=$(PWD)

.PHONY: help
help:
	@echo "help     - help menu             "
	@echo "build    - compile c/asm file    "

.PHONY: build
build:
	@echo -e ${COLORS}[INFO] compile c/asm file ...${COLORE}
	${Q}${CC} ${INCLUDES} ${INCFILES} ${CFLAGS} ${LDFLAGS} ${LDLIBS} ${ASMFILES} ${CFILES} -o ${TARGET}.elf
	@echo -e ${COLORS}[INFO] create dump file ...${COLORE}
	${Q}${OBJDUMP} -D -S ${TARGET}.elf > ${TARGET}.dump
	@echo -e ${COLORS}[INFO] create image file ...${COLORE}
	${Q}${OBJCOPY} -S -O binary -j .init -j .text -j .data -j .bss -j .abi_section -j .abi_jump ${TARGET}.elf ${TARGET}.bin
	${Q}${PYTHON} ${PROJPATH}/scripts/bin2coe.py ${TARGET}.bin
	@echo -e ${COLORS}[INFO] execute done${COLORE}

.PHONY: clean
clean:
	@echo [INFO] clean project ...
	@find . -maxdepth 1 -type f ! -name "*.c" ! -name "*.h" ! -name "Makefile" ! -name "*.lds" ! -name "*.S" -delete
	@echo [INFO] execute done
ifneq ($(IS_WINDOWS),)
	@echo -e ${COLORS}[ERROR] 'clean' is only supported on Linux.${COLORE}
	@exit 1
endif
	$(MAKE) -C ${NEMU_PATH} clean-all
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
