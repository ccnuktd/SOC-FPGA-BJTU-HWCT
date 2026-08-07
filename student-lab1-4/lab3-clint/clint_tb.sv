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

integer tests;
integer failures;
integer i;
reg [31:0] expected_mstatus;

pa_core_clint dut (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),
    .inst_set_i(inst_set_i),
    .inst_func_i(inst_func_i),
    .pc_i(pc_i),
    .inst_i(inst_i),
    .csr_mtvec_i(csr_mtvec_i),
    .csr_mepc_i(csr_mepc_i),
    .csr_mstatus_i(csr_mstatus_i),
    .irq_i(irq_i),
    .jump_flag_i(jump_flag_i),
    .jump_addr_i(jump_addr_i),
    .hold_flag_i(hold_flag_i),
    .next_pc_i(next_pc_i),
    .inst_retire_i(inst_retire_i),
    .csr_waddr_o(csr_waddr_o),
    .csr_waddr_vld_o(csr_waddr_vld_o),
    .csr_wdata_o(csr_wdata_o),
    .hold_flag_o(hold_flag_o),
    .jump_flag_o(jump_flag_o),
    .jump_addr_o(jump_addr_o)
);

always #5 clk_i = ~clk_i;

initial begin
    $dumpfile("clint.vcd");
    $dumpvars(0, clint_tb);
end

task check1;
    input [1023:0] name;
    input expected;
    input actual;
begin
    tests = tests + 1;
    if (actual !== expected) begin
        failures = failures + 1;
        $display("[FAIL] %0s expected=%b actual=%b time=%0t", name, expected, actual, $time);
    end
end
endtask

task check32;
    input [1023:0] name;
    input [31:0] expected;
    input [31:0] actual;
begin
    tests = tests + 1;
    if (actual !== expected) begin
        failures = failures + 1;
        $display("[FAIL] %0s expected=%08h actual=%08h time=%0t", name, expected, actual, $time);
    end
end
endtask

task dump_context;
begin
    if (failures != 0) begin
        $display("       func=%b pc=%08h irq=%b retire=%b hold_i=%b jump_i=%b next_pc=%08h",
                 inst_func_i, pc_i, irq_i, inst_retire_i, hold_flag_i, jump_flag_i, next_pc_i);
        $display("       csr_vld=%b csr_addr=%08h csr_data=%08h hold_o=%b jump_o=%b jump_addr=%08h",
                 csr_waddr_vld_o, csr_waddr_o, csr_wdata_o, hold_flag_o,
                 jump_flag_o, jump_addr_o);
    end
end
endtask

task check_phase;
    input [1023:0] name;
    input expected_csr_vld;
    input [31:0] expected_csr_addr;
    input [31:0] expected_csr_data;
    input expected_hold;
    input expected_jump;
    input [31:0] expected_jump_addr;
    integer failures_before;
begin
    failures_before = failures;
    check1({name, " csr valid"}, expected_csr_vld, csr_waddr_vld_o);
    check1({name, " hold"}, expected_hold, hold_flag_o);
    check1({name, " jump"}, expected_jump, jump_flag_o);
    if (expected_csr_vld) begin
        check32({name, " csr address"}, expected_csr_addr, csr_waddr_o);
        check32({name, " csr data"}, expected_csr_data, csr_wdata_o);
    end
    else begin
        check32({name, " idle csr address"}, 32'h0, csr_waddr_o);
        check32({name, " idle csr data"}, 32'h0, csr_wdata_o);
    end
    if (expected_jump)
        check32({name, " jump address"}, expected_jump_addr, jump_addr_o);
    else
        check32({name, " idle jump address"}, 32'h0, jump_addr_o);
    if (failures != failures_before) dump_context();
end
endtask

task clear_events;
begin
    inst_set_i    = 1'b0;
    inst_func_i   = 3'b000;
    irq_i         = 1'b0;
    jump_flag_i   = 1'b0;
    hold_flag_i   = 1'b0;
    inst_retire_i = 1'b0;
end
endtask

task reset_dut;
begin
    @(negedge clk_i);
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
    repeat (3) @(negedge clk_i);
    #1;
    check_phase("asynchronous reset", 1'b0, 0, 0, 1'b0, 1'b0, 0);
    rst_n_i = 1'b1;
    @(posedge clk_i); #1;
    check_phase("first idle cycle after reset", 1'b0, 0, 0, 1'b0, 1'b0, 0);
end
endtask

task expect_trap_sequence;
    input [31:0] expected_mepc;
    input [31:0] expected_cause;
    input [31:0] status_before;
    input [1023:0] name;
    reg [31:0] trap_status;
begin
    trap_status = {status_before[31:8], status_before[3], status_before[6:4],
                   1'b0, status_before[2:0]};
    #1;
    check_phase({name, " before capture"}, 1'b0, 0, 0, 1'b0, 1'b0, 0);
    @(posedge clk_i); #1;
    check_phase({name, " MEPC cycle"}, 1'b1, `CSR_MEPC, expected_mepc, 1'b1, 1'b0, 0);
    @(negedge clk_i);
    clear_events();
    @(posedge clk_i); #1;
    check_phase({name, " MSTATUS cycle"}, 1'b1, `CSR_MSTATUS, trap_status, 1'b1, 1'b0, 0);
    @(posedge clk_i); #1;
    check_phase({name, " MCAUSE cycle"}, 1'b1, `CSR_MCAUSE, expected_cause, 1'b1, 1'b0, 0);
    @(posedge clk_i); #1;
    check_phase({name, " redirect cycle"}, 1'b0, 0, 0, 1'b0, 1'b1, csr_mtvec_i);
    @(posedge clk_i); #1;
    check_phase({name, " post redirect idle"}, 1'b0, 0, 0, 1'b0, 1'b0, 0);
end
endtask

task expect_mret_sequence;
    input [31:0] status_before;
    input [31:0] expected_pc;
    input [1023:0] name;
    reg [31:0] return_status;
begin
    return_status = {status_before[31:8], 1'b0, status_before[6:4],
                     status_before[7], status_before[2:0]};
    #1;
    check_phase({name, " before capture"}, 1'b0, 0, 0, 1'b0, 1'b0, 0);
    @(posedge clk_i); #1;
    check_phase({name, " MRET CSR cycle"}, 1'b1, `CSR_MSTATUS, return_status, 1'b1, 1'b0, 0);
    @(negedge clk_i);
    clear_events();
    @(posedge clk_i); #1;
    check_phase({name, " return redirect"}, 1'b0, 0, 0, 1'b0, 1'b1, expected_pc);
    @(posedge clk_i); #1;
    check_phase({name, " post return idle"}, 1'b0, 0, 0, 1'b0, 1'b0, 0);
end
endtask

task pulse_irq_one_cycle;
begin
    @(negedge clk_i);
    irq_i = 1'b1;
    @(posedge clk_i); #1;
    @(negedge clk_i);
    irq_i = 1'b0;
    @(posedge clk_i); #1;
end
endtask

initial begin
    clk_i = 1'b0;
    rst_n_i = 1'b1;
    tests = 0;
    failures = 0;
    clear_events();
    pc_i = 0;
    inst_i = `INST_DATA_NOP;
    csr_mtvec_i = 0;
    csr_mepc_i = 0;
    csr_mstatus_i = 0;
    jump_addr_i = 0;
    next_pc_i = 0;

    $display("[TEST] ECALL/EBREAK decode, exact CSR order, and PC-8 semantics");
    reset_dut();
    @(negedge clk_i);
    inst_set_i = 1'b1;
    inst_func_i = 3'b100;
    pc_i = 32'h8000_0208;
    csr_mstatus_i = 32'ha5a5_5a5b;
    expect_trap_sequence(32'h8000_0200, 32'h0000_000b, csr_mstatus_i, "ecall");

    reset_dut();
    @(negedge clk_i);
    inst_set_i = 1'b1;
    inst_func_i = 3'b010;
    pc_i = 32'h0000_0004;
    csr_mstatus_i = 32'h1234_56f7;
    expect_trap_sequence(32'hffff_fffc, 32'h0000_0003, csr_mstatus_i, "ebreak wraparound");

    $display("[TEST] instruction-set enable and exception conflict gates");
    reset_dut();
    @(negedge clk_i);
    inst_set_i = 1'b0;
    inst_func_i = 3'b110;
    repeat (3) begin
        @(posedge clk_i); #1;
        check_phase("inst_set=0 blocks exception decode", 1'b0, 0, 0, 1'b0, 1'b0, 0);
    end
    @(negedge clk_i);
    inst_set_i = 1'b1;
    inst_func_i = 3'b100;
    hold_flag_i = 1'b1;
    repeat (2) begin
        @(posedge clk_i); #1;
        check_phase("hold conflict blocks ecall", 1'b0, 0, 0, 1'b0, 1'b0, 0);
    end
    @(negedge clk_i);
    hold_flag_i = 1'b0;
    jump_flag_i = 1'b1;
    @(posedge clk_i); #1;
    check_phase("jump conflict blocks ecall", 1'b0, 0, 0, 1'b0, 1'b0, 0);
    @(negedge clk_i);
    jump_flag_i = 1'b0;
    pc_i = 32'h9000_0108;
    expect_trap_sequence(32'h9000_0100, 32'h0000_000b, csr_mstatus_i, "ecall after conflicts clear");

    $display("[TEST] IRQ edge capture, pending retention, retire boundary, and next_pc");
    reset_dut();
    @(negedge clk_i);
    irq_i = 1'b1;
    inst_retire_i = 1'b1;
    next_pc_i = 32'h8000_7774;
    @(posedge clk_i); #1;
    check_phase("first IRQ synchronizer sample cannot trap early", 1'b0, 0, 0, 1'b0, 1'b0, 0);
    @(negedge clk_i);
    irq_i = 1'b0;
    expect_trap_sequence(32'h8000_7774, 32'h8000_0003, csr_mstatus_i,
                         "IRQ exact synchronizer latency");

    reset_dut();
    pulse_irq_one_cycle();
    repeat (4) begin
        @(posedge clk_i); #1;
        check_phase("pending IRQ waits without retire", 1'b0, 0, 0, 1'b0, 1'b0, 0);
    end
    @(negedge clk_i);
    next_pc_i = 32'h0000_0000;
    inst_retire_i = 1'b1;
    expect_trap_sequence(32'h0000_0000, 32'h8000_0003, csr_mstatus_i, "IRQ accepts zero next_pc exactly");

    reset_dut();
    pulse_irq_one_cycle();
    repeat (7) begin
        @(posedge clk_i); #1;
        check_phase("long pending IRQ remains idle", 1'b0, 0, 0, 1'b0, 1'b0, 0);
    end
    @(negedge clk_i);
    next_pc_i = 32'h8123_4567;
    inst_retire_i = 1'b1;
    expect_trap_sequence(32'h8123_4567, 32'h8000_0003, csr_mstatus_i, "IRQ delayed retire");

    $display("[TEST] masked IRQ is discarded rather than taken after MIE changes");
    reset_dut();
    csr_mstatus_i[3] = 1'b0;
    pulse_irq_one_cycle();
    @(negedge clk_i);
    csr_mstatus_i[3] = 1'b1;
    inst_retire_i = 1'b1;
    repeat (6) begin
        @(posedge clk_i); #1;
        check_phase("masked edge remains discarded", 1'b0, 0, 0, 1'b0, 1'b0, 0);
    end
    clear_events();

    $display("[TEST] exception and MRET priority over competing sources");
    reset_dut();
    pulse_irq_one_cycle();
    @(negedge clk_i);
    inst_set_i = 1'b1;
    inst_func_i = 3'b100;
    pc_i = 32'h8000_d008;
    inst_retire_i = 1'b1;
    next_pc_i = 32'h8000_eeee;
    expect_trap_sequence(32'h8000_d000, 32'h0000_000b, csr_mstatus_i,
                         "ecall wins over pending IRQ");

    reset_dut();
    @(negedge clk_i);
    inst_set_i = 1'b1;
    inst_func_i = 3'b101;
    csr_mepc_i = 32'h8000_d111;
    csr_mstatus_i = 32'h1357_9b80;
    expect_mret_sequence(csr_mstatus_i, csr_mepc_i,
                         "mret bit has priority over simultaneous ecall bit");

    $display("[TEST] ready MRET exact timing and status restoration patterns");
    reset_dut();
    @(negedge clk_i);
    inst_set_i = 1'b1;
    inst_func_i = 3'b001;
    csr_mstatus_i = 32'hdeaf_be87;
    csr_mepc_i = 32'h8765_4321;
    expect_mret_sequence(csr_mstatus_i, csr_mepc_i, "ready mret");

    $display("[TEST] blocked MRET is retained and holds younger instructions");
    reset_dut();
    @(negedge clk_i);
    inst_set_i = 1'b1;
    inst_func_i = 3'b001;
    hold_flag_i = 1'b1;
    #1;
    check_phase("blocked mret first cycle does not hold early", 1'b0, 0, 0, 1'b0, 1'b0, 0);
    @(posedge clk_i); #1;
    check_phase("blocked mret becomes pending", 1'b0, 0, 0, 1'b1, 1'b0, 0);
    @(negedge clk_i);
    inst_set_i = 1'b0;
    inst_func_i = 3'b000;
    repeat (3) begin
        @(posedge clk_i); #1;
        check_phase("pending mret holds while older work drains", 1'b0, 0, 0, 1'b1, 1'b0, 0);
    end
    @(negedge clk_i);
    hold_flag_i = 1'b0;
    csr_mstatus_i = 32'h0bad_f080;
    csr_mepc_i = 32'h8000_abcd;
    // The pending request enters MRET on this edge.
    @(posedge clk_i); #1;
    expected_mstatus = {csr_mstatus_i[31:8], 1'b0, csr_mstatus_i[6:4],
                        csr_mstatus_i[7], csr_mstatus_i[2:0]};
    check_phase("pending mret enters only when ready", 1'b1, `CSR_MSTATUS,
                expected_mstatus, 1'b1, 1'b0, 0);
    @(posedge clk_i); #1;
    check_phase("pending mret redirects mepc", 1'b0, 0, 0, 1'b0, 1'b1, csr_mepc_i);
    @(posedge clk_i); #1;
    check_phase("pending mret returns idle", 1'b0, 0, 0, 1'b0, 1'b0, 0);

    $display("[TEST] jump conflict also defers MRET until safe");
    reset_dut();
    @(negedge clk_i);
    inst_set_i = 1'b1;
    inst_func_i = 3'b001;
    jump_flag_i = 1'b1;
    @(posedge clk_i); #1;
    check_phase("jump-blocked mret becomes pending", 1'b0, 0, 0, 1'b1, 1'b0, 0);
    @(negedge clk_i);
    inst_set_i = 1'b0;
    inst_func_i = 3'b000;
    @(posedge clk_i); #1;
    check_phase("jump-blocked mret remains pending", 1'b0, 0, 0, 1'b1, 1'b0, 0);
    @(negedge clk_i);
    jump_flag_i = 1'b0;
    @(posedge clk_i); #1;
    expected_mstatus = {csr_mstatus_i[31:8], 1'b0, csr_mstatus_i[6:4],
                        csr_mstatus_i[7], csr_mstatus_i[2:0]};
    check_phase("jump-blocked mret enters after conflict", 1'b1, `CSR_MSTATUS,
                expected_mstatus, 1'b1, 1'b0, 0);
    @(posedge clk_i); #1;
    check_phase("jump-blocked mret redirects", 1'b0, 0, 0, 1'b0, 1'b1, csr_mepc_i);
    @(posedge clk_i); #1;
    check_phase("jump-blocked mret returns idle", 1'b0, 0, 0, 1'b0, 1'b0, 0);

    $display("[TEST] IRQ cannot preempt a deferred MRET and remains pending afterward");
    reset_dut();
    @(negedge clk_i);
    inst_set_i = 1'b1;
    inst_func_i = 3'b001;
    hold_flag_i = 1'b1;
    @(posedge clk_i); #1;
    check_phase("mret pending before competing irq", 1'b0, 0, 0, 1'b1, 1'b0, 0);
    @(negedge clk_i);
    inst_set_i = 1'b0;
    inst_func_i = 3'b000;
    irq_i = 1'b1;
    inst_retire_i = 1'b1;
    @(posedge clk_i); #1;
    check_phase("irq sample cannot bypass pending mret", 1'b0, 0, 0, 1'b1, 1'b0, 0);
    @(negedge clk_i);
    irq_i = 1'b0;
    @(posedge clk_i); #1;
    check_phase("irq edge retained while mret blocked", 1'b0, 0, 0, 1'b1, 1'b0, 0);
    @(negedge clk_i);
    hold_flag_i = 1'b0;
    inst_retire_i = 1'b0;
    @(posedge clk_i); #1;
    expected_mstatus = {csr_mstatus_i[31:8], 1'b0, csr_mstatus_i[6:4],
                        csr_mstatus_i[7], csr_mstatus_i[2:0]};
    check_phase("mret wins over retained irq", 1'b1, `CSR_MSTATUS,
                expected_mstatus, 1'b1, 1'b0, 0);
    @(posedge clk_i); #1;
    check_phase("mret redirect precedes irq", 1'b0, 0, 0, 1'b0, 1'b1, csr_mepc_i);
    @(posedge clk_i); #1;
    check_phase("retained irq still waits for retire", 1'b0, 0, 0, 1'b0, 1'b0, 0);
    @(negedge clk_i);
    next_pc_i = 32'h8000_c004;
    inst_retire_i = 1'b1;
    expect_trap_sequence(32'h8000_c004, 32'h8000_0003, csr_mstatus_i,
                         "retained irq after mret");

    $display("\n========================================================");
    $display("CLINT STRICT TEST SUMMARY: assertions=%0d failed=%0d", tests, failures);
    $display("========================================================");
    if (failures != 0) $fatal(1, "clint_tb failed");
    $display("[PASS] clint_tb");
    $finish;
end

endmodule
