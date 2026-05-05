/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date             Author      Notes
 * 2021-10-29       Lyons       first version
 * 2022-04-04       Lyons       v2.0
 * 2023-06-13       Lyons       v3.0, add comments
 * 2024-04-25       Migration   Replace IP core with simple multiplication
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

module pa_core_exu_mul (
    input                               clk,
    input                               rst_n,
    input  wire [`DATA_BUS_WIDTH-1:0]   data1_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   data2_i,
    input wire                          valid_i,
    input wire [`REG_BUS_WIDTH-1:0]    waddr_i,
    input  wire                         sign_i,
    output wire                         hold_o,
    output wire [63:0]                  data_o,
    output wire [`REG_BUS_WIDTH-1:0]    waddr_o,
    output wire                         valid_o
);

// Buffer inputs when valid
reg [31:0]                             data1_buf;
reg [31:0]                             data2_buf;
reg [`REG_BUS_WIDTH-1:0]              waddr_buf;

assign waddr_o = waddr_buf;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data1_buf <= 32'b0;
        data2_buf <= 32'b0;
        waddr_buf <= `ZERO_WORD;
    end else if (valid_i) begin
        data1_buf <= data1_i;
        data2_buf <= data2_i;
        waddr_buf <= waddr_i;
    end
end

// Simple multiplication using Verilog operators
// Signed multiplication for signed_out
wire signed [31:0] signed_a;
wire signed [31:0] signed_b;
assign signed_a = data1_buf;
assign signed_b = data2_buf;

wire signed [63:0] signed_out;
assign signed_out = signed_a * signed_b;

// Unsigned multiplication for unsigned_out
wire [63:0] unsigned_out;
assign unsigned_out = data1_buf * data2_buf;

// Select output based on sign flag
assign data_o[63:0] = sign_i ? signed_out[63:0] : unsigned_out[63:0];

// Pipeline for multiplication result (2-cycle latency to match original IP)
reg [7:0] valid_pipe;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_pipe <= 8'b0;
    end else begin
        valid_pipe <= {valid_pipe[6:0], valid_i};
    end
end

assign valid_o = valid_pipe[1];      // 2-cycle latency
assign hold_o  = |valid_pipe[1:0];   // pipeline has operation not complete

endmodule
