.PHONY: all compile run clean wave

# 默认目标：编译并运行
all: compile run

# 编译目标
compile:
	iverilog -DTESTBENCH_VCS -o uart_tb uart_tb.sv lab4_uart.v pa_dff.v pa_chip_param.v

# 运行目标
run: compile
	vvp uart_tb

# 波形目标
wave: compile
	vvp uart_tb
	gtkwave uart.vcd uart.gtkw &

# 清理目标
clean:
	rm -f uart_tb uart.vcd uart.view
