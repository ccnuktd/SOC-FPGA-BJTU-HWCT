/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date             Author      Notes
 * 2021-10-29       Lyons       first version
 * 2022-04-04       Lyons       v2.0
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

module pa_soc_rbm (
    input  wire [`ADDR_BUS_WIDTH-1:0]   m_addr_i,
    output reg  [`DATA_BUS_WIDTH-1:0]   m_data_o,
    input  wire                         m_we_i,
    input  wire                         m_rd_i,

    input  wire [`DATA_BUS_WIDTH-1:0]   s0_data_i,
    output reg                          s0_we_o,
    output reg                          s0_rd_o,

    input  wire [`DATA_BUS_WIDTH-1:0]   s1_data_i,
    output reg                          s1_we_o,
    output reg                          s1_rd_o,

    input  wire [`DATA_BUS_WIDTH-1:0]   s2_data_i,
    output reg                          s2_we_o,
    output reg                          s2_rd_o,

    input  wire [`DATA_BUS_WIDTH-1:0]   s3_data_i,
    output reg                          s3_we_o,
    output reg                          s3_rd_o,

    input  wire [`DATA_BUS_WIDTH-1:0]   s4_data_i,
    output reg                          s4_we_o,
    output reg                          s4_rd_o,

    input  wire [`DATA_BUS_WIDTH-1:0]   s5_data_i,
    output reg                          s5_we_o,
    output reg                          s5_rd_o,

    input  wire [`DATA_BUS_WIDTH-1:0]   s6_data_i,
    output reg                          s6_we_o,
    output reg                          s6_rd_o
);


localparam SLAVE_0_ADDR                 = 16'h8000; // ram    0x8000_0000 ~ 0x8000_ffff
localparam SLAVE_1_ADDR                 = 16'h0000; // XXX    XXXXXXXXXXXXXXXXXXXXXXXXX
localparam SLAVE_2_ADDR                 = 16'h8001; // timer  0x8001_0000 ~ 0x8001_ffff
localparam SLAVE_3_ADDR                 = 16'h8002; // uart   0x8002_0000 ~ 0x8002_ffff
localparam SLAVE_4_ADDR                 = 16'h8003; // i2c    0x8003_0000 ~ 0x8003_ffff
localparam SLAVE_5_ADDR                 = 16'h8004; // spi    0x8004_0000 ~ 0x8004_ffff
localparam SLAVE_6_ADDR                 = 16'h8005; // lcd    0x8005_0000 ~ 0x8005_ffff


always @ (*) begin
    case (m_addr_i[31:16])
        SLAVE_0_ADDR : m_data_o[`DATA_BUS_WIDTH-1:0] = s0_data_i[`DATA_BUS_WIDTH-1:0];
        SLAVE_1_ADDR : m_data_o[`DATA_BUS_WIDTH-1:0] = s1_data_i[`DATA_BUS_WIDTH-1:0];
        SLAVE_2_ADDR : m_data_o[`DATA_BUS_WIDTH-1:0] = s2_data_i[`DATA_BUS_WIDTH-1:0];
        SLAVE_3_ADDR : m_data_o[`DATA_BUS_WIDTH-1:0] = s3_data_i[`DATA_BUS_WIDTH-1:0];
        SLAVE_4_ADDR : m_data_o[`DATA_BUS_WIDTH-1:0] = s4_data_i[`DATA_BUS_WIDTH-1:0];
        SLAVE_5_ADDR : m_data_o[`DATA_BUS_WIDTH-1:0] = s5_data_i[`DATA_BUS_WIDTH-1:0];
        SLAVE_6_ADDR : m_data_o[`DATA_BUS_WIDTH-1:0] = s6_data_i[`DATA_BUS_WIDTH-1:0];
        default      : m_data_o[`DATA_BUS_WIDTH-1:0] = `ZERO_WORD;
    endcase
end

always @ (*) begin
    s0_we_o = `INVALID;
    s1_we_o = `INVALID;
    s2_we_o = `INVALID;
    s3_we_o = `INVALID;
    s4_we_o = `INVALID;
    s5_we_o = `INVALID;
    s6_we_o = `INVALID;
    case (m_addr_i[31:16])
        SLAVE_0_ADDR : s0_we_o = m_we_i;
        SLAVE_1_ADDR : s1_we_o = m_we_i;
        SLAVE_2_ADDR : s2_we_o = m_we_i;
        SLAVE_3_ADDR : s3_we_o = m_we_i;
        SLAVE_4_ADDR : s4_we_o = m_we_i;
        SLAVE_5_ADDR : s5_we_o = m_we_i;
        SLAVE_6_ADDR : s6_we_o = m_we_i;
    endcase
end

always @ (*) begin
    s0_rd_o = `INVALID;
    s1_rd_o = `INVALID;
    s2_rd_o = `INVALID;
    s3_rd_o = `INVALID;
    s4_rd_o = `INVALID;
    s5_rd_o = `INVALID;
    s6_rd_o = `INVALID;
    case (m_addr_i[31:16])
        SLAVE_0_ADDR : s0_rd_o = m_rd_i;
        SLAVE_1_ADDR : s1_rd_o = m_rd_i;
        SLAVE_2_ADDR : s2_rd_o = m_rd_i;
        SLAVE_3_ADDR : s3_rd_o = m_rd_i;
        SLAVE_4_ADDR : s4_rd_o = m_rd_i;
        SLAVE_5_ADDR : s5_rd_o = m_rd_i;
        SLAVE_6_ADDR : s6_rd_o = m_rd_i;
    endcase
end

endmodule
