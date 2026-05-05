/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date             Author      Notes
 * 2023-06-05       Lyons       first version
 * 2023-06-13       Lyons       add comments
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

// dff, set 'def_val' when 'reset' is valid, update when 'enable' is valid

module pa_dff_rst_def #(
    parameter               DW = 32
)(
    input  wire             clk_i,
    input  wire             rst_n_i,

    input  wire [DW-1:0]    def_val,

    input  wire             en,
    input  wire [DW-1:0]    din,

    output wire [DW-1:0]    qout
);

reg  [DW-1:0]               qout_r;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        qout_r[DW-1:0] <= def_val[DW-1:0];
    end
    else if (en) begin
        qout_r[DW-1:0] <= din[DW-1:0];
    end
    else begin
        qout_r[DW-1:0] <= qout_r[DW-1:0];
    end
end

assign qout[DW-1:0] = qout_r[DW-1:0];

endmodule


// dff, set '0' when 'reset' is valid, update when 'enable' is valid

module pa_dff_rst_0 #(
    parameter               DW = 32
)(
    input  wire             clk_i,
    input  wire             rst_n_i,

    input  wire             en,
    input  wire [DW-1:0]    din,

    output wire [DW-1:0]    qout
);

pa_dff_rst_def #(DW) _dff (clk_i, rst_n_i, {DW{1'b0}}, en, din, qout);

endmodule


// dff, set '1' when 'reset' is valid, update when 'enable' is valid

module pa_dff_rst_1 #(
    parameter               DW = 32
)(
    input  wire             clk_i,
    input  wire             rst_n_i,

    input  wire             en,
    input  wire [DW-1:0]    din,

    output wire [DW-1:0]    qout
);

pa_dff_rst_def #(DW) _dff (clk_i, rst_n_i, {DW{1'b1}}, en, din, qout);

endmodule


// dff, update when 'enable' is valid, lock when it is invalid
module pa_dff_en_l #(
    parameter               DW = 32
)(
    input  wire             clk_i,
    input  wire             rst_n_i,

    input  wire             en,
    input  wire [DW-1:0]    din,

    output wire [DW-1:0]    qout
);

reg  [DW-1:0]               qout_r;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        qout_r[DW-1:0] <= 0;
    end
    else if (en) begin
        qout_r[DW-1:0] <= din[DW-1:0];
    end
    else begin
        qout_r[DW-1:0] <= qout_r[DW-1:0];
    end
end

assign qout[DW-1:0] = qout_r[DW-1:0];

endmodule


// dff, update when 'enable' is valid
module pa_dff_en_2 #(
    parameter               DW = 32
)(
    input  wire             clk_i,
    input  wire             rst_n_i,

    input  wire             en,
    input  wire [DW-1:0]    din1,
    input  wire [DW-1:0]    din2,

    output wire [DW-1:0]    qout
);

reg  [DW-1:0]               qout_r;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        qout_r[DW-1:0] <= 0;
    end
    else if (en) begin
        qout_r[DW-1:0] <= din1[DW-1:0];
    end
    else begin
        qout_r[DW-1:0] <= din2[DW-1:0];
    end
end

assign qout[DW-1:0] = qout_r[DW-1:0];

endmodule
