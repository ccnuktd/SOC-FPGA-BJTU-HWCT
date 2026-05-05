/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date             Author      Notes
 * 2021-10-29       Lyons       first version
 * 2022-04-04       Lyons       v2.0
 * 2023-06-14       Lyons       v3.0, add comments
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

module pa_core_exu_div (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    input  wire [`DATA_BUS_WIDTH-1:0]   data1_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   data2_i,

    input  wire [`REG_BUS_WIDTH-1:0]    reg_waddr_i,

    input  wire                         op_div_i,
    input  wire                         op_rem_i,

    input  wire                         q_sign_i,
    input  wire                         r_sign_i,

    output wire                         hold_o,

    output wire [`REG_BUS_WIDTH-1:0]    reg_waddr_o,

    output wire [31:0]                  data_o,
    output wire                         data_vld_o
);


wire                                    div_start;

assign div_start = (op_div_i || op_rem_i);

wire [31:0]                                 data_dividend;
pa_dff_rst_0 #(32)                      dff_data_dividend (clk_i, rst_n_i, div_start, data1_i, data_dividend);

wire [31:0]                                 data_divisor;
pa_dff_rst_0 #(32)                      dff_data_divisor (clk_i, rst_n_i, div_start, data2_i, data_divisor);

wire                                        q_sign;
pa_dff_rst_0 #(1)                       dff_q_sign (clk_i, rst_n_i, div_start, q_sign_i, q_sign);

wire                                        r_sign;
pa_dff_rst_0 #(1)                       dff_r_sign (clk_i, rst_n_i, div_start, r_sign_i, r_sign);

wire                                        op;
pa_dff_rst_0 #(1)                       dff_op (clk_i, rst_n_i, div_start, op_div_i, op);

wire [`REG_BUS_WIDTH-1:0]                   reg_waddr;
pa_dff_rst_0 #(`REG_BUS_WIDTH)          dff_reg_waddr (clk_i, rst_n_i, div_start, reg_waddr_i, reg_waddr);

wire [64:0]                             current_divisor_n; // [-y]
wire [64:0]                             current_divisor_p; // [ y]

assign current_divisor_n[64:0] = {1'b1, (~data_divisor[31:0] + 32'd1), 32'b0}; // [-y]
assign current_divisor_p[64:0] = {1'b0,   data_divisor[31:0],          32'b0}; // [ y]

// 'divide_zero' is valid when 'data_divisor' is equal to zero
// 'divide_sel' is valid when 'data_divisor' is greater than 'data_dividend'

wire                                    divide_zero;
wire                                    divide_sel;

assign divide_zero = ~(|data_divisor[31:0]);

assign divide_sel = (data_divisor > data_dividend);

// division process

reg  [5:0]                              div_cnt;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        div_cnt <= 6'd33;
    end
    else if (div_start) begin
        if (data2_i == 32'd0) begin
            div_cnt <= 6'd32;
        end
        else if (data2_i > data1_i) begin
            div_cnt <= 6'd32;
        end
        else begin
            div_cnt <= 6'd0;
        end
    end
    else if (div_cnt > 6'd32) begin
        div_cnt <= div_cnt;
    end
    else begin
        div_cnt <= div_cnt + 6'd1;
    end
end

wire                                    sm_start;
wire                                    sm_running;
wire                                    sm_stop;

assign sm_start   = (div_cnt == 6'd0);
assign sm_running = (div_cnt >= 6'd0) && (div_cnt <= 6'd32);
assign sm_stop    = (div_cnt == 6'd32);

wire [64:0]                             rst_remainder;

wire [64:0]                             current_remainder;
reg  [64:0]                             next_remainder;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        next_remainder[64:0] <= 65'b0;
    end
    else if (sm_start) begin
        next_remainder[64:0] <= {33'b0, data_dividend[31:0]};
    end
    else if (sm_stop) begin
        next_remainder[64:0] <= next_remainder[64:0];
    end
    else if (sm_running) begin
        next_remainder[64:0] <= rst_remainder[64:0];
    end
    else begin
        next_remainder[64:0] <= 65'b0;
    end
end

assign current_remainder[64:0] = {next_remainder[63:0], 1'b0};

wire [64:0]                             rst_remainder_sub;
wire [64:0]                             rst_remainder_add;

assign rst_remainder_sub[64:0] = current_remainder[64:0]
                               + current_divisor_n[64:0];

assign rst_remainder_add[64:0] = current_remainder[64:0]
                               + current_divisor_p[64:0];

assign rst_remainder[64:1] = current_remainder[64] ? rst_remainder_add[64:1]
                                                   : rst_remainder_sub[64:1];

assign rst_remainder[0] = !rst_remainder[64];

wire [31:0]                             rst_qt;
wire [31:0]                             rst_rem;

assign rst_qt[31:0]  = rst_remainder[31:0];

wire [64:0]                     rst_remainder_back;

assign rst_remainder_back[64:0] = rst_remainder[64:0]
                                + current_divisor_p[64:0];

assign rst_rem[31:0] = rst_remainder[64] ? rst_remainder_back[63:32]
                                         : rst_remainder[63:32];

wire [31:0]                             rst_qt_final_t;
wire [31:0]                             rst_rem_final_t;

assign rst_qt_final_t[31:0]  = divide_zero ? 32'hffff_ffff
                                           : (divide_sel ? 32'b0 : rst_qt[31:0]);

assign rst_rem_final_t[31:0] = divide_zero ? data_dividend[31:0]
                                           : (divide_sel ? data_dividend[31:0] : rst_rem[31:0]);

wire [31:0]                             rst_qt_final;
wire [31:0]                             rst_rem_final;

assign rst_qt_final[31:0]  = q_sign ? (~rst_qt_final_t[31:0]  + 32'd1)
                                    :   rst_qt_final_t[31:0];

assign rst_rem_final[31:0] = r_sign ? (~rst_rem_final_t[31:0] + 32'd1)
                                    :   rst_rem_final_t[31:0];

assign hold_o = sm_running && !sm_stop;

assign reg_waddr_o[`REG_BUS_WIDTH-1:0] = {5{sm_stop}} & reg_waddr[`REG_BUS_WIDTH-1:0];

assign data_o[31:0] = {32{sm_stop}} & {op ? rst_qt_final[31:0] : rst_rem_final[31:0]};
assign data_vld_o = sm_stop;

endmodule
