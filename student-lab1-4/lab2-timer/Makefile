.PHONY: all compile run clean wave

# 默认目标：编译并运行
all: compile run

# 编译目标
compile:
	iverilog -DTESTBENCH_VCS -o timer_tb timer_tb.sv lab2_timer.v pa_chip_param.v

# 运行目标
run: compile
	vvp timer_tb

# 波形目标
wave: compile
	vvp timer_tb
	gtkwave timer.vcd timer.gtkw &

# 清理目标
clean:
	rm -f timer_tb timer.vcd timer.view
