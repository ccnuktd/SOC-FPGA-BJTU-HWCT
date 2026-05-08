`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

module pa_perips_timer (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    input  wire [7:0]                   addr_i,
    input  wire                         data_rd_i,
    input  wire                         data_we_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   data_i,
    output wire [`DATA_BUS_WIDTH-1:0]   data_o,

    output wire                         irq_o
);

// TODO: Lab 2 - implement timer registers, prescaler, counter, and IRQ flag.

assign data_o = `ZERO_WORD;
assign irq_o  = `INVALID;

endmodule
