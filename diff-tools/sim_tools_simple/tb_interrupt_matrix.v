`timescale 1ns/1ps

module tb_interrupt_matrix;

`include "../rtl/pa_chip_param.v"

reg                         clk;
reg                         rst_n;
reg                         inst_set;
reg  [2:0]                  inst_func;
reg  [`ADDR_BUS_WIDTH-1:0]  pc;
reg  [`DATA_BUS_WIDTH-1:0]  inst;
reg  [`DATA_BUS_WIDTH-1:0]  csr_mtvec;
reg  [`DATA_BUS_WIDTH-1:0]  csr_mepc;
reg  [`DATA_BUS_WIDTH-1:0]  csr_mstatus;
reg                         irq;
reg                         jump_flag;
reg  [`DATA_BUS_WIDTH-1:0]  jump_addr;
reg                         hold_flag;

wire [`CSR_BUS_WIDTH-1:0]   csr_waddr;
wire                        csr_waddr_vld;
wire [`DATA_BUS_WIDTH-1:0]  csr_wdata;
wire                        hold_flag_o;
wire                        jump_flag_o;
wire [`DATA_BUS_WIDTH-1:0]  jump_addr_o;

integer                     errors;

pa_core_clint dut (
    .clk_i                  (clk),
    .rst_n_i                (rst_n),
    .inst_set_i             (inst_set),
    .inst_func_i            (inst_func),
    .pc_i                   (pc),
    .inst_i                 (inst),
    .csr_mtvec_i            (csr_mtvec),
    .csr_mepc_i             (csr_mepc),
    .csr_mstatus_i          (csr_mstatus),
    .irq_i                  (irq),
    .jump_flag_i            (jump_flag),
    .jump_addr_i            (jump_addr),
    .hold_flag_i            (hold_flag),
    .csr_waddr_o            (csr_waddr),
    .csr_waddr_vld_o        (csr_waddr_vld),
    .csr_wdata_o            (csr_wdata),
    .hold_flag_o            (hold_flag_o),
    .jump_flag_o            (jump_flag_o),
    .jump_addr_o            (jump_addr_o)
);

always #5 clk = ~clk;

task cycle;
    begin
        @(negedge clk);
    end
endtask

task fail;
    input [1023:0] label;
    begin
        errors = errors + 1;
        $display("[FAIL] %0t %0s", $time, label);
    end
endtask

task reset_case;
    begin
        rst_n       = 1'b0;
        inst_set    = 1'b0;
        inst_func   = 3'b000;
        pc          = 32'h8000_0100;
        inst        = 32'h0000_0013;
        csr_mtvec   = 32'h8000_017c;
        csr_mepc    = 32'h8000_2000;
        csr_mstatus = 32'h0000_1888;
        irq         = 1'b0;
        jump_flag   = 1'b0;
        jump_addr   = 32'h8000_1000;
        hold_flag   = 1'b0;
        repeat (3) cycle();
        rst_n       = 1'b1;
        repeat (2) cycle();
    end
endtask

task pulse_irq;
    begin
        irq = 1'b1;
        cycle();
        irq = 1'b0;
    end
endtask

task assert_no_trap_cycles;
    input integer cycles;
    input [1023:0] label;
    integer i;
    begin
        for (i = 0; i < cycles; i = i + 1) begin
            cycle();
            if (csr_waddr_vld || jump_flag_o || hold_flag_o) begin
                errors = errors + 1;
                $display("[FAIL] %0t %0s unexpected trap/hold csr_vld=%b jump=%b hold=%b",
                         $time, label, csr_waddr_vld, jump_flag_o, hold_flag_o);
            end
        end
    end
endtask

task pulse_jump;
    input [`DATA_BUS_WIDTH-1:0] target;
    begin
        jump_addr = target;
        jump_flag = 1'b1;
        cycle();
        jump_flag = 1'b0;
    end
endtask

task expect_csr_now_or_later;
    input [`CSR_BUS_WIDTH-1:0] exp_addr;
    input [`DATA_BUS_WIDTH-1:0] exp_data;
    input [1023:0] label;
    integer i;
    reg found;
    begin
        found = 1'b0;
        for (i = 0; i < 12; i = i + 1) begin
            if (csr_waddr_vld) begin
                found = 1'b1;
                if (csr_waddr !== exp_addr || csr_wdata !== exp_data) begin
                    errors = errors + 1;
                    $display("[FAIL] %0t %0s csr got addr=%h data=%h exp addr=%h data=%h",
                             $time, label, csr_waddr, csr_wdata, exp_addr, exp_data);
                end
                i = 12;
            end
            else begin
                cycle();
            end
        end
        if (!found) begin
            errors = errors + 1;
            $display("[FAIL] %0t %0s csr write not observed", $time, label);
        end
        cycle();
    end
endtask

task expect_mtvec_jump;
    input [1023:0] label;
    integer i;
    reg found;
    begin
        found = 1'b0;
        for (i = 0; i < 12; i = i + 1) begin
            if (jump_flag_o) begin
                found = 1'b1;
                if (jump_addr_o !== csr_mtvec) begin
                    errors = errors + 1;
                    $display("[FAIL] %0t %0s jump got=%h exp=%h",
                             $time, label, jump_addr_o, csr_mtvec);
                end
                i = 12;
            end
            else begin
                cycle();
            end
        end
        if (!found) begin
            errors = errors + 1;
            $display("[FAIL] %0t %0s jump not observed", $time, label);
        end
        cycle();
    end
endtask

task complete_pending_on_jump;
    input [`DATA_BUS_WIDTH-1:0] target;
    input [1023:0] label;
    begin
        pulse_jump(target);
        expect_csr_now_or_later(`CSR_MEPC, target, label);
        expect_csr_now_or_later(`CSR_MSTATUS, 32'h0000_1880, "mstatus");
        expect_csr_now_or_later(`CSR_MCAUSE, 32'h8000_0003, "mcause");
        expect_mtvec_jump("mtvec");
    end
endtask

task jump_waits_for_side_effect_case;
    begin
        $display("[TEST] irq plus jump waits until older side effect is drained");
        reset_case();
        pulse_irq();
        jump_addr = 32'h8000_5000;
        jump_flag = 1'b1;
        hold_flag = 1'b1;
        cycle();
        jump_flag = 1'b0;
        assert_no_trap_cycles(4, "jump with older side effect");
        hold_flag = 1'b0;
        expect_csr_now_or_later(`CSR_MEPC, 32'h8000_5000, "drained jump mepc");
        expect_csr_now_or_later(`CSR_MSTATUS, 32'h0000_1880, "drained jump mstatus");
        expect_csr_now_or_later(`CSR_MCAUSE, 32'h8000_0003, "drained jump mcause");
        expect_mtvec_jump("drained jump mtvec");
    end
endtask

task pending_until_jump_case;
    input [1023:0] label;
    input [2:0] func;
    input no_side_effect_hold;
    input [`DATA_BUS_WIDTH-1:0] target;
    begin
        $display("[TEST] %0s", label);
        reset_case();
        inst_set = 1'b1;
        inst_func = func;
        hold_flag = no_side_effect_hold;
        pulse_irq();
        assert_no_trap_cycles(6, label);
        hold_flag = 1'b0;
        assert_no_trap_cycles(2, label);
        complete_pending_on_jump(target, label);
    end
endtask

task immediate_jump_case;
    input [1023:0] label;
    input [`DATA_BUS_WIDTH-1:0] target;
    begin
        $display("[TEST] %0s", label);
        reset_case();
        pulse_irq();
        pulse_jump(target);
        expect_csr_now_or_later(`CSR_MEPC, target, label);
        expect_csr_now_or_later(`CSR_MSTATUS, 32'h0000_1880, "mstatus");
        expect_csr_now_or_later(`CSR_MCAUSE, 32'h8000_0003, "mcause");
        expect_mtvec_jump("mtvec");
    end
endtask

initial begin
    clk = 1'b0;
    errors = 0;

    pending_until_jump_case("irq during ALU/add waits for later control-flow boundary",
                            3'b000, 1'b0, 32'h8000_1100);
    pending_until_jump_case("irq during CSR instruction waits for later control-flow boundary",
                            3'b000, 1'b0, 32'h8000_1200);
    pending_until_jump_case("irq during load/store busy waits for later control-flow boundary",
                            3'b000, 1'b1, 32'h8000_1300);
    pending_until_jump_case("irq during multicycle div/rem busy waits for later control-flow boundary",
                            3'b000, 1'b1, 32'h8000_1400);
    pending_until_jump_case("irq during branch-not-taken waits for later taken control-flow boundary",
                            3'b000, 1'b0, 32'h8000_1500);

    immediate_jump_case("irq then branch-taken saves target PC", 32'h8000_2000);
    immediate_jump_case("irq then jal saves target PC", 32'h8000_3000);
    immediate_jump_case("irq then jalr saves target PC", 32'h8000_4000);
    jump_waits_for_side_effect_case();

    if (errors == 0) begin
        $display("[PASS] tb_interrupt_matrix");
        $finish;
    end
    else begin
        $display("[FAIL] tb_interrupt_matrix errors=%0d", errors);
        $fatal(1);
    end
end

endmodule
