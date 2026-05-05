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

wire [63:0]                             unsigned_out;
wire [63:0]                             signed_out;

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


usigned_mult_gen_0 unsigned_ipcore (
  .CLK(clk),  // input wire CLK
  .A(data1_buf),      // input wire [31 : 0] A
  .B(data2_buf),      // input wire [31 : 0] B
  .P(unsigned_out)      // output wire [63 : 0] P
);

signed_mult_gen_0 signed_ipcore (
  .CLK(clk),  // input wire CLK
  .A(data1_buf),      // input wire [31 : 0] A
  .B(data2_buf),      // input wire [31 : 0] B
  .P(signed_out)      // output wire [63 : 0] P
);

// 删除signed_ipcore实例（或忽略其输出）
assign data_o[63:0] = sign_i ? signed_out[63:0] : unsigned_out[63:0];

reg [7:0] valid_pipe;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipe <= 8'b0;
        end else begin
            valid_pipe <= {valid_pipe[6:0], valid_i};
        end
    end

    assign valid_o = valid_pipe[7];      // 第 7 拍结果有效
    assign hold_o  = |valid_pipe[6:0];   // pipeline 里有运算尚未完成时置高


endmodule
