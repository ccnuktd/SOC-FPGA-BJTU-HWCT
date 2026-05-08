`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

module pa_core_csr (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    output wire [`DATA_BUS_WIDTH-1:0]   csr_mtvec_o,
    output wire [`DATA_BUS_WIDTH-1:0]   csr_mepc_o,
    output wire [`DATA_BUS_WIDTH-1:0]   csr_mstatus_o,

    input  wire [`CSR_BUS_WIDTH-1:0]    csr_raddr_i,

    input  wire [`CSR_BUS_WIDTH-1:0]    csr_waddr_i,
    input  wire                         csr_waddr_vld_i,

    input  wire [`DATA_BUS_WIDTH-1:0]   csr_wdata_i,

    output wire [`DATA_BUS_WIDTH-1:0]   csr_rdata_o
);

// TODO: Lab 1 - implement CSR registers and read/write behavior.

assign csr_mtvec_o   = `ZERO_WORD;
assign csr_mepc_o    = `ZERO_WORD;
assign csr_mstatus_o = `ZERO_WORD;
assign csr_rdata_o   = `ZERO_WORD;

endmodule
