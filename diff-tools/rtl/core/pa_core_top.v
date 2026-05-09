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
 * 2024-04-25       Migration   Add debug outputs for difftest
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

    // Debug outputs for difftest
    output wire [`ADDR_BUS_WIDTH-1:0]   debug_wb_pc,
    output wire                         debug_wb_valid,
    output wire [`REG_BUS_WIDTH-1:0]   debug_wb_reg,
    output wire [`DATA_BUS_WIDTH-1:0]   debug_wb_value,
    
    // Fetch PC debug output
    output wire [`ADDR_BUS_WIDTH-1:0]   debug_fetch_pc,

    // EX stage instruction (for debugging)
    output wire [`DATA_BUS_WIDTH-1:0]   debug_exu_inst,

    // WB stage instruction (for debugging)
    output wire [`DATA_BUS_WIDTH-1:0]   debug_wb_instr,

    // Complete instruction tracking (EX stage)
    output reg                          debug_inst_complete_valid,
    output reg [`ADDR_BUS_WIDTH-1:0]   debug_inst_complete_pc,
    output reg [`DATA_BUS_WIDTH-1:0]   debug_inst_complete_instr,

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

// EX stage full instruction (for debugging)
wire [`DATA_BUS_WIDTH-1:0]                  exu_inst;
pa_dff_en_2 #(`DATA_BUS_WIDTH)          dff_exu_inst (clk_i, rst_n_i, exu_flush_flag, {`DATA_BUS_WIDTH{1'b0}}, idu_inst_data, exu_inst);
assign debug_exu_inst = exu_inst;

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

// PRECISE-INT: signals fed to CLINT to enable any-instruction-boundary
// interrupt capture with a correct mepc value.
//
// next_pc_to_clint is the PC of the instruction that should run AFTER the
// one currently in EX. For a taken jump in EX, that is exu_jump_addr; for
// any other inst, EX_PC = ifu_inst_addr - 8, so next_pc = EX_PC + 4 =
// ifu_inst_addr - 4 (i.e. the inst sitting in ID this cycle).
//
// inst_retire_to_clint marks cycles at which the precise-interrupt boundary
// holds: EX has a real (non-flushed) instruction, EX is not stalling for a
// multi-cycle op (mul/div), and no memory transaction is in flight. On such
// a cycle CLINT may safely sample mepc from next_pc_to_clint and start the
// trap entry; the EX-stage writeback (if any) still latches at the next
// posedge before int_hold_flag rises.
wire [`ADDR_BUS_WIDTH-1:0]              next_pc_to_clint;
wire                                    inst_retire_to_clint;

assign next_pc_to_clint = exu_jump_flag ? exu_jump_addr
                                        : (ifu_inst_addr - 32'd4);

assign inst_retire_to_clint = (|exu_inst_func)      // EX has a decoded inst
                           && !exu_hold_flag        // not multi-cycle stall
                           && !mem_en_flag          // no mem fired this cycle
                           && !mem_en_flag_1r;      // no mem in writeback cycle

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
    .hold_flag_i                        (exu_hold_flag || reg_waddr_wb_vld || reg_waddr_wb_vld_1r || mem_en_flag),

    // PRECISE-INT: see clint port descriptions.
    //   next_pc_to_clint = jump target (if EX is jumping)
    //                    | exu_pc + 4   (= ifu_inst_addr - 4, the inst in ID)
    //   inst_retire_to_clint = EX has a real, single-cycle instruction
    //                          completing this cycle and no multi-cycle
    //                          work (mem / div / mul) is in flight.
    .next_pc_i                          (next_pc_to_clint),
    .inst_retire_i                      (inst_retire_to_clint),

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

// FIX H6: include int_hold_flag in EX flush. While CLINT processes a trap
// (int_hold_flag asserted), the EX-stage instruction must be cleared, otherwise
// it keeps re-firing memory accesses, register writebacks, jumps, etc.
assign exu_flush_flag = (jump_flag || jump_flag_1r)
                     || (int_hold_flag || int_hold_flag_1r)
                     || (exu_hold_flag);

pa_dff_rst_0 #(1)                       dff_int_hold_flag_1r (clk_i, rst_n_i, `VALID, int_hold_flag, int_hold_flag_1r);
pa_dff_rst_0 #(1)                       dff_int_hold_flag_2r (clk_i, rst_n_i, `VALID, int_hold_flag_1r, int_hold_flag_2r);

wire [`CSR_BUS_WIDTH-1:0]               csr_waddr;
wire                                    csr_waddr_vld;
wire [`DATA_BUS_WIDTH-1:0]              csr_wdata;

// FIX H1: replace the OR-merge with a mux + gating so EXU CSR writes never
// collide with CLINT trap-entry CSR writes (CLINT takes priority).
assign csr_waddr[`CSR_BUS_WIDTH-1:0] = int_csr_waddr_vld ? int_csr_waddr[`CSR_BUS_WIDTH-1:0]
                                                         : exu_csr_addr[`CSR_BUS_WIDTH-1:0];

assign csr_waddr_vld = int_csr_waddr_vld
                    || (exu_csr_waddr_vld && !int_hold_flag);

assign csr_wdata[`DATA_BUS_WIDTH-1:0] = int_csr_waddr_vld ? int_csr_wdata[`DATA_BUS_WIDTH-1:0]
                                                          : exu_csr_wdata[`DATA_BUS_WIDTH-1:0];

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

assign mem_wdata[`DATA_BUS_WIDTH-1:0] = {{`DATA_BUS_WIDTH}{mem_en_flag}} & exu_reg2_rdata[`DATA_BUS_WIDTH-1:0];
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
// FIX H3: gate dbus_rd/we with !int_hold_flag so an in-flight load/store
// does not keep firing memory transactions while CLINT is taking a trap.
assign dbus_rd_o = mem_en_flag & op_load  & !int_hold_flag;
assign dbus_we_o = mem_en_flag & op_store & !int_hold_flag;

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
// FIX H2: gate register writeback with !int_hold_flag so an in-flight
// instruction (e.g. a load whose result is not yet meaningful) does not
// clobber the architectural register file while CLINT is taking a trap.
// After mret the squashed instruction will re-execute from mepc and write
// the correct value.
assign rtu_reg_waddr_vld                   = !int_hold_flag &&
                                              (mau_mem_data_vld ? (mau_reg_addr_vld && !mem_en_flag) // from memory
                                                                :  reg_waddr_wb_vld); // from exu

assign rtu_reg_wdata[`DATA_BUS_WIDTH-1:0]  = mau_mem_data_vld ?  mau_mem_data[`DATA_BUS_WIDTH-1:0] // from memory, data
                                                              :  iresult[`DATA_BUS_WIDTH-1:0]; // from exu, data

assign rtu_csr_waddr[`CSR_BUS_WIDTH-1:0]   = csr_waddr[`CSR_BUS_WIDTH-1:0];
assign rtu_csr_waddr_vld                   = csr_waddr_vld;

assign rtu_csr_wdata[`DATA_BUS_WIDTH-1:0]  = csr_wdata[`DATA_BUS_WIDTH-1:0];

// Track PC and instruction at writeback stage
// Design: PC and instruction must always be synchronized
// PC tracking: ifu_inst_addr -> wb_pc_1r -> wb_pc_2r -> wb_pc
// Instr tracking: idu_inst_data -> exu_inst -> wb_instr

reg [`ADDR_BUS_WIDTH-1:0]              wb_pc;
reg [`DATA_BUS_WIDTH-1:0]              wb_instr;
reg [`REG_BUS_WIDTH-1:0]               wb_reg;
reg [`DATA_BUS_WIDTH-1:0]              wb_value;
reg                                    wb_valid;

// Pipeline delay registers for PC
reg [`ADDR_BUS_WIDTH-1:0]              wb_pc_1r;
reg [`ADDR_BUS_WIDTH-1:0]              wb_pc_2r;

// Pipeline delay registers for instruction
reg [`DATA_BUS_WIDTH-1:0]              wb_instr_1r;

// Track whether last instruction was flushed
reg                                    last_inst_flushed;

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        wb_pc <= `RESET_PC_ADDR;
        wb_pc_1r <= `RESET_PC_ADDR;
        wb_pc_2r <= `RESET_PC_ADDR;
        wb_instr <= 32'h0;
        wb_instr_1r <= 32'h0;
        wb_reg <= 5'h0;
        wb_value <= 32'h0;
        wb_valid <= 1'b0;
        last_inst_flushed <= 1'b0;
    end else begin
        // Pipeline delay for PC (IF -> ID -> EX -> MEM -> WB)
        wb_pc_1r <= ifu_inst_addr;
        wb_pc_2r <= wb_pc_1r;
        
        // Pipeline delay for instruction (ID -> EX -> MEM -> WB)
        wb_instr_1r <= idu_inst_data;
        wb_instr <= exu_inst;
        
        // Track flush state
        last_inst_flushed <= exu_flush_flag;
        
        // wb_valid is set when any of these conditions are met:
        // 1. Register writeback (rtu_reg_waddr_vld)
        // 2. Memory write (mem_wdata_vld in next cycle via mem_en_flag_1r)
        // 3. PC changed (jump happened) - detected by jump_flag_1r
        // We need to delay the valid signal to match PC/instr pipeline
        
        // For proper PC-instr alignment, we track when the instruction in WB
        // is the same instruction whose PC we're tracking
        // Since wb_pc comes from wb_pc_2r (ifu_inst_addr delayed by 2 cycles),
        // and wb_instr comes from exu_inst (idu_inst_data delayed by 1 cycle),
        // the alignment should be: when rtu_reg_waddr_vld is high,
        // wb_pc and wb_instr both represent the same instruction
        
        wb_valid <= rtu_reg_waddr_vld;
        if (rtu_reg_waddr_vld) begin
            wb_pc <= wb_pc_2r;  // PC delayed by 2 cycles from IF stage
            wb_reg <= rtu_reg_waddr;
            wb_value <= rtu_reg_wdata;
        end
    end
end

// Debug signals for complete instruction tracking
// For each completed instruction, we report:
// - PC: the address where this instruction was fetched
// - Instruction: the actual instruction bits
// - Valid: goes high for ONE CYCLE (pulse) when the instruction completes

reg                                    inst_complete_valid;
reg [`ADDR_BUS_WIDTH-1:0]              inst_complete_pc;
reg [`DATA_BUS_WIDTH-1:0]              inst_complete_instr;

// Internal completion condition
wire                                    inst_complete_cond;

// For branch/jump instructions, we need to report the TARGET PC, not the branch PC
// For non-branch instructions, we report the sequential PC

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        inst_complete_valid <= 1'b0;
        inst_complete_pc <= `RESET_PC_ADDR;
        inst_complete_instr <= 32'h0;
    end else begin
        // Generate a ONE-CYCLE PULSE for completion
        // inst_complete_cond must go high and then low in subsequent cycles
        // even if the original condition stays high
        inst_complete_valid <= inst_complete_cond && !inst_complete_valid;
        
        // Update PC and instruction when condition is detected
        if (inst_complete_cond && !inst_complete_valid) begin
            // For branches that are taken, report the jump target as the PC
            // For all other instructions, report the PC of this instruction
            if (exu_jump_flag) begin
                // Branch/jump taken: report the target PC
                inst_complete_pc <= jump_addr;
                inst_complete_instr <= exu_inst;
            end else begin
                // Non-branch instruction completing: report its PC
                inst_complete_pc <= wb_pc_1r;  // PC delayed by 1 cycle from IF stage
                inst_complete_instr <= exu_inst;
            end
        end
    end
end

// The actual completion condition
assign inst_complete_cond = reg_waddr_wb_vld || mem_wdata_vld || exu_jump_flag;

assign debug_wb_pc = wb_pc;
assign debug_wb_valid = wb_valid;
assign debug_wb_reg = wb_reg;
assign debug_wb_value = wb_value;
assign debug_wb_instr = wb_instr;  // WB stage instruction
assign debug_fetch_pc = ifu_inst_addr;  // Current fetch PC

// New signals for complete instruction tracking - these are reg type outputs
always @(*) begin
    debug_inst_complete_valid = inst_complete_valid;
    debug_inst_complete_pc = inst_complete_pc;
    debug_inst_complete_instr = inst_complete_instr;
end

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

    .csr_rdata_o                        (exu_csr_rdata),

    // Debug outputs
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
