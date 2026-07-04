.PHONY: all compile run clean wave

CLINT_SRC ?= ../../rtl/core/pa_core_clint.v

# 默认目标：编译并运行
all: compile run

# 编译目标
compile:
	iverilog -DTESTBENCH_VCS -o clint_tb clint_tb.sv $(CLINT_SRC) pa_dff.v pa_chip_param.v

# 运行目标
run: compile
	vvp clint_tb

# 波形目标
wave: compile
	vvp clint_tb
	gtkwave clint.vcd clint.gtkw &

# 清理目标
clean:
	rm -f clint_tb clint.vcd clint.view
