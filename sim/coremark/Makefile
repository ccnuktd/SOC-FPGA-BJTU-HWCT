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

INCLUDES       += -I.

INCFILES       += 

CFLAGS         += -O3 -fno-common -funroll-loops -finline-functions --param max-inline-insns-auto=20 -falign-functions=4 -falign-jumps=4 -falign-loops=4 -falign-jumps=4 -falign-loops=4
#CFLAGS         += -g
CFLAGS         += -DITERATIONS=1000 -DPERFORMANCE_RUN=1

LDFLAGS        += -T${WORKPATH}/link.lds

LDLIBS         += 

ASMFILES       += 

CFILES         += ${WORKPATH}/core_list_join.c \
                  ${WORKPATH}/core_main.c \
                  ${WORKPATH}/core_matrix.c \
                  ${WORKPATH}/core_state.c \
                  ${WORKPATH}/core_util.c \
                  ${WORKPATH}/core_portme.c

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
