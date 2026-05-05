`include "../rtl/pa_chip_param.v"

module pa_core_clint_tb;

reg                             clk;
reg                             rst_n;

reg                             inst_set_i;
reg  [2:0]                      inst_func_i;
reg  [`ADDR_BUS_WIDTH-1:0]      pc_i;
reg  [`DATA_BUS_WIDTH-1:0]      inst_i;
reg  [`DATA_BUS_WIDTH-1:0]      csr_mtvec_i;
reg  [`DATA_BUS_WIDTH-1:0]      csr_mepc_i;
reg  [`DATA_BUS_WIDTH-1:0]      csr_mstatus_i;
reg                             irq_i;
reg                             jump_flag_i;
reg                             hold_flag_i;

wire [`CSR_BUS_WIDTH-1:0]       csr_waddr_o;
wire                            csr_waddr_vld_o;
wire [`DATA_BUS_WIDTH-1:0]      csr_wdata_o;
wire                            hold_flag_o;
wire                            jump_flag_o;
wire [`DATA_BUS_WIDTH-1:0]      jump_addr_o;

integer                         failures;

pa_core_clint dut (
    .clk_i                      (clk),
    .rst_n_i                    (rst_n),
    .inst_set_i                 (inst_set_i),
    .inst_func_i                (inst_func_i),
    .pc_i                       (pc_i),
    .inst_i                     (inst_i),
    .csr_mtvec_i                (csr_mtvec_i),
    .csr_mepc_i                 (csr_mepc_i),
    .csr_mstatus_i              (csr_mstatus_i),
    .irq_i                      (irq_i),
    .jump_flag_i                (jump_flag_i),
    .hold_flag_i                (hold_flag_i),
    .csr_waddr_o                (csr_waddr_o),
    .csr_waddr_vld_o            (csr_waddr_vld_o),
    .csr_wdata_o                (csr_wdata_o),
    .hold_flag_o                (hold_flag_o),
    .jump_flag_o                (jump_flag_o),
    .jump_addr_o                (jump_addr_o)
);

always #5 clk = ~clk;

task update_csr_model;
begin
    if (csr_waddr_vld_o) begin
        case (csr_waddr_o)
            `CSR_MEPC    : csr_mepc_i    = csr_wdata_o;
            `CSR_MSTATUS : csr_mstatus_i = csr_wdata_o;
            default      : begin
            end
        endcase
    end
end
endtask

task step;
begin
    @(posedge clk);
    #1;
    update_csr_model();
end
endtask

task expect_signal;
    input [8*32-1:0] name;
    input [31:0] actual;
    input [31:0] expected;
begin
    if (actual !== expected) begin
        failures = failures + 1;
        $display("FAIL: %0s actual=0x%08x expect=0x%08x at t=%0t", name, actual, expected, $time);
    end
end
endtask

task expect_write;
    input [11:0] expect_addr;
    input [31:0] expect_data;
begin
    expect_signal("csr_waddr_vld", {31'b0, csr_waddr_vld_o}, 32'd1);
    expect_signal("csr_waddr", {20'b0, csr_waddr_o}, {20'b0, expect_addr});
    expect_signal("csr_wdata", csr_wdata_o, expect_data);
end
endtask

task expect_no_write;
begin
    expect_signal("csr_waddr_vld", {31'b0, csr_waddr_vld_o}, 32'd0);
end
endtask

task clear_inputs;
begin
    inst_set_i   = 1'b0;
    inst_func_i  = 3'b000;
    irq_i        = 1'b0;
    jump_flag_i  = 1'b0;
    hold_flag_i  = 1'b0;
end
endtask

initial begin
    clk           = 1'b0;
    rst_n         = 1'b0;
    failures      = 0;
    inst_set_i    = 1'b0;
    inst_func_i   = 3'b000;
    pc_i          = 32'h8000_0000;
    inst_i        = 32'h0000_0000;
    csr_mtvec_i   = 32'h8000_0100;
    csr_mepc_i    = 32'h0000_0000;
    csr_mstatus_i = 32'h0000_0008;
    irq_i         = 1'b0;
    jump_flag_i   = 1'b0;
    hold_flag_i   = 1'b0;

    step();
    step();
    rst_n = 1'b1;
    step();
    expect_no_write();

    // Scenario 1: synchronous ecall should save pc-8 and cause 11.
    clear_inputs();
    pc_i        = 32'h8000_0010;
    inst_set_i  = 1'b1;
    inst_func_i = 3'b100;
    step();
    expect_write(`CSR_MEPC, 32'h8000_0008);
    step();
    expect_write(`CSR_MSTATUS, 32'h0000_0080);
    step();
    expect_write(`CSR_MCAUSE, 32'd11);
    step();
    expect_signal("jump_flag", {31'b0, jump_flag_o}, 32'd1);
    expect_signal("jump_addr", jump_addr_o, 32'h8000_0100);
    clear_inputs();
    step();
    expect_no_write();

    // Scenario 2: asynchronous interrupt without hold should save pc-4 and jump to mtvec.
    csr_mstatus_i = 32'h0000_0008;
    pc_i          = 32'h8000_0030;
    irq_i         = 1'b1;
    step();
    expect_no_write();
    expect_signal("hold_flag", {31'b0, hold_flag_o}, 32'd0);
    irq_i = 1'b0;
    step();
    expect_write(`CSR_MEPC, 32'h8000_002c);
    step();
    expect_write(`CSR_MSTATUS, 32'h0000_0080);
    step();
    expect_write(`CSR_MCAUSE, 32'h8000_0003);
    step();
    expect_signal("jump_flag", {31'b0, jump_flag_o}, 32'd1);
    expect_signal("jump_addr", jump_addr_o, 32'h8000_0100);
    step();
    expect_no_write();

    // Scenario 3: interrupt accepted while EXU is holding; later pc changes must not corrupt mepc.
    csr_mstatus_i = 32'h0000_0008;
    pc_i          = 32'h8000_0100;
    hold_flag_i   = 1'b1;
    irq_i         = 1'b1;
    step();
    expect_no_write();
    irq_i = 1'b0;
    step();
    expect_no_write();
    expect_signal("hold_flag", {31'b0, hold_flag_o}, 32'd1);
    pc_i  = 32'h8000_0200;
    step();
    expect_no_write();
    pc_i        = 32'h8000_0300;
    hold_flag_i = 1'b0;
    step();
    expect_write(`CSR_MEPC, 32'h8000_00fc);
    step();
    expect_write(`CSR_MSTATUS, 32'h0000_0080);
    step();
    expect_write(`CSR_MCAUSE, 32'h8000_0003);
    step();
    expect_signal("jump_flag", {31'b0, jump_flag_o}, 32'd1);
    expect_signal("jump_addr", jump_addr_o, 32'h8000_0100);

    // Scenario 4: exception must win over simultaneous interrupt.
    clear_inputs();
    csr_mstatus_i = 32'h0000_0008;
    pc_i          = 32'h8000_0400;
    inst_set_i    = 1'b1;
    inst_func_i   = 3'b100;
    irq_i         = 1'b1;
    step();
    expect_write(`CSR_MEPC, 32'h8000_03f8);
    step();
    expect_write(`CSR_MSTATUS, 32'h0000_0080);
    step();
    expect_write(`CSR_MCAUSE, 32'd11);
    irq_i = 1'b0;
    step();
    expect_signal("jump_flag", {31'b0, jump_flag_o}, 32'd1);
    clear_inputs();
    step();

    // Scenario 5: mret should jump back to mepc and restore MIE from MPIE.
    csr_mepc_i    = 32'h8000_0555;
    csr_mstatus_i = 32'h0000_0080;
    inst_set_i    = 1'b1;
    inst_func_i   = 3'b001;
    step();
    expect_write(`CSR_MSTATUS, 32'h0000_0008);
    step();
    expect_signal("jump_flag", {31'b0, jump_flag_o}, 32'd1);
    expect_signal("jump_addr", jump_addr_o, 32'h8000_0555);
    clear_inputs();
    step();

    if (failures == 0) begin
        $display("PASS: pa_core_clint trap sequencing checks passed.");
    end
    else begin
        $display("FAIL: pa_core_clint trap sequencing checks failed. failures=%0d", failures);
        $fatal(1);
    end

    $finish;
end

endmodule
