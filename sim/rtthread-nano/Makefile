#/*
# * Copyright {c} 2020-2021, SERI Development Team
# *
# * SPDX-License-Identifier: Apache-2.0
# *
# * Change Logs:
# * Date         Author          Notes
# * 2022-03-27   Lyons           first version
# */

TARGET          = riscv

Q               = @

PROJPATH        = ../..
WORKPATH        = .

include ../config.mk

INCLUDES       += -I. \
                  -I${PROJPATH}/libs/_kernel/bsp \
                  -I${PROJPATH}/libs/_kernel/components/finsh \
                  -I${PROJPATH}/libs/_kernel/include \
                  -I${PROJPATH}/libs/_kernel/include/libc \
                  -I${PROJPATH}/libs/_kernel/libcpu/risc-v/common \
                  -I${WORKPATH}/coremark

INCFILES       += 

CFLAGS         += -O3 -ffunction-sections -fdata-sections
CFLAGS         += -DITERATIONS=10 -DPERFORMANCE_RUN=1
#CFLAGS         += -g
CFLAGS         += -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast
CFLAGS         += -DOS_ENABLE_RT_THREAD
CFLAGS         += -DSIMULATION_PRINT_VERSION
#CFLAGS         += -DSIMULATION_PRINT_THREAD_SWITCH

LDFLAGS        += -T${WORKPATH}/link.lds

LDLIBS         += 

ASMFILES       += ${PROJPATH}/libs/_kernel/libcpu/risc-v/common/context_gcc.S

CFILES         += ${PROJPATH}/libs/_kernel/bsp/board.c \
                  ${PROJPATH}/libs/_kernel/components/device/device.c \
                  ${PROJPATH}/libs/_kernel/components/finsh/cmd.c \
                  ${PROJPATH}/libs/_kernel/components/finsh/finsh_port.c \
                  ${PROJPATH}/libs/_kernel/components/finsh/msh.c \
                  ${PROJPATH}/libs/_kernel/components/finsh/shell.c \
                  ${PROJPATH}/libs/_kernel/libcpu/risc-v/common/cpuport.c \
                  ${PROJPATH}/libs/_kernel/src/clock.c \
                  ${PROJPATH}/libs/_kernel/src/components.c \
                  ${PROJPATH}/libs/_kernel/src/cpu.c \
                  ${PROJPATH}/libs/_kernel/src/idle.c \
                  ${PROJPATH}/libs/_kernel/src/ipc.c \
                  ${PROJPATH}/libs/_kernel/src/irq.c \
                  ${PROJPATH}/libs/_kernel/src/kservice.c \
                  ${PROJPATH}/libs/_kernel/src/mem.c \
                  ${PROJPATH}/libs/_kernel/src/memheap.c \
                  ${PROJPATH}/libs/_kernel/src/mempool.c \
                  ${PROJPATH}/libs/_kernel/src/object.c \
                  ${PROJPATH}/libs/_kernel/src/scheduler.c \
                  ${PROJPATH}/libs/_kernel/src/slab.c \
                  ${PROJPATH}/libs/_kernel/src/thread.c \
                  ${PROJPATH}/libs/_kernel/src/timer.c

CFILES         += ${WORKPATH}/init.c \
                  ${WORKPATH}/interrupt.c \
                  ${WORKPATH}/main.c \
                  ${WORKPATH}/coremark/core_list_join.c \
                  ${WORKPATH}/coremark/core_main.c \
                  ${WORKPATH}/coremark/core_matrix.c \
                  ${WORKPATH}/coremark/core_portme.c \
                  ${WORKPATH}/coremark/core_state.c \
                  ${WORKPATH}/coremark/core_util.c

include ../build.mk

.PHONY: build_app
build_app:
	@echo -e ${COLORS}[INFO] compile c/asm file ...${COLORE}
	${Q}${CC} ${INCLUDES} ${INCFILES} ${CFLAGS} ${LDFLAGS} ${LDLIBS} ${ASMFILES} ${CFILES} -o ${TARGET}.elf
	@echo -e ${COLORS}[INFO] create dump file ...${COLORE}
	${Q}${OBJDUMP} -D -S ${TARGET}.elf > ${TARGET}.dump
	@echo -e ${COLORS}[INFO] create image file ...${COLORE}
	${Q}${OBJCOPY} -S -O binary  ${TARGET}.elf ${TARGET}_app.bin
	@echo -e ${COLORS}[INFO] execute done${COLORE}
