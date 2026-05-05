/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date             Author      Notes
 * 2021-10-29       Lyons       first version
 * 2022-04-04       Lyons       v2.0
 * 2024-04-25       Migration   Add debug outputs for difftest
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

module pa_core_rtu (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    input  wire [`REG_BUS_WIDTH-1:0]    reg1_raddr_i,
    input  wire [`REG_BUS_WIDTH-1:0]    reg2_raddr_i,

    input  wire [`REG_BUS_WIDTH-1:0]    reg_waddr_i,
    input  wire                         reg_waddr_vld_i,

    input  wire [`DATA_BUS_WIDTH-1:0]   reg_wdata_i,

    output wire [`DATA_BUS_WIDTH-1:0]   reg1_rdata_o,
    output wire [`DATA_BUS_WIDTH-1:0]   reg2_rdata_o,

    output wire [`DATA_BUS_WIDTH-1:0]   csr_mtvec_o,
    output wire [`DATA_BUS_WIDTH-1:0]   csr_mepc_o,
    output wire [`DATA_BUS_WIDTH-1:0]   csr_mstatus_o,

    input  wire [`CSR_BUS_WIDTH-1:0]    csr_raddr_i,

    input  wire [`CSR_BUS_WIDTH-1:0]    csr_waddr_i,
    input  wire                         csr_waddr_vld_i,

    input  wire [`DATA_BUS_WIDTH-1:0]   csr_wdata_i,

    output wire [`DATA_BUS_WIDTH-1:0]   csr_rdata_o,

    // Debug outputs for difftest
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_0,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_1,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_2,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_3,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_4,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_5,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_6,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_7,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_8,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_9,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_10,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_11,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_12,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_13,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_14,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_15,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_16,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_17,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_18,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_19,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_20,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_21,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_22,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_23,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_24,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_25,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_26,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_27,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_28,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_29,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_30,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_reg_31
);

pa_core_csr u_pa_core_csr (
    .clk_i                              (clk_i),
    .rst_n_i                            (rst_n_i),

    .csr_mtvec_o                        (csr_mtvec_o),
    .csr_mepc_o                         (csr_mepc_o),
    .csr_mstatus_o                      (csr_mstatus_o),

    .csr_raddr_i                        (csr_raddr_i),

    .csr_waddr_i                        (csr_waddr_i),
    .csr_waddr_vld_i                    (csr_waddr_vld_i),

    .csr_wdata_i                        (csr_wdata_i),

    .csr_rdata_o                        (csr_rdata_o)
);

pa_core_xreg u_pa_core_xreg (
    .clk_i                              (clk_i),
    .rst_n_i                            (rst_n_i),

    .reg1_raddr_i                       (reg1_raddr_i),
    .reg2_raddr_i                       (reg2_raddr_i),

    .reg_waddr_i                        (reg_waddr_i),
    .reg_waddr_vld_i                    (reg_waddr_vld_i),

    .reg_wdata_i                        (reg_wdata_i),

    .reg1_rdata_o                       (reg1_rdata_o),
    .reg2_rdata_o                       (reg2_rdata_o),

    // Debug outputs passed through
    .debug_reg_0                        (debug_reg_0),
    .debug_reg_1                        (debug_reg_1),
    .debug_reg_2                        (debug_reg_2),
    .debug_reg_3                        (debug_reg_3),
    .debug_reg_4                        (debug_reg_4),
    .debug_reg_5                        (debug_reg_5),
    .debug_reg_6                        (debug_reg_6),
    .debug_reg_7                        (debug_reg_7),
    .debug_reg_8                        (debug_reg_8),
    .debug_reg_9                        (debug_reg_9),
    .debug_reg_10                       (debug_reg_10),
    .debug_reg_11                       (debug_reg_11),
    .debug_reg_12                       (debug_reg_12),
    .debug_reg_13                       (debug_reg_13),
    .debug_reg_14                       (debug_reg_14),
    .debug_reg_15                       (debug_reg_15),
    .debug_reg_16                       (debug_reg_16),
    .debug_reg_17                       (debug_reg_17),
    .debug_reg_18                       (debug_reg_18),
    .debug_reg_19                       (debug_reg_19),
    .debug_reg_20                       (debug_reg_20),
    .debug_reg_21                       (debug_reg_21),
    .debug_reg_22                       (debug_reg_22),
    .debug_reg_23                       (debug_reg_23),
    .debug_reg_24                       (debug_reg_24),
    .debug_reg_25                       (debug_reg_25),
    .debug_reg_26                       (debug_reg_26),
    .debug_reg_27                       (debug_reg_27),
    .debug_reg_28                       (debug_reg_28),
    .debug_reg_29                       (debug_reg_29),
    .debug_reg_30                       (debug_reg_30),
    .debug_reg_31                       (debug_reg_31)
);

endmodule
