`timescale 1ns/1ps

module tb_pcgen;

`include "../rtl/pa_chip_param.v"

reg clk;
reg rst_n;
reg reset_flag;
reg hold_flag;
reg jump_flag;
reg [`DATA_BUS_WIDTH-1:0] jump_addr;
wire [`DATA_BUS_WIDTH-1:0] pc;
integer errors;

pa_core_pcgen dut (
    .clk_i          (clk),
    .rst_n_i        (rst_n),
    .reset_flag_i   (reset_flag),
    .hold_flag_i    (hold_flag),
    .jump_flag_i    (jump_flag),
    .jump_addr_i    (jump_addr),
    .pc_o           (pc)
);

always #5 clk = ~clk;

task cycle;
    begin
        @(negedge clk);
    end
endtask

task check_pc;
    input [`DATA_BUS_WIDTH-1:0] exp;
    input [255:0] label;
    begin
        if (pc !== exp) begin
            errors = errors + 1;
            $display("[FAIL] %0t %0s pc=%h exp=%h", $time, label, pc, exp);
        end
    end
endtask

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    reset_flag = 1'b0;
    hold_flag = 1'b0;
    jump_flag = 1'b0;
    jump_addr = 32'h8000_1000;
    errors = 0;

    repeat (3) cycle();
    rst_n = 1'b1;
    cycle();
    check_pc(32'h8000_0004, "normal increment after reset");

    hold_flag = 1'b1;
    cycle();
    check_pc(32'h8000_0004, "hold keeps pc");

    jump_flag = 1'b1;
    jump_addr = 32'h8000_1234;
    cycle();
    check_pc(32'h8000_1234, "jump wins over hold");

    jump_flag = 1'b0;
    hold_flag = 1'b0;
    cycle();
    check_pc(32'h8000_1238, "increment after jump");

    reset_flag = 1'b1;
    cycle();
    check_pc(32'h8000_0000, "software reset");

    if (errors == 0) begin
        $display("[PASS] tb_pcgen");
        $finish;
    end
    else begin
        $display("[FAIL] tb_pcgen errors=%0d", errors);
        $fatal(1);
    end
end

endmodule
