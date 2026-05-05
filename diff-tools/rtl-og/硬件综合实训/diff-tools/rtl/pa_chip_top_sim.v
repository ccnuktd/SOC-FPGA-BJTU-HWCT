`timescale 1ns / 1ps
/*
 * Copyright (c) 2020-2024, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * 2024-04-25       Migration   Create simulation top-level module
 *                    - Remove FPGA IP cores
 *                    - Expose debug signals for difftest
 *                    - Support Verilator simulation
 *                    - TCM memory initialized via $fread
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "./pa_chip_param.v"
`endif

module pa_chip_top_sim (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    // Debug interface for difftest
    output wire [`ADDR_BUS_WIDTH-1:0]   debug_wb_pc,
    output wire                         debug_wb_valid,
    output wire                         debug_wb_have_inst,
    output wire [`REG_BUS_WIDTH-1:0]    debug_wb_reg,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_wb_value,

    // Register file debug interface (for npc difftest)
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_0,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_1,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_2,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_3,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_4,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_5,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_6,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_7,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_8,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_9,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_10,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_11,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_12,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_13,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_14,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_15,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_16,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_17,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_18,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_19,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_20,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_21,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_22,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_23,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_24,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_25,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_26,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_27,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_28,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_29,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_30,
    output wire [`DATA_BUS_WIDTH-1:0]   reg_file_31,

    // Current PC (fetch PC) - for difftest
    output wire [`ADDR_BUS_WIDTH-1:0]   current_pc,
    
    // Current instruction (from imem/m0) - for difftest
    output wire [`DATA_BUS_WIDTH-1:0]   current_instr,

    // EX stage instruction (from core) - for debugging
    output wire [`DATA_BUS_WIDTH-1:0]   current_exu_instr,

    // WB stage instruction (from core) - for debugging
    output wire [`DATA_BUS_WIDTH-1:0]   current_wb_instr,

    // Complete instruction tracking (EX stage)
    output wire                         inst_complete_valid,
    output wire [`ADDR_BUS_WIDTH-1:0]   inst_complete_pc,
    output wire [`DATA_BUS_WIDTH-1:0]   inst_complete_instr
);

// Internal wires
wire [`ADDR_BUS_WIDTH-1:0]              m0_addr;
wire [`DATA_BUS_WIDTH-1:0]              m0_rdata;  // Instruction data from TCM

wire [`ADDR_BUS_WIDTH-1:0]              m1_addr;
wire                                    m1_rd;
wire                                    m1_we;
wire [2:0]                              m1_size;
wire [`DATA_BUS_WIDTH-1:0]              m1_wdata;
wire [`DATA_BUS_WIDTH-1:0]              m1_rdata;

wire                                    s0_rd;
wire                                    s0_we;
wire [`DATA_BUS_WIDTH-1:0]              s0_data;

wire                                    s1_rd;
wire                                    s1_we;
wire [`DATA_BUS_WIDTH-1:0]              s1_data;

wire                                    s2_rd;
wire                                    s2_we;
wire [`DATA_BUS_WIDTH-1:0]              s2_data;

wire                                    s3_rd;
wire                                    s3_we;
wire [`DATA_BUS_WIDTH-1:0]              s3_data;

wire                                    s4_rd;
wire                                    s4_we;
wire [`DATA_BUS_WIDTH-1:0]              s4_data;

wire                                    s5_rd;
wire                                    s5_we;
wire [`DATA_BUS_WIDTH-1:0]              s5_data;

wire                                    s6_rd;
wire                                    s6_we;
wire [`DATA_BUS_WIDTH-1:0]              s6_data;

wire                                    uart_txd;

wire                                    clk_50m;
wire                                    rst_n;

assign clk_50m = clk_i;
assign rst_n = rst_n_i;

wire                                    irq_flag;

// Internal debug signals from core
wire [`ADDR_BUS_WIDTH-1:0]              core_wb_pc;
wire                                    core_wb_valid;
wire [`REG_BUS_WIDTH-1:0]               core_wb_reg;
wire [`DATA_BUS_WIDTH-1:0]              core_wb_value;
wire [`ADDR_BUS_WIDTH-1:0]              core_fetch_pc;
wire [`DATA_BUS_WIDTH-1:0]              core_exu_instr;
wire [`DATA_BUS_WIDTH-1:0]              core_wb_instr;
wire                                    core_jump_flag;
wire [`ADDR_BUS_WIDTH-1:0]              core_jump_pc;
wire [`DATA_BUS_WIDTH-1:0]              core_jump_instr;
wire                                    core_inst_complete_valid;
wire [`ADDR_BUS_WIDTH-1:0]              core_inst_complete_pc;
wire [`DATA_BUS_WIDTH-1:0]              core_inst_complete_instr;

// Connect debug outputs
assign debug_wb_pc = core_wb_pc;
assign debug_wb_valid = core_wb_valid;
assign debug_wb_reg = core_wb_reg;
assign debug_wb_value = core_wb_value;
assign current_pc = core_fetch_pc;
assign current_instr = m0_rdata;  // Expose current instruction to top level
assign current_exu_instr = core_exu_instr;  // EX stage instruction
assign current_wb_instr = core_wb_instr;  // WB stage instruction
assign inst_complete_valid = core_inst_complete_valid;
assign inst_complete_pc = core_inst_complete_pc;
assign inst_complete_instr = core_inst_complete_instr;

// Core instantiation
pa_core_top u_pa_core_top (
    .clk_i                              (clk_50m),
    .rst_n_i                            (rst_n),

    .irq_i                              (irq_flag),

    .ibus_addr_o                        (m0_addr),
    .ibus_data_i                        (m0_rdata),  // Connect to TCM instruction output

    .dbus_addr_o                        (m1_addr),
    .dbus_rd_o                          (m1_rd),
    .dbus_we_o                          (m1_we),
    .dbus_size_o                        (m1_size),
    .dbus_data_o                        (m1_wdata),
    .dbus_data_i                        (m1_rdata),

    // Debug outputs
    .debug_wb_pc                        (core_wb_pc),
    .debug_wb_valid                     (core_wb_valid),
    .debug_wb_reg                       (core_wb_reg),
    .debug_wb_value                     (core_wb_value),
    .debug_fetch_pc                     (core_fetch_pc),
    .debug_exu_inst                     (core_exu_instr),
    .debug_wb_instr                     (core_wb_instr),
    .debug_inst_complete_valid          (core_inst_complete_valid),
    .debug_inst_complete_pc             (core_inst_complete_pc),
    .debug_inst_complete_instr          (core_inst_complete_instr),

    .debug_reg_0                        (reg_file_0),
    .debug_reg_1                        (reg_file_1),
    .debug_reg_2                        (reg_file_2),
    .debug_reg_3                        (reg_file_3),
    .debug_reg_4                        (reg_file_4),
    .debug_reg_5                        (reg_file_5),
    .debug_reg_6                        (reg_file_6),
    .debug_reg_7                        (reg_file_7),
    .debug_reg_8                        (reg_file_8),
    .debug_reg_9                        (reg_file_9),
    .debug_reg_10                       (reg_file_10),
    .debug_reg_11                       (reg_file_11),
    .debug_reg_12                       (reg_file_12),
    .debug_reg_13                       (reg_file_13),
    .debug_reg_14                       (reg_file_14),
    .debug_reg_15                       (reg_file_15),
    .debug_reg_16                       (reg_file_16),
    .debug_reg_17                       (reg_file_17),
    .debug_reg_18                       (reg_file_18),
    .debug_reg_19                       (reg_file_19),
    .debug_reg_20                       (reg_file_20),
    .debug_reg_21                       (reg_file_21),
    .debug_reg_22                       (reg_file_22),
    .debug_reg_23                       (reg_file_23),
    .debug_reg_24                       (reg_file_24),
    .debug_reg_25                       (reg_file_25),
    .debug_reg_26                       (reg_file_26),
    .debug_reg_27                       (reg_file_27),
    .debug_reg_28                       (reg_file_28),
    .debug_reg_29                       (reg_file_29),
    .debug_reg_30                       (reg_file_30),
    .debug_reg_31                       (reg_file_31)
);

// Bus matrix
pa_soc_rbm u_pa_soc_rbm1 (
    .m_addr_i                           (m1_addr),
    .m_data_o                           (m1_rdata),
    .m_we_i                             (m1_we),
    .m_rd_i                             (m1_rd),

    .s0_data_i                          (s0_data),
    .s0_we_o                            (s0_we),
    .s0_rd_o                            (s0_rd),

    .s1_data_i                          (s1_data),
    .s1_we_o                            (s1_we),
    .s1_rd_o                            (s1_rd),

    .s2_data_i                          (s2_data),
    .s2_we_o                            (s2_we),
    .s2_rd_o                            (s2_rd),

    .s3_data_i                          (s3_data),
    .s3_we_o                            (s3_we),
    .s3_rd_o                            (s3_rd),

    .s4_data_i                          (s4_data),
    .s4_we_o                            (s4_we),
    .s4_rd_o                            (s4_rd),

    .s5_data_i                          (s5_data),
    .s5_we_o                            (s5_we),
    .s5_rd_o                            (s5_rd),

    .s6_data_i                          (s6_data),
    .s6_we_o                            (s6_we),
    .s6_rd_o                            (s6_rd)
);

// TCM (Tightly Coupled Memory) instantiation
// TCM loads bin file via $fread in initial block
pa_perips_tcm u_pa_perips_tcm (
    .clk_i                              (clk_50m),
    .rst_n_i                            (rst_n),

    // Data bus (load/store)
    .addr1_i                            (m1_addr),
    .rd1_i                              (s0_rd),
    .we1_i                              (s0_we),
    .size1_i                            (m1_size),
    .data1_i                            (m1_wdata),
    .data1_o                            (s0_data),

    // Instruction bus (fetch) - connected to m0
    .addr2_i                            (m0_addr),
    .rd2_i                              (1'b1),
    .data2_o                            (m0_rdata)
);

// Timer peripheral
pa_perips_timer u_pa_perips_timer1 (
    .clk_i                              (clk_50m),
    .rst_n_i                            (rst_n),

    .addr_i                             (m1_addr[7:0]),
    .data_rd_i                          (s2_rd),
    .data_we_i                          (s2_we),
    .data_i                             (m1_wdata),
    .data_o                             (s2_data),

    .irq_o                              (irq_flag)
);

// UART peripheral
pa_perips_uart u_pa_perips_uart (
    .clk_i                              (clk_50m),
    .rst_n_i                            (rst_n),

    .addr_i                             (m1_addr[7:0]),
    .data_rd_i                          (s1_rd),
    .data_we_i                          (s1_we),
    .data_i                             (m1_wdata),
    .data_o                             (s1_data),

    .pad_rxd                            (1'b1),
    .pad_txd                            (uart_txd)
);

// ============================================
// DPI-C debug interface for npc difftest
// ============================================
export "DPI-C" function dbg_get_reg;
function int dbg_get_reg(int idx);
    case (idx)
        0:  return 32'h0;
        1:  return reg_file_1;
        2:  return reg_file_2;
        3:  return reg_file_3;
        4:  return reg_file_4;
        5:  return reg_file_5;
        6:  return reg_file_6;
        7:  return reg_file_7;
        8:  return reg_file_8;
        9:  return reg_file_9;
        10: return reg_file_10;
        11: return reg_file_11;
        12: return reg_file_12;
        13: return reg_file_13;
        14: return reg_file_14;
        15: return reg_file_15;
        16: return reg_file_16;
        17: return reg_file_17;
        18: return reg_file_18;
        19: return reg_file_19;
        20: return reg_file_20;
        21: return reg_file_21;
        22: return reg_file_22;
        23: return reg_file_23;
        24: return reg_file_24;
        25: return reg_file_25;
        26: return reg_file_26;
        27: return reg_file_27;
        28: return reg_file_28;
        29: return reg_file_29;
        30: return reg_file_30;
        31: return reg_file_31;
        default: return 32'h0;
    endcase
endfunction

export "DPI-C" function dbg_get_pc;
function int dbg_get_pc();
    return current_pc;
endfunction

export "DPI-C" function dbg_get_wb_pc;
function int dbg_get_wb_pc();
    return debug_wb_pc;
endfunction

export "DPI-C" function dbg_get_wb_valid;
function int dbg_get_wb_valid();
    return debug_wb_valid ? 1 : 0;
endfunction

export "DPI-C" function dbg_get_wb_reg;
function int dbg_get_wb_reg();
    return {27'h0, debug_wb_reg};
endfunction

export "DPI-C" function dbg_get_wb_value;
function int dbg_get_wb_value();
    return debug_wb_value;
endfunction

export "DPI-C" function dbg_get_instr;
function int dbg_get_instr();
    return current_instr;
endfunction

export "DPI-C" function dbg_get_exu_instr;
function int dbg_get_exu_instr();
    return current_exu_instr;
endfunction

export "DPI-C" function dbg_get_wb_instr;
function int dbg_get_wb_instr();
    return current_wb_instr;
endfunction

// New DPI-C functions for complete instruction tracking
export "DPI-C" function dbg_get_inst_complete_valid;
function int dbg_get_inst_complete_valid();
    return inst_complete_valid ? 1 : 0;
endfunction

export "DPI-C" function dbg_get_inst_complete_pc;
function int dbg_get_inst_complete_pc();
    return inst_complete_pc;
endfunction

export "DPI-C" function dbg_get_inst_complete_instr;
function int dbg_get_inst_complete_instr();
    return inst_complete_instr;
endfunction

endmodule
