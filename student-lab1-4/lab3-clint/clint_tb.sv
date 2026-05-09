`timescale 1ns/1ps
`define TESTBENCH_VCS
`include "pa_chip_param.v"

module clint_tb;

reg                         clk_i;
reg                         rst_n_i;
reg                         inst_set_i;
reg  [2:0]                  inst_func_i;
reg  [`ADDR_BUS_WIDTH-1:0]  pc_i;
reg  [`DATA_BUS_WIDTH-1:0]  inst_i;
reg  [`DATA_BUS_WIDTH-1:0]  csr_mtvec_i;
reg  [`DATA_BUS_WIDTH-1:0]  csr_mepc_i;
reg  [`DATA_BUS_WIDTH-1:0]  csr_mstatus_i;
reg                         irq_i;
reg                         jump_flag_i;
reg  [`DATA_BUS_WIDTH-1:0]  jump_addr_i;
reg                         hold_flag_i;
reg  [`ADDR_BUS_WIDTH-1:0]  next_pc_i;
reg                         inst_retire_i;

wire [`CSR_BUS_WIDTH-1:0]   csr_waddr_o;
wire                        csr_waddr_vld_o;
wire [`DATA_BUS_WIDTH-1:0]  csr_wdata_o;
wire                        hold_flag_o;
wire                        jump_flag_o;
wire [`DATA_BUS_WIDTH-1:0]  jump_addr_o;

integer                     test_count;
integer                     pass_count;
integer                     fail_count;

pa_core_clint dut (
    .clk_i                  (clk_i),
    .rst_n_i                (rst_n_i),
    .inst_set_i             (inst_set_i),
    .inst_func_i            (inst_func_i),
    .pc_i                   (pc_i),
    .inst_i                 (inst_i),
    .csr_mtvec_i            (csr_mtvec_i),
    .csr_mepc_i             (csr_mepc_i),
    .csr_mstatus_i          (csr_mstatus_i),
    .irq_i                  (irq_i),
    .jump_flag_i            (jump_flag_i),
    .jump_addr_i            (jump_addr_i),
    .hold_flag_i            (hold_flag_i),
    .next_pc_i              (next_pc_i),
    .inst_retire_i          (inst_retire_i),
    .csr_waddr_o            (csr_waddr_o),
    .csr_waddr_vld_o        (csr_waddr_vld_o),
    .csr_wdata_o            (csr_wdata_o),
    .hold_flag_o            (hold_flag_o),
    .jump_flag_o            (jump_flag_o),
    .jump_addr_o            (jump_addr_o)
);

always #5 clk_i = ~clk_i;

initial begin
    $dumpfile("clint.vcd");
    $dumpvars(0, clint_tb);
end

task cycle;
    begin
        @(negedge clk_i);
    end
endtask

task reset_case;
    begin
        rst_n_i       = 1'b0;
        inst_set_i    = 1'b0;
        inst_func_i   = 3'b000;
        pc_i          = 32'h8000_0100;
        inst_i        = `INST_DATA_NOP;
        csr_mtvec_i   = 32'h8000_017c;
        csr_mepc_i    = 32'h8000_2000;
        csr_mstatus_i = 32'h0000_1888;
        irq_i         = 1'b0;
        jump_flag_i   = 1'b0;
        jump_addr_i   = 32'h8000_1000;
        hold_flag_i   = 1'b0;
        next_pc_i     = 32'h8000_0104;
        inst_retire_i = 1'b0;
        repeat (3) cycle();
        rst_n_i       = 1'b1;
        repeat (2) cycle();
    end
endtask

task record_pass;
    input [1023:0] label;
    begin
        test_count = test_count + 1;
        pass_count = pass_count + 1;
        $display("  [PASS] %0s", label);
    end
endtask

task record_fail;
    input [1023:0] label;
    begin
        test_count = test_count + 1;
        fail_count = fail_count + 1;
        $display("  [FAIL] %0s", label);
        $display("    Debug: inst_set=%b inst_func=%b pc=%h irq=%b mie=%b hold_i=%b jump_i=%b jump_addr_i=%h next_pc_i=%h retire=%b",
                 inst_set_i, inst_func_i, pc_i, irq_i, csr_mstatus_i[3],
                 hold_flag_i, jump_flag_i, jump_addr_i, next_pc_i, inst_retire_i);
        $display("           hold_o=%b jump_o=%b jump_addr_o=%h csr_vld=%b csr_addr=%h csr_data=%h",
                 hold_flag_o, jump_flag_o, jump_addr_o, csr_waddr_vld_o, csr_waddr_o, csr_wdata_o);
        $display("    Hint : compare trap entry timing, pending IRQ capture, CSR write order, and MRET restore behavior.");
    end
endtask

task check_eq1;
    input [1023:0] label;
    input got;
    input exp;
    begin
        if (got === exp) begin
            record_pass(label);
        end
        else begin
            $display("    Expected: %b, Got: %b", exp, got);
            record_fail(label);
        end
    end
endtask

task check_eq32;
    input [1023:0] label;
    input [`DATA_BUS_WIDTH-1:0] got;
    input [`DATA_BUS_WIDTH-1:0] exp;
    begin
        if (got === exp) begin
            record_pass(label);
        end
        else begin
            $display("    Expected: %h, Got: %h", exp, got);
            record_fail(label);
        end
    end
endtask

task expect_no_csr_for;
    input integer cycles;
    input [1023:0] label;
    integer i;
    begin
        for (i = 0; i < cycles; i = i + 1) begin
            cycle();
            if (csr_waddr_vld_o) begin
                record_fail(label);
            end
        end
        record_pass(label);
    end
endtask

task expect_no_trap_cycles;
    input integer cycles;
    input [1023:0] label;
    integer i;
    reg ok;
    begin
        ok = 1'b1;
        for (i = 0; i < cycles; i = i + 1) begin
            cycle();
            if (csr_waddr_vld_o || jump_flag_o || hold_flag_o) begin
                ok = 1'b0;
                $display("    Unexpected trap at %0t: csr_vld=%b jump=%b hold=%b",
                         $time, csr_waddr_vld_o, jump_flag_o, hold_flag_o);
            end
        end

        if (ok) begin
            record_pass(label);
        end
        else begin
            record_fail(label);
        end
    end
endtask

task expect_csr;
    input [`CSR_BUS_WIDTH-1:0] exp_addr;
    input [`DATA_BUS_WIDTH-1:0] exp_data;
    input [1023:0] label;
    integer i;
    reg found;
    begin
        found = 1'b0;
        for (i = 0; i < 16; i = i + 1) begin
            if (csr_waddr_vld_o) begin
                found = 1'b1;
                if (csr_waddr_o === exp_addr && csr_wdata_o === exp_data) begin
                    record_pass(label);
                end
                else begin
                    $display("    Expected CSR: addr=%h data=%h, Got: addr=%h data=%h",
                             exp_addr, exp_data, csr_waddr_o, csr_wdata_o);
                    record_fail(label);
                end
                i = 16;
            end
            else begin
                cycle();
            end
        end

        if (!found) begin
            $display("    Timeout: CSR write addr=%h data=%h was not observed.", exp_addr, exp_data);
            record_fail(label);
        end
        else begin
            cycle();
        end
    end
endtask

task expect_jump;
    input [`DATA_BUS_WIDTH-1:0] exp_addr;
    input [1023:0] label;
    integer i;
    reg found;
    begin
        found = 1'b0;
        for (i = 0; i < 16; i = i + 1) begin
            if (jump_flag_o) begin
                found = 1'b1;
                if (jump_addr_o === exp_addr) begin
                    record_pass(label);
                end
                else begin
                    $display("    Expected jump=%h, Got=%h", exp_addr, jump_addr_o);
                    record_fail(label);
                end
                i = 16;
            end
            else begin
                cycle();
            end
        end

        if (!found) begin
            $display("    Timeout: jump to %h was not observed.", exp_addr);
            record_fail(label);
        end
        else begin
            cycle();
        end
    end
endtask

task pulse_irq;
    begin
        irq_i = 1'b1;
        cycle();
        irq_i = 1'b0;
    end
endtask

task expect_mtvec_jump;
    input [1023:0] label;
    begin
        expect_jump(csr_mtvec_i, label);
    end
endtask

task retire_seq;
    input [`DATA_BUS_WIDTH-1:0] target;
    begin
        next_pc_i     = target;
        inst_retire_i = 1'b1;
        jump_flag_i   = 1'b0;
        cycle();
        inst_retire_i = 1'b0;
    end
endtask

task retire_jump;
    input [`DATA_BUS_WIDTH-1:0] target;
    begin
        next_pc_i     = target;
        jump_addr_i   = target;
        jump_flag_i   = 1'b1;
        inst_retire_i = 1'b1;
        cycle();
        inst_retire_i = 1'b0;
        jump_flag_i   = 1'b0;
    end
endtask

task complete_pending_on_retire;
    input [`DATA_BUS_WIDTH-1:0] target;
    input [1023:0] label;
    begin
        retire_seq(target);
        expect_csr(`CSR_MEPC, target, label);
        expect_csr(`CSR_MSTATUS, 32'h0000_1880, "pending irq writes mstatus");
        expect_csr(`CSR_MCAUSE, 32'h8000_0003, "pending irq writes mcause");
        expect_mtvec_jump("pending irq jumps to mtvec");
    end
endtask

task pending_until_retire_case;
    input [1023:0] label;
    input [`DATA_BUS_WIDTH-1:0] target;
    begin
        $display("\n[TEST] %0s", label);
        reset_case();
        pulse_irq();
        hold_flag_i = 1'b1;
        expect_no_trap_cycles(4, {label, " while no precise retire boundary"});
        hold_flag_i = 1'b0;
        expect_no_trap_cycles(2, {label, " after busy clears but before retire"});
        complete_pending_on_retire(target, label);
    end
endtask

task immediate_retire_case;
    input [1023:0] label;
    input [`DATA_BUS_WIDTH-1:0] target;
    input is_jump;
    begin
        $display("\n[TEST] %0s", label);
        reset_case();
        pulse_irq();
        if (is_jump) begin
            retire_jump(target);
        end
        else begin
            retire_seq(target);
        end
        expect_csr(`CSR_MEPC, target, label);
        expect_csr(`CSR_MSTATUS, 32'h0000_1880, "immediate irq writes mstatus");
        expect_csr(`CSR_MCAUSE, 32'h8000_0003, "immediate irq writes mcause");
        expect_mtvec_jump("immediate irq jumps to mtvec");
    end
endtask

task retire_waits_for_side_effect_case;
    begin
        $display("\n[TEST] irq waits until older side effect is drained");
        reset_case();
        pulse_irq();
        hold_flag_i = 1'b1;
        next_pc_i = 32'h8000_5000;
        inst_retire_i = 1'b0;
        cycle();
        expect_no_trap_cycles(4, "older side effect should not enter trap");
        hold_flag_i = 1'b0;
        retire_seq(32'h8000_5000);
        expect_csr(`CSR_MEPC, 32'h8000_5000, "drained jump writes mepc");
        expect_csr(`CSR_MSTATUS, 32'h0000_1880, "drained jump writes mstatus");
        expect_csr(`CSR_MCAUSE, 32'h8000_0003, "drained jump writes mcause");
        expect_mtvec_jump("drained jump jumps to mtvec");
    end
endtask

task show_summary;
    begin
        $display("\n");
        $display("========================================================");
        $display("CLINT TEST SUMMARY");
        $display("Total : %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("========================================================");
    end
endtask

initial begin
    clk_i = 1'b0;
    test_count = 0;
    pass_count = 0;
    fail_count = 0;

    $display("[TEST] reset idle outputs");
    reset_case();
    check_eq1("idle has no CSR write", csr_waddr_vld_o, 1'b0);
    check_eq1("idle has no hold request", hold_flag_o, 1'b0);
    check_eq1("idle has no jump", jump_flag_o, 1'b0);

    $display("\n[TEST] interrupt waits for precise retire and saves next PC");
    reset_case();
    pulse_irq();
    expect_no_csr_for(5, "interrupt should not write CSR before retire boundary");
    check_eq1("idle CLINT must not hold pipe before trap entry", hold_flag_o, 1'b0);
    retire_seq(32'h8000_0104);
    expect_csr(`CSR_MEPC, 32'h8000_0104, "interrupt writes mepc with next_pc_i");
    expect_csr(`CSR_MSTATUS, 32'h0000_1880, "interrupt writes mstatus");
    expect_csr(`CSR_MCAUSE, 32'h8000_0003, "interrupt writes mcause");
    expect_jump(32'h8000_017c, "interrupt jumps to mtvec");

    $display("\n[TEST] ecall exception saves current EX PC");
    reset_case();
    inst_set_i  = 1'b1;
    inst_func_i = 3'b100;
    pc_i        = 32'h8000_0208;
    expect_csr(`CSR_MEPC, 32'h8000_0200, "ecall writes mepc as pc-8");
    expect_csr(`CSR_MSTATUS, 32'h0000_1880, "ecall writes mstatus");
    expect_csr(`CSR_MCAUSE, 32'h0000_000b, "ecall writes mcause");
    expect_jump(32'h8000_017c, "ecall jumps to mtvec");

    $display("\n[TEST] ebreak exception saves current EX PC");
    reset_case();
    inst_set_i  = 1'b1;
    inst_func_i = 3'b010;
    pc_i        = 32'h8000_0308;
    expect_csr(`CSR_MEPC, 32'h8000_0300, "ebreak writes mepc as pc-8");
    expect_csr(`CSR_MSTATUS, 32'h0000_1880, "ebreak writes mstatus");
    expect_csr(`CSR_MCAUSE, 32'h0000_0003, "ebreak writes mcause");
    expect_jump(32'h8000_017c, "ebreak jumps to mtvec");

    $display("\n[TEST] mret restores mstatus and jumps to mepc");
    reset_case();
    inst_set_i     = 1'b1;
    inst_func_i    = 3'b001;
    csr_mstatus_i  = 32'h0000_1880;
    csr_mepc_i     = 32'h8000_3456;
    expect_csr(`CSR_MSTATUS, 32'h0000_1808, "mret writes restored mstatus");
    expect_jump(32'h8000_3456, "mret jumps to mepc");

    $display("\n[TEST] irq masked when mstatus.MIE is 0");
    reset_case();
    csr_mstatus_i = 32'h0000_1880;
    pulse_irq();
    retire_seq(32'h8000_6000);
    expect_no_trap_cycles(8, "masked interrupt should not enter trap");

    pending_until_retire_case("irq during ALU/add waits for later precise retire",
                              32'h8000_1100);
    pending_until_retire_case("irq during load/store busy waits for later precise retire",
                              32'h8000_1300);
    pending_until_retire_case("irq during multicycle div/rem busy waits for later precise retire",
                              32'h8000_1400);
    pending_until_retire_case("irq during branch-not-taken waits for later precise retire",
                              32'h8000_1500);

    immediate_retire_case("irq then sequential retire saves next PC", 32'h8000_1804, 1'b0);
    immediate_retire_case("irq then branch-taken saves target PC", 32'h8000_2000, 1'b1);
    immediate_retire_case("irq then jal saves target PC", 32'h8000_3000, 1'b1);
    immediate_retire_case("irq then jalr saves target PC", 32'h8000_4000, 1'b1);
    retire_waits_for_side_effect_case();

    show_summary();
    if (fail_count == 0) begin
        $display("[PASS] clint_tb");
        $finish;
    end
    else begin
        $display("[FAIL] clint_tb errors=%0d", fail_count);
        $fatal(1);
    end
end

endmodule
