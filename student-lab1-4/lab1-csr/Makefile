.PHONY: all compile run clean wave

# 默认目标：编译并运行
all: compile run

# 编译目标
compile:
	iverilog -DTESTBENCH_VCS -o csr_tb csr_tb.sv lab1_CSR.v pa_chip_param.v

# 运行目标
run: compile
	vvp csr_tb

# 清理目标
clean:
	rm -f csr_tb csr.vcd csr.view

# 波形目标
wave: compile
	vvp csr_tb
	gtkwave csr.vcd csr.gtkw &
