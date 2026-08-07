`timescale 1ns/1ps
`define TESTBENCH_VCS
`include "pa_chip_param.v"

module csr_tb;

reg                         clk_i;
reg                         rst_n_i;
wire [`DATA_BUS_WIDTH-1:0]  csr_mtvec_o;
wire [`DATA_BUS_WIDTH-1:0]  csr_mepc_o;
wire [`DATA_BUS_WIDTH-1:0]  csr_mstatus_o;
reg  [`CSR_BUS_WIDTH-1:0]   csr_raddr_i;
reg  [`CSR_BUS_WIDTH-1:0]   csr_waddr_i;
reg                         csr_waddr_vld_i;
reg  [`DATA_BUS_WIDTH-1:0]  csr_wdata_i;
wire [`DATA_BUS_WIDTH-1:0]  csr_rdata_o;

integer tests;
integer failures;
integer i;

reg [11:0] csr_addr [0:8];
reg [31:0] csr_value[0:8];

pa_core_csr dut (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),
    .csr_mtvec_o(csr_mtvec_o),
    .csr_mepc_o(csr_mepc_o),
    .csr_mstatus_o(csr_mstatus_o),
    .csr_raddr_i(csr_raddr_i),
    .csr_waddr_i(csr_waddr_i),
    .csr_waddr_vld_i(csr_waddr_vld_i),
    .csr_wdata_i(csr_wdata_i),
    .csr_rdata_o(csr_rdata_o)
);

always #5 clk_i = ~clk_i;

initial begin
    $dumpfile("csr.vcd");
    $dumpvars(0, csr_tb);
end

task check32;
    input [1023:0] name;
    input [31:0] expected;
    input [31:0] actual;
begin
    tests = tests + 1;
    if (actual !== expected) begin
        failures = failures + 1;
        $display("[FAIL] %0s expected=%08h actual=%08h time=%0t", name, expected, actual, $time);
        $display("       raddr=%08h waddr=%08h we=%b wdata=%08h", csr_raddr_i, csr_waddr_i,
                 csr_waddr_vld_i, csr_wdata_i);
    end
end
endtask

task idle_bus;
begin
    csr_waddr_vld_i = 1'b0;
    csr_waddr_i     = `ZERO_WORD;
    csr_wdata_i     = `ZERO_WORD;
end
endtask

task reset_dut;
begin
    @(negedge clk_i);
    rst_n_i = 1'b0;
    idle_bus();
    csr_raddr_i = `CSR_MSTATUS;
    #1;
    check32("asynchronous reset immediately restores mstatus", 32'h0000_1880, csr_mstatus_o);
    repeat (2) @(posedge clk_i);
    @(negedge clk_i);
    rst_n_i = 1'b1;
end
endtask

task read_now;
    input [31:0] addr;
    input [31:0] expected;
    input [1023:0] name;
begin
    csr_raddr_i = addr;
    #1;
    check32(name, expected, csr_rdata_o);
end
endtask

task write_csr;
    input [31:0] addr;
    input [31:0] data;
begin
    @(negedge clk_i);
    csr_waddr_i     = addr;
    csr_wdata_i     = data;
    csr_waddr_vld_i = 1'b1;
    @(posedge clk_i);
    #1;
    @(negedge clk_i);
    idle_bus();
end
endtask

initial begin
    clk_i = 1'b0;
    rst_n_i = 1'b1;
    csr_raddr_i = `ZERO_WORD;
    csr_waddr_i = `ZERO_WORD;
    csr_waddr_vld_i = 1'b0;
    csr_wdata_i = `ZERO_WORD;
    tests = 0;
    failures = 0;

    csr_addr[0] = `CSR_MTVEC;
    csr_addr[1] = `CSR_MEPC;
    csr_addr[2] = `CSR_MCAUSE;
    csr_addr[3] = `CSR_MIE;
    csr_addr[4] = `CSR_MIP;
    csr_addr[5] = `CSR_MTVAL;
    csr_addr[6] = `CSR_MSCRATCH;
    csr_addr[7] = `CSR_MSCRATCHCSWL;
    csr_addr[8] = `CSR_MSTATUS;

    csr_value[0] = 32'h0123_4567;
    csr_value[1] = 32'h89ab_cdef;
    csr_value[2] = 32'h8000_0003;
    csr_value[3] = 32'h1357_9bdf;
    csr_value[4] = 32'h2468_ace0;
    csr_value[5] = 32'hdead_beef;
    csr_value[6] = 32'h55aa_aa55;
    csr_value[7] = 32'hc001_c0de;
    csr_value[8] = 32'h0000_1888;

    $display("[TEST] CSR asynchronous reset and exact cycle timing");
    reset_dut();
    read_now(`CSR_CYCLE, 32'h0, "cycle is zero before first released edge");
    @(posedge clk_i); #1;
    check32("cycle increments on first released edge", 32'h1, csr_rdata_o);
    @(posedge clk_i); #1;
    check32("cycle increments on every edge", 32'h2, csr_rdata_o);
    write_csr(`CSR_CYCLE, 32'hffff_ffff);
    read_now(`CSR_CYCLE, 32'h3, "cycle is read-only and still increments normally");
    csr_raddr_i = `CSR_CYCLEH; #1;
    check32("cycleh remains zero without overflow", 32'h0, csr_rdata_o);

    reset_dut();
    read_now(`CSR_MTVEC, 32'h0, "mtvec reset value");
    read_now(`CSR_MEPC, 32'h0, "mepc reset value");
    read_now(`CSR_MCAUSE, 32'h0, "mcause reset value");
    read_now(`CSR_MIE, 32'h0, "mie reset value");
    read_now(`CSR_MIP, 32'h0, "mip reset value");
    read_now(`CSR_MTVAL, 32'h0, "mtval reset value");
    read_now(`CSR_MSCRATCH, 32'h0, "mscratch reset value");
    read_now(`CSR_MSTATUS, 32'h0000_1880, "mstatus reset value");
    check32("mstatus direct output reset value", 32'h0000_1880, csr_mstatus_o);

    $display("[TEST] all writable CSRs, direct outputs, and register isolation");
    reset_dut();
    for (i = 0; i < 9; i = i + 1) begin
        write_csr({20'ha5a5a, csr_addr[i]}, csr_value[i]);
    end
    for (i = 0; i < 9; i = i + 1) begin
        read_now({20'h5a5a5, csr_addr[i]}, csr_value[i], "CSR retains its own distinct value");
    end
    check32("mtvec direct output", csr_value[0], csr_mtvec_o);
    check32("mepc direct output", csr_value[1], csr_mepc_o);
    check32("mstatus direct output", csr_value[8], csr_mstatus_o);

    $display("[TEST] write enable, unknown address, and same-cycle visibility");
    reset_dut();
    write_csr(`CSR_MTVEC, 32'h1111_2222);
    @(negedge clk_i);
    csr_raddr_i     = `CSR_MTVEC;
    csr_waddr_i     = `CSR_MTVEC;
    csr_wdata_i     = 32'h3333_4444;
    csr_waddr_vld_i = 1'b0;
    #1;
    check32("disabled write does not change read data before edge", 32'h1111_2222, csr_rdata_o);
    @(posedge clk_i); #1;
    check32("disabled write does not change register", 32'h1111_2222, csr_rdata_o);

    @(negedge clk_i);
    csr_waddr_vld_i = 1'b1;
    csr_wdata_i     = 32'h5555_6666;
    #1;
    check32("write is not visible before active edge", 32'h1111_2222, csr_rdata_o);
    @(posedge clk_i); #1;
    check32("write becomes visible immediately after active edge", 32'h5555_6666, csr_rdata_o);

    @(negedge clk_i);
    csr_waddr_i     = 32'h0000_0fff;
    csr_wdata_i     = 32'hffff_ffff;
    csr_waddr_vld_i = 1'b1;
    @(posedge clk_i); #1;
    idle_bus();
    read_now(`CSR_MTVEC, 32'h5555_6666, "unknown write does not corrupt mtvec");
    read_now(32'h0000_0fff, 32'h0, "unknown CSR reads zero");

    $display("[TEST] read mux is combinational, not one cycle late");
    csr_raddr_i = `CSR_MTVEC; #1;
    check32("combinational read mtvec", 32'h5555_6666, csr_rdata_o);
    csr_raddr_i = `CSR_MSTATUS; #1;
    check32("combinational read changes within same cycle", 32'h0000_1880, csr_rdata_o);
    csr_raddr_i = `CSR_MEPC; #1;
    check32("combinational read changes again without clock", 32'h0, csr_rdata_o);

    $display("\n========================================================");
    $display("CSR STRICT TEST SUMMARY: total=%0d failed=%0d", tests, failures);
    $display("========================================================");
    if (failures != 0) $fatal(1, "csr_tb failed");
    $display("[PASS] csr_tb");
    $finish;
end

endmodule
