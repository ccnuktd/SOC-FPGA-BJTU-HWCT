`timescale 1ns/1ps
`define TESTBENCH_VCS
`include "../rtl/pa_chip_param.v"

module pa_core_clint_tb;

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

integer                     errors;

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

task cycle;
begin
    @(negedge clk_i);
end
endtask

task fail;
    input [1023:0] label;
begin
    errors = errors + 1;
    $display("[FAIL] %0t %0s", $time, label);
    $display("       inst_set=%b inst_func=%b pc=%h irq=%b mie=%b retire=%b next_pc=%h",
             inst_set_i, inst_func_i, pc_i, irq_i, csr_mstatus_i[3],
             inst_retire_i, next_pc_i);
    $display("       csr_vld=%b csr_addr=%h csr_data=%h hold=%b jump=%b jump_addr=%h",
             csr_waddr_vld_o, csr_waddr_o, csr_wdata_o,
             hold_flag_o, jump_flag_o, jump_addr_o);
end
endtask

task check1;
    input [1023:0] label;
    input got;
    input exp;
begin
    if (got !== exp) fail(label);
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

task expect_no_trap;
    input integer cycles;
    input [1023:0] label;
    integer i;
begin
    for (i = 0; i < cycles; i = i + 1) begin
        cycle();
        if (csr_waddr_vld_o || hold_flag_o || jump_flag_o) fail(label);
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
    for (i = 0; i < 12; i = i + 1) begin
        if (csr_waddr_vld_o) begin
            found = 1'b1;
            if (csr_waddr_o !== exp_addr || csr_wdata_o !== exp_data || hold_flag_o !== 1'b1) begin
                $display("       got addr=%h data=%h hold=%b exp addr=%h data=%h hold=1",
                         csr_waddr_o, csr_wdata_o, hold_flag_o, exp_addr, exp_data);
                fail(label);
            end
            i = 12;
        end
        else begin
            cycle();
        end
    end
    if (!found) fail({label, " not observed"});
    cycle();
end
endtask

task expect_jump;
    input [`DATA_BUS_WIDTH-1:0] exp_addr;
    input [1023:0] label;
    integer i;
    reg found;
begin
    found = 1'b0;
    for (i = 0; i < 12; i = i + 1) begin
        if (jump_flag_o) begin
            found = 1'b1;
            if (jump_addr_o !== exp_addr) fail(label);
            i = 12;
        end
        else begin
            cycle();
        end
    end
    if (!found) fail({label, " not observed"});
    cycle();
end
endtask

task pulse_irq;
begin
    irq_i = 1'b1;
    cycle();
    irq_i = 1'b0;
end
endtask

task retire_next;
    input [`ADDR_BUS_WIDTH-1:0] next_pc;
begin
    next_pc_i     = next_pc;
    inst_retire_i = 1'b1;
    cycle();
    inst_retire_i = 1'b0;
end
endtask

task expect_trap_entry;
    input [`DATA_BUS_WIDTH-1:0] exp_mepc;
    input [`DATA_BUS_WIDTH-1:0] exp_mcause;
    input [1023:0] label;
begin
    expect_csr(`CSR_MEPC, exp_mepc, {label, " mepc"});
    expect_csr(`CSR_MSTATUS, 32'h0000_1880, {label, " mstatus"});
    expect_csr(`CSR_MCAUSE, exp_mcause, {label, " mcause"});
    expect_jump(csr_mtvec_i, {label, " mtvec"});
end
endtask

initial begin
    clk_i = 1'b0;
    errors = 0;

    $display("[TEST] reset idle outputs");
    reset_case();
    check1("idle csr_waddr_vld_o", csr_waddr_vld_o, 1'b0);
    check1("idle hold_flag_o", hold_flag_o, 1'b0);
    check1("idle jump_flag_o", jump_flag_o, 1'b0);

    $display("[TEST] external interrupt waits for retire");
    reset_case();
    pulse_irq();
    expect_no_trap(3, "irq should wait for retire");
    retire_next(32'h8000_0104);
    expect_trap_entry(32'h8000_0104, 32'h8000_0003, "irq");

    $display("[TEST] ecall exception");
    reset_case();
    inst_set_i  = 1'b1;
    inst_func_i = 3'b100;
    pc_i        = 32'h8000_0208;
    expect_trap_entry(32'h8000_0200, 32'h0000_000b, "ecall");

    $display("[TEST] ebreak exception");
    reset_case();
    inst_set_i  = 1'b1;
    inst_func_i = 3'b010;
    pc_i        = 32'h8000_0308;
    expect_trap_entry(32'h8000_0300, 32'h0000_0003, "ebreak");

    $display("[TEST] mret return");
    reset_case();
    inst_set_i    = 1'b1;
    inst_func_i   = 3'b001;
    csr_mstatus_i = 32'h0000_1880;
    csr_mepc_i    = 32'h8000_3456;
    expect_csr(`CSR_MSTATUS, 32'h0000_1808, "mret mstatus");
    expect_jump(32'h8000_3456, "mret mepc");

    $display("[TEST] masked interrupt");
    reset_case();
    csr_mstatus_i = 32'h0000_1880;
    pulse_irq();
    retire_next(32'h8000_0600);
    expect_no_trap(6, "MIE=0 masks irq");

    if (errors == 0) begin
        $display("[PASS] pa_core_clint_tb");
        $finish;
    end
    else begin
        $display("[FAIL] pa_core_clint_tb errors=%0d", errors);
        $fatal(1);
    end
end

endmodule
