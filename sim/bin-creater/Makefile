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

CFLAGS         += -O0 -nostartfiles -Wl,-e,_jump
#CFLAGS         += -g

LDFLAGS        += -T${WORKPATH}/link.lds

LDLIBS         += 

ASMFILES       += 

CFILES         += ${WORKPATH}/main.c

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
