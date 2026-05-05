# Simple Makefile for PA-CHIP simulator

VERILATOR = verilator

TOP_MODULE = pa_chip_top_sim
BIN_FILE ?= riscv.bin
SIM_ARGS ?=

BIN_PATH ?= ./riscv.bin

RTL_DIR = ../rtl

RTL_FILES = \
	$(RTL_DIR)/pa_chip_top_sim.v \
	$(RTL_DIR)/core/pa_core_top.v \
	$(RTL_DIR)/core/pa_core_pcgen.v \
	$(RTL_DIR)/core/pa_core_idu.v \
	$(RTL_DIR)/core/pa_core_exu.v \
	$(RTL_DIR)/core/pa_core_exu_mul.v \
	$(RTL_DIR)/core/pa_core_exu_div.v \
	$(RTL_DIR)/core/pa_core_mau.v \
	$(RTL_DIR)/core/pa_core_rtu.v \
	$(RTL_DIR)/core/pa_core_clint.v \
	$(RTL_DIR)/core/pa_core_csr.v \
	$(RTL_DIR)/core/pa_core_xreg.v \
	$(RTL_DIR)/perips/pa_perips_tcm.v \
	$(RTL_DIR)/perips/pa_perips_timer.v \
	$(RTL_DIR)/perips/pa_perips_uart.v \
	$(RTL_DIR)/soc/pa_soc_rbm.v \
	$(RTL_DIR)/utils/pa_dff.v

VERILATOR_FLAGS = -j 8 --Wno-fatal -DTESTBENCH_VCS \
                  --Wno-TIMESCALEMOD \
                  --Wno-WIDTHTRUNC --Wno-WIDTHEXPAND \
                  --Wno-UNSIGNED --Wno-CASEINCOMPLETE --Wno-COMBDLY \
                  --Wno-UNOPTFLAT
CXXFLAGS = -std=c++17 -O2 -g

all:
	rm -rf obj_dir
	OBJCACHE= $(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOP_MODULE) \
		--cc --trace -O0 --trace-structs --exe --build \
		--CFLAGS "$(CXXFLAGS)" \
		-I$(RTL_DIR) -I.. -I../rtl \
		-y $(RTL_DIR) \
		+define+BIN_PATH=\"$(BIN_PATH)\" \
		$(RTL_FILES) \
		main.cpp

run: all
	ln -sf $(abspath $(BIN_FILE)) obj_dir/riscv.bin
	cd obj_dir && ./V$(TOP_MODULE) --bin riscv.bin $(SIM_ARGS)

tracerun: all
	ln -sf $(abspath $(BIN_FILE)) obj_dir/riscv.bin
	cd obj_dir && ./V$(TOP_MODULE) --bin riscv.bin --trace $(SIM_ARGS)

runtrace: tracerun

clint-test:
	iverilog -g2012 -I$(RTL_DIR) -I$(RTL_DIR)/core \
		-o /tmp/tb_clint.vvp \
		tb_clint.v \
		$(RTL_DIR)/core/pa_core_clint.v \
		$(RTL_DIR)/utils/pa_dff.v
	vvp /tmp/tb_clint.vvp

interrupt-matrix-test:
	iverilog -g2012 -I$(RTL_DIR) -I$(RTL_DIR)/core \
		-o /tmp/tb_interrupt_matrix.vvp \
		tb_interrupt_matrix.v \
		$(RTL_DIR)/core/pa_core_clint.v \
		$(RTL_DIR)/utils/pa_dff.v
	vvp /tmp/tb_interrupt_matrix.vvp

pcgen-test:
	iverilog -g2012 -I$(RTL_DIR) -I$(RTL_DIR)/core \
		-o /tmp/tb_pcgen.vvp \
		tb_pcgen.v \
		$(RTL_DIR)/core/pa_core_pcgen.v
	vvp /tmp/tb_pcgen.vvp

exu-control-test:
	iverilog -g2012 -I$(RTL_DIR) -I$(RTL_DIR)/core \
		-o /tmp/tb_exu_control.vvp \
		tb_exu_control.v \
		$(RTL_DIR)/core/pa_core_exu.v \
		$(RTL_DIR)/core/pa_core_exu_mul.v \
		$(RTL_DIR)/core/pa_core_exu_div.v \
		$(RTL_DIR)/utils/pa_dff.v
	vvp /tmp/tb_exu_control.vvp

unit-test: pcgen-test exu-control-test clint-test interrupt-matrix-test

clean:
	rm -rf obj_dir
	rm -f sim.vcd

.PHONY: all clean run tracerun runtrace clint-test interrupt-matrix-test pcgen-test exu-control-test unit-test
