/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date             Author      Notes
 * 2021-10-29       Lyons       first version
 * 2022-04-04       Lyons       v2.0
 * 2023-06-10       Lyons       v3.0
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

module pa_core_top (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    input  wire                         irq_i,

    output wire [`ADDR_BUS_WIDTH-1:0]   ibus_addr_o,
    input  wire [`DATA_BUS_WIDTH-1:0]   ibus_data_i,

    output wire [`ADDR_BUS_WIDTH-1:0]   dbus_addr_o,
    output                              dbus_rd_o,
    output                              dbus_we_o,
    output wire [2:0]                   dbus_size_o,
    output wire [`DATA_BUS_WIDTH-1:0]   dbus_data_o,
    input  wire [`DATA_BUS_WIDTH-1:0]   dbus_data_i,

    output wire [`ADDR_BUS_WIDTH-1:0]   debug_wb_pc,
    output wire                         debug_wb_valid,
    output wire [`REG_BUS_WIDTH-1:0]    debug_wb_reg,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_wb_value,
    output wire [`ADDR_BUS_WIDTH-1:0]   debug_fetch_pc,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_exu_inst,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_wb_instr,
    output reg                          debug_inst_complete_valid,
    output reg [`ADDR_BUS_WIDTH-1:0]    debug_inst_complete_pc,
    output reg [`DATA_BUS_WIDTH-1:0]    debug_inst_complete_instr,
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


wire                                    exu_hold_flag;
wire                                    int_hold_flag;

wire                                    hold_flag;

wire                                    jump_flag;
wire [`ADDR_BUS_WIDTH-1:0]              jump_addr;

wire                                    idu_flush_flag;
wire                                    exu_flush_flag;
wire                                    int_hold_flag_1r;
wire                                    int_hold_flag_2r;


wire                                        hold_flag_1r;
pa_dff_rst_0 #(1)                       dff_hold_flag_1r (clk_i, rst_n_i, `VALID, hold_flag, hold_flag_1r);

wire                                        jump_flag_1r;
pa_dff_rst_0 #(1)                       dff_jump_flag_1r (clk_i, rst_n_i, `VALID, jump_flag, jump_flag_1r);

// inst address generated from pcgen module
// inst data fetched after one clock

wire [`ADDR_BUS_WIDTH-1:0]              inst_addr;
wire [`DATA_BUS_WIDTH-1:0]              inst_data;

pa_core_pcgen u_pa_core_pcgen (
    .clk_i                              (clk_i),
    .rst_n_i                            (rst_n_i),

    .reset_flag_i                       (`INVALID),

    .hold_flag_i                        (hold_flag),

    .jump_flag_i                        (jump_flag),
    .jump_addr_i                        (jump_addr),

    .pc_o                               (inst_addr)
);

// "ifu_inst_addr" work under IF state

wire [`ADDR_BUS_WIDTH-1:0]              ifu_inst_addr;

assign ifu_inst_addr[`ADDR_BUS_WIDTH-1:0] = inst_addr[`ADDR_BUS_WIDTH-1:0];

// inst data fetched from tcm module by bus

assign ibus_addr_o[`ADDR_BUS_WIDTH-1:0] = ifu_inst_addr[`ADDR_BUS_WIDTH-1:0];
assign inst_data[`DATA_BUS_WIDTH-1:0] = ibus_data_i[`DATA_BUS_WIDTH-1:0];

// "idu_inst_data" work under ID state

wire [`DATA_BUS_WIDTH-1:0]              idu_inst_data;

wire [`DATA_BUS_WIDTH-1:0]                  inst_data_1r;
pa_dff_en_2 #(`DATA_BUS_WIDTH)          dff_inst_data_1r (clk_i, rst_n_i, idu_flush_flag, {`DATA_BUS_WIDTH{1'b0}}, idu_inst_data, inst_data_1r);

assign idu_inst_data[`DATA_BUS_WIDTH-1:0] = hold_flag_1r ? inst_data_1r[`DATA_BUS_WIDTH-1:0]
                                                         : inst_data[`DATA_BUS_WIDTH-1:0];


wire [`INST_SET_WIDTH-1:0]              inst_set;
wire [`INST_TYPE_WIDTH-1:0]             inst_type;
wire [`INST_FUNC_WIDTH-1:0]             inst_func;

wire [`REG_BUS_WIDTH-1:0]               reg1_raddr;
wire [`REG_BUS_WIDTH-1:0]               reg2_raddr;

wire [`DATA_BUS_WIDTH-1:0]              reg1_rdata;
wire [`DATA_BUS_WIDTH-1:0]              reg2_rdata;

wire [`REG_BUS_WIDTH-1:0]               reg_waddr;
wire                                    reg_waddr_vld;

wire [`DATA_BUS_WIDTH-1:0]              uimm_data;

wire [`CSR_BUS_WIDTH-1:0]               csr_addr;

// ifu module only include comb logic, no timing logic

pa_core_idu u_pa_core_idu (
    .inst_data_i                        (idu_inst_data),

    .inst_set_o                         (inst_set),
    .inst_type_o                        (inst_type),
    .inst_func_o                        (inst_func),

    .reg1_raddr_o                       (reg1_raddr),
    .reg2_raddr_o                       (reg2_raddr),

    .reg_waddr_o                        (reg_waddr),
    .reg_waddr_vld_o                    (reg_waddr_vld),

    .uimm_o                             (uimm_data),
    .csr_o                              (csr_addr)
);

wire [`INST_SET_WIDTH-1:0]                  exu_inst_set;
pa_dff_en_2 #(`INST_SET_WIDTH)          dff_exu_inst_set (clk_i, rst_n_i, exu_flush_flag, {`INST_SET_WIDTH{1'b0}}, inst_set, exu_inst_set);

wire [`INST_FUNC_WIDTH-1:0]                 exu_inst_func;
pa_dff_en_2 #(`INST_FUNC_WIDTH)         dff_exu_inst_func (clk_i, rst_n_i, exu_flush_flag, {`INST_FUNC_WIDTH{1'b0}}, inst_func, exu_inst_func);

wire [`DATA_BUS_WIDTH-1:0]                  exu_reg1_rdata;
pa_dff_en_2 #(`DATA_BUS_WIDTH)          dff_exu_reg1_rdata (clk_i, rst_n_i, exu_flush_flag, {`DATA_BUS_WIDTH{1'b0}}, reg1_rdata, exu_reg1_rdata);

wire [`DATA_BUS_WIDTH-1:0]                  exu_reg2_rdata;
pa_dff_en_2 #(`DATA_BUS_WIDTH)          dff_exu_reg2_rdata (clk_i, rst_n_i, exu_flush_flag, {`DATA_BUS_WIDTH{1'b0}}, reg2_rdata, exu_reg2_rdata);

wire [`REG_BUS_WIDTH-1:0]                   exu_reg_waddr;
pa_dff_en_2 #(`REG_BUS_WIDTH)           dff_exu_reg_waddr (clk_i, rst_n_i, exu_flush_flag, {`REG_BUS_WIDTH{1'b0}}, reg_waddr, exu_reg_waddr);

wire                                        exu_reg_waddr_vld;
pa_dff_en_2 #(1)                        dff_exu_reg_waddr_vld (clk_i, rst_n_i, exu_flush_flag, 1'b0, reg_waddr_vld, exu_reg_waddr_vld);

wire [`DATA_BUS_WIDTH-1:0]                  exu_uimm_data;
pa_dff_en_2 #(`DATA_BUS_WIDTH)          dff_exu_uimm_data (clk_i, rst_n_i, exu_flush_flag, {`DATA_BUS_WIDTH{1'b0}}, uimm_data, exu_uimm_data);

wire [`CSR_BUS_WIDTH-1:0]                   exu_csr_addr;
pa_dff_en_2 #(`CSR_BUS_WIDTH)           dff_exu_csr_addr (clk_i, rst_n_i, exu_flush_flag, {`CSR_BUS_WIDTH{1'b0}}, csr_addr, exu_csr_addr);

// exu module generate "exu_hold_flag" signal if extend EX state

wire [`DATA_BUS_WIDTH-1:0]              exu_csr_rdata;

wire                                    exu_csr_waddr_vld;
wire [`DATA_BUS_WIDTH-1:0]              exu_csr_wdata;

wire                                    mem_en_flag;

wire                                    exu_jump_flag;
wire [`ADDR_BUS_WIDTH-1:0]              exu_jump_addr;
wire                                    exu_branch_flag;

wire [`REG_BUS_WIDTH-1:0]               reg_waddr_wb;
wire                                    reg_waddr_wb_vld;
wire                                    reg_waddr_wb_vld_1r;

wire [`DATA_BUS_WIDTH-1:0]              iresult;
wire                                    iresult_vld;

pa_core_exu u_pa_core_exu (
    .clk_i                              (clk_i),
    .rst_n_i                            (rst_n_i),

    .inst_set_i                         (exu_inst_set[1:0]),
    .inst_func_i                        (exu_inst_func),

    .pc_i                               (ifu_inst_addr),

    .reg1_rdata_i                       (exu_reg1_rdata),
    .reg2_rdata_i                       (exu_reg2_rdata),

    .uimm_i                             (exu_uimm_data[19:0]),

    .reg_waddr_i                        (exu_reg_waddr),
    .reg_waddr_vld_i                    (exu_reg_waddr_vld),

    .csr_rdata_i                        (exu_csr_rdata),

    .csr_waddr_vld_o                    (exu_csr_waddr_vld),
    .csr_wdata_o                        (exu_csr_wdata),

    .mem_en_o                           (mem_en_flag),

    .hold_flag_o                        (exu_hold_flag),

    .jump_flag_o                        (exu_jump_flag),
    .jump_addr_o                        (exu_jump_addr),

    .reg_waddr_o                        (reg_waddr_wb),
    .reg_waddr_vld_o                    (reg_waddr_wb_vld),

    .iresult_o                          (iresult),
    .iresult_vld_o                      (iresult_vld)
);

assign exu_branch_flag = exu_inst_set[0] && exu_inst_func[11];

pa_dff_rst_0 #(1)                       dff_reg_waddr_wb_vld_1r (clk_i, rst_n_i, `VALID, reg_waddr_wb_vld, reg_waddr_wb_vld_1r);

// clint module generate "int_hold_flag" signal if interrupt valid

wire [`DATA_BUS_WIDTH-1:0]              csr_mtvec_data;
wire [`DATA_BUS_WIDTH-1:0]              csr_mepc_data;
wire [`DATA_BUS_WIDTH-1:0]              csr_mstatus_data;

wire [`CSR_BUS_WIDTH-1:0]               int_csr_waddr;
wire                                    int_csr_waddr_vld;
wire [`DATA_BUS_WIDTH-1:0]              int_csr_wdata;

wire                                    int_jump_flag;
wire [`ADDR_BUS_WIDTH-1:0]              int_jump_addr;

pa_core_clint u_pa_core_clint (
    .clk_i                              (clk_i),
    .rst_n_i                            (rst_n_i),

    .inst_set_i                         (exu_inst_set[0]),
    .inst_func_i                        (exu_inst_func[6:4]),

    .pc_i                               (ifu_inst_addr),
    .inst_i                             (idu_inst_data),

    .csr_mtvec_i                        (csr_mtvec_data),
    .csr_mepc_i                         (csr_mepc_data),
    .csr_mstatus_i                      (csr_mstatus_data),

    .irq_i                              (irq_i),

    .jump_flag_i                        (exu_jump_flag),
    .jump_addr_i                        (exu_jump_addr),
    .branch_flag_i                      (exu_branch_flag),
    .hold_flag_i                        (exu_hold_flag || reg_waddr_wb_vld || reg_waddr_wb_vld_1r || mem_en_flag),




    .csr_waddr_o                        (int_csr_waddr),
    .csr_waddr_vld_o                    (int_csr_waddr_vld),
    .csr_wdata_o                        (int_csr_wdata),

    .hold_flag_o                        (int_hold_flag),

    .jump_flag_o                        (int_jump_flag),
    .jump_addr_o                        (int_jump_addr)
);

assign hold_flag = exu_hold_flag
                || int_hold_flag;

assign jump_flag = exu_jump_flag
                || int_jump_flag;

assign jump_addr = exu_jump_flag ? exu_jump_addr
                                 : int_jump_addr;

assign idu_flush_flag = (jump_flag)
                     || (int_hold_flag_1r);

assign exu_flush_flag = (jump_flag || jump_flag_1r)
                     || (exu_hold_flag);

pa_dff_rst_0 #(1)                       dff_int_hold_flag_1r (clk_i, rst_n_i, `VALID, int_hold_flag, int_hold_flag_1r);
pa_dff_rst_0 #(1)                       dff_int_hold_flag_2r (clk_i, rst_n_i, `VALID, int_hold_flag_1r, int_hold_flag_2r);

wire [`CSR_BUS_WIDTH-1:0]               csr_waddr;
wire                                    csr_waddr_vld;
wire [`DATA_BUS_WIDTH-1:0]              csr_wdata;

assign csr_waddr[`CSR_BUS_WIDTH-1:0] = exu_csr_addr[`CSR_BUS_WIDTH-1:0]
                                     | int_csr_waddr[`CSR_BUS_WIDTH-1:0];

assign csr_waddr_vld = exu_csr_waddr_vld
                     | int_csr_waddr_vld;

assign csr_wdata[`DATA_BUS_WIDTH-1:0] = exu_csr_wdata[`DATA_BUS_WIDTH-1:0]
                                      | int_csr_wdata[`DATA_BUS_WIDTH-1:0];

// mem store generate address in EX state, write under next clock
// mem load generate address in EX state, return data after next clock

wire                                        mem_en_flag_1r;
pa_dff_rst_0 #(1)                       dff_mem_en_flag_1r (clk_i, rst_n_i, `VALID, mem_en_flag, mem_en_flag_1r);

wire [`ADDR_BUS_WIDTH-1:0]              mem_addr;
wire [`DATA_BUS_WIDTH-1:0]              mem_data;
wire [2:0]                              mem_size;

wire [`DATA_BUS_WIDTH-1:0]              mem_wdata;
wire                                    mem_wdata_vld;

wire [`DATA_BUS_WIDTH-1:0]              mem_rdata;
wire                                    mem_rdata_vld;

wire [`ADDR_BUS_WIDTH-1:0]                  mem_addr_1r;
pa_dff_rst_0 #(`ADDR_BUS_WIDTH)         dff_mem_addr_1r (clk_i, rst_n_i, `VALID, mem_addr, mem_addr_1r);

assign mem_addr[`ADDR_BUS_WIDTH-1:0]  = {{`ADDR_BUS_WIDTH}{mem_en_flag   }} & iresult[`DATA_BUS_WIDTH-1:0]
                                      | {{`ADDR_BUS_WIDTH}{mem_en_flag_1r}} & mem_addr_1r[`ADDR_BUS_WIDTH-1:0];

assign mem_wdata[`DATA_BUS_WIDTH-1:0] = {{`DATA_BUS_WIDTH}{mem_en_flag   }} & exu_reg2_rdata[`DATA_BUS_WIDTH-1:0];
assign mem_wdata_vld = mem_en_flag;

wire                                        subop_sign_1r;
pa_dff_rst_0 #(1)                       dff_subop_sign_1r (clk_i, rst_n_i, `VALID, exu_inst_func[31], subop_sign_1r);

wire [1:0]                                  subop_size_1r;
pa_dff_rst_0 #(2)                       dff_subop_size_1r (clk_i, rst_n_i, `VALID, exu_inst_func[29:28], subop_size_1r);

wire                                        op_load_1r;
pa_dff_rst_0 #(1)                       dff_op_load_1r (clk_i, rst_n_i, `VALID, exu_inst_func[14], op_load_1r);

wire                                    subop_sign;
wire [1:0]                              subop_size;
wire                                    op_load;
wire                                    op_store;

assign subop_sign      = exu_inst_func[31] || subop_sign_1r;
assign subop_size[1:0] = exu_inst_func[29:28] | subop_size_1r[1:0];
assign op_load         = exu_inst_func[14] || op_load_1r;
assign op_store        = exu_inst_func[13];

wire [4:0]                              mau_inst_func;

assign mau_inst_func[4:0] = {subop_sign, subop_size[1:0], op_load, op_store};

pa_core_mau u_pa_core_mau (
    .inst_func_i                        (mau_inst_func),

    .mem_addr_i                         (mem_addr[1:0]),

    .mem_data_i                         (mem_wdata),
    .mem_data_vld_i                     (mem_wdata_vld),

    .mem_data_o                         (mem_rdata),
    .mem_data_vld_o                     (mem_rdata_vld),

    .rbm_data_i                         (dbus_data_i),

    .rbm_data_o                         (mem_data),
    .rbm_size_o                         (mem_size)
);

assign dbus_addr_o[`ADDR_BUS_WIDTH-1:0] = {32{mem_en_flag || mem_en_flag_1r}} & mem_addr[`ADDR_BUS_WIDTH-1:0];
assign dbus_data_o[`DATA_BUS_WIDTH-1:0] = {32{mem_en_flag}} & mem_data[`DATA_BUS_WIDTH-1:0];
assign dbus_size_o[2:0] = {3{mem_en_flag}} & mem_size[2:0];
assign dbus_rd_o = mem_en_flag & op_load;
assign dbus_we_o = mem_en_flag & op_store;

wire [`REG_BUS_WIDTH-1:0]                   mau_reg_addr;
pa_dff_rst_0 #(`REG_BUS_WIDTH)          dff_mau_reg_addr (clk_i, rst_n_i, `VALID, reg_waddr_wb, mau_reg_addr);

wire                                        mau_reg_addr_vld;
pa_dff_rst_0 #(1)                       dff_mau_reg_addr_vld (clk_i, rst_n_i, `VALID, reg_waddr_wb_vld, mau_reg_addr_vld);

wire [`DATA_BUS_WIDTH-1:0]              mau_mem_data;
wire                                    mau_mem_data_vld;

assign mau_mem_data[`DATA_BUS_WIDTH-1:0] = mem_rdata[`DATA_BUS_WIDTH-1:0];
assign mau_mem_data_vld = mem_rdata_vld;

// rtu module work under ID/WB state, include regfile and csrfile

wire [`REG_BUS_WIDTH-1:0]               rtu_reg_waddr;
wire                                    rtu_reg_waddr_vld;

wire [`DATA_BUS_WIDTH-1:0]              rtu_reg_wdata;

wire [`CSR_BUS_WIDTH-1:0]               rtu_csr_waddr;
wire                                    rtu_csr_waddr_vld;

wire [`DATA_BUS_WIDTH-1:0]              rtu_csr_wdata;

assign rtu_reg_waddr[`REG_BUS_WIDTH-1:0]   = mau_mem_data_vld ?  mau_reg_addr[`REG_BUS_WIDTH-1:0] // from memory
                                                              :  reg_waddr_wb[`REG_BUS_WIDTH-1:0]; // from exu
assign rtu_reg_waddr_vld                   = mau_mem_data_vld ? (mau_reg_addr_vld && !mem_en_flag) // from memory
                                                              :  reg_waddr_wb_vld; // from exu

assign rtu_reg_wdata[`DATA_BUS_WIDTH-1:0]  = mau_mem_data_vld ?  mau_mem_data[`DATA_BUS_WIDTH-1:0] // from memory, data
                                                              :  iresult[`DATA_BUS_WIDTH-1:0]; // from exu, data

assign rtu_csr_waddr[`CSR_BUS_WIDTH-1:0]   = csr_waddr[`CSR_BUS_WIDTH-1:0];
assign rtu_csr_waddr_vld                   = csr_waddr_vld;

assign rtu_csr_wdata[`DATA_BUS_WIDTH-1:0]  = csr_wdata[`DATA_BUS_WIDTH-1:0];

assign debug_wb_pc                         = ifu_inst_addr;
assign debug_wb_valid                      = rtu_reg_waddr_vld;
assign debug_wb_reg[`REG_BUS_WIDTH-1:0]    = rtu_reg_waddr[`REG_BUS_WIDTH-1:0];
assign debug_wb_value[`DATA_BUS_WIDTH-1:0] = rtu_reg_wdata[`DATA_BUS_WIDTH-1:0];
assign debug_fetch_pc[`ADDR_BUS_WIDTH-1:0] = ifu_inst_addr[`ADDR_BUS_WIDTH-1:0];
assign debug_exu_inst[`DATA_BUS_WIDTH-1:0] = idu_inst_data[`DATA_BUS_WIDTH-1:0];
assign debug_wb_instr[`DATA_BUS_WIDTH-1:0] = `ZERO_WORD;

always @(*) begin
    debug_inst_complete_valid = rtu_reg_waddr_vld || mem_wdata_vld || exu_jump_flag;
    debug_inst_complete_pc    = exu_jump_flag ? jump_addr : ifu_inst_addr;
    debug_inst_complete_instr = idu_inst_data;
end

assign debug_reg_0  = `ZERO_WORD;
assign debug_reg_1  = `ZERO_WORD;
assign debug_reg_2  = `ZERO_WORD;
assign debug_reg_3  = `ZERO_WORD;
assign debug_reg_4  = `ZERO_WORD;
assign debug_reg_5  = `ZERO_WORD;
assign debug_reg_6  = `ZERO_WORD;
assign debug_reg_7  = `ZERO_WORD;
assign debug_reg_8  = `ZERO_WORD;
assign debug_reg_9  = `ZERO_WORD;
assign debug_reg_10 = `ZERO_WORD;
assign debug_reg_11 = `ZERO_WORD;
assign debug_reg_12 = `ZERO_WORD;
assign debug_reg_13 = `ZERO_WORD;
assign debug_reg_14 = `ZERO_WORD;
assign debug_reg_15 = `ZERO_WORD;
assign debug_reg_16 = `ZERO_WORD;
assign debug_reg_17 = `ZERO_WORD;
assign debug_reg_18 = `ZERO_WORD;
assign debug_reg_19 = `ZERO_WORD;
assign debug_reg_20 = `ZERO_WORD;
assign debug_reg_21 = `ZERO_WORD;
assign debug_reg_22 = `ZERO_WORD;
assign debug_reg_23 = `ZERO_WORD;
assign debug_reg_24 = `ZERO_WORD;
assign debug_reg_25 = `ZERO_WORD;
assign debug_reg_26 = `ZERO_WORD;
assign debug_reg_27 = `ZERO_WORD;
assign debug_reg_28 = `ZERO_WORD;
assign debug_reg_29 = `ZERO_WORD;
assign debug_reg_30 = `ZERO_WORD;
assign debug_reg_31 = `ZERO_WORD;

pa_core_rtu u_pa_core_rtu (
    .clk_i                              (clk_i),
    .rst_n_i                            (rst_n_i),

    .reg1_raddr_i                       (reg1_raddr),
    .reg2_raddr_i                       (reg2_raddr),

    .reg_waddr_i                        (rtu_reg_waddr),
    .reg_waddr_vld_i                    (rtu_reg_waddr_vld),

    .reg_wdata_i                        (rtu_reg_wdata),

    .reg1_rdata_o                       (reg1_rdata),
    .reg2_rdata_o                       (reg2_rdata),

    .csr_mtvec_o                        (csr_mtvec_data),
    .csr_mepc_o                         (csr_mepc_data),
    .csr_mstatus_o                      (csr_mstatus_data),

    .csr_raddr_i                        (exu_csr_addr),

    .csr_waddr_i                        (rtu_csr_waddr),
    .csr_waddr_vld_i                    (rtu_csr_waddr_vld),

    .csr_wdata_i                        (rtu_csr_wdata),

    .csr_rdata_o                        (exu_csr_rdata)
);

endmodule
