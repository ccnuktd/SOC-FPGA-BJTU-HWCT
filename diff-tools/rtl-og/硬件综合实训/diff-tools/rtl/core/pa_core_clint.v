/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date             Author      Notes
 * 2021-10-29       Lyons       first version
 * 2022-04-04       Lyons       v2.0
 * 2023-06-14       Lyons       v3.0
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

module pa_core_clint (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    input  wire                         inst_set_i,  // indicate instruction set, [0], only support rv32i yet
    input  wire [2:0]                   inst_func_i, // indicate instruction func, [6:4], only 3-bits

    input  wire [`ADDR_BUS_WIDTH-1:0]   pc_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   inst_i,

    input  wire [`DATA_BUS_WIDTH-1:0]   csr_mtvec_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   csr_mepc_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   csr_mstatus_i,

    input  wire                         irq_i,

    input  wire                         jump_flag_i,
    input  wire                         hold_flag_i,

    output wire [`CSR_BUS_WIDTH-1:0]    csr_waddr_o,
    output wire                         csr_waddr_vld_o,
    output wire [`DATA_BUS_WIDTH-1:0]   csr_wdata_o,

    output wire                         hold_flag_o,

    output wire                         jump_flag_o,
    output wire [`DATA_BUS_WIDTH-1:0]   jump_addr_o
);


// value of 'int_state'

localparam INT_STATE_IDLE               = 2'd0;
localparam INT_STATE_MCALL              = 2'd1;
localparam INT_STATE_MRET               = 2'd2;

// value of 'int_type'

localparam INT_TYPE_NONE                = 2'b00;
localparam INT_TYPE_EXCEPTION           = 2'b01;
localparam INT_TYPE_INTERRUPT           = 2'b10;

// value of 'csr_state'

localparam CSR_STATE_IDLE               = 3'd0;
localparam CSR_STATE_WAIT               = 3'd1;
localparam CSR_STATE_MEPC               = 3'd2;
localparam CSR_STATE_MSTATUS            = 3'd3;
localparam CSR_STATE_MCAUSE             = 3'd4;
localparam CSR_STATE_MRET               = 3'd5;


reg  [1:0]                              int_state;
reg  [1:0]                              int_type;

reg  [2:0]                              csr_state;

wire                                    inst_set_rvi;

assign inst_set_rvi  = inst_set_i;

wire                                    global_int_en;
wire                                    global_int_si;

assign global_int_en = csr_mstatus_i[3];  // MIE

// 'op_xxx' is equal to zero when it is Non-ecall/ebreak/mret inst

wire                                    op_ecall;
wire                                    op_ebreak;
wire                                    op_mret;

assign op_ecall  = inst_set_rvi && inst_func_i[2]; // to inst_func_i[6]
assign op_ebreak = inst_set_rvi && inst_func_i[1]; // to inst_func_i[5]
assign op_mret   = inst_set_rvi && inst_func_i[0]; // to inst_func_i[4]

wire [1:0]                                  irq_1r;
pa_dff_rst_0 #(2)                       dff_irq_1r (clk_i, rst_n_i, `VALID, {irq_1r[0], irq_i}, irq_1r);

// 'irq_vld' is valid during the csr-handle cycle

wire                                    irq_vld;
reg                                     irq_vld_t;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        irq_vld_t <= `INVALID;
    end
    else begin
        if (int_state == INT_STATE_IDLE) begin
            irq_vld_t <= `INVALID;
        end
        else begin
            irq_vld_t <= irq_vld;
        end
    end
end

assign irq_vld = (irq_vld_t)
              || (~irq_1r[1] && irq_1r[0]); // posedge of irq_i

always @ (*) begin
    if (!rst_n_i) begin
        int_state <= INT_STATE_IDLE;
        int_type  <= INT_TYPE_NONE;
    end
    else begin
        if (op_mret) begin
            int_state = INT_STATE_MRET;
            int_type  = INT_TYPE_EXCEPTION;
        end
        else if (op_ecall || op_ebreak) begin
            int_state = INT_STATE_MCALL;
            int_type  = INT_TYPE_EXCEPTION;
        end
        else if (global_int_en && irq_vld) begin
            int_state = INT_STATE_MCALL;
            int_type  = INT_TYPE_INTERRUPT;
        end
        else begin
            int_state = INT_STATE_IDLE;
            int_type  = INT_TYPE_NONE;
        end
    end
end

wire [`DATA_BUS_WIDTH-1:0]              exception_addr;
wire [`DATA_BUS_WIDTH-1:0]              interrupt_addr;

assign exception_addr[`DATA_BUS_WIDTH-1:0] = pc_i[`DATA_BUS_WIDTH-1:0] + 32'hffff_fff8; // -8
assign interrupt_addr[`DATA_BUS_WIDTH-1:0] = pc_i[`DATA_BUS_WIDTH-1:0] + 32'hffff_fffc; // -4

wire [`DATA_BUS_WIDTH-1:0]              break_addr_soft;
wire [`DATA_BUS_WIDTH-1:0]              break_addr_ext;

assign break_addr_soft[`DATA_BUS_WIDTH-1:0]  = {32{int_type[0] &  op_ecall   }} & exception_addr
                                             | {32{int_type[0] &  op_ebreak  }} & exception_addr;

assign break_addr_ext[`DATA_BUS_WIDTH-1:0]   = {32{int_type[1] & ~int_type[0] }} & interrupt_addr;

wire [`DATA_BUS_WIDTH-1:0]              break_cause_soft;
wire [`DATA_BUS_WIDTH-1:0]              break_cause_ext;

assign break_cause_soft[`DATA_BUS_WIDTH-1:0] = {32{int_type[0] &  op_ecall   }} & 32'd11
                                             | {32{int_type[0] &  op_ebreak  }} & 32'd3;

wire [`DATA_BUS_WIDTH-1:0]                  break_addr_soft_1r;
pa_dff_en_2 #(`DATA_BUS_WIDTH)          dff_break_addr_soft (clk_i, rst_n_i,
                                                            (int_state == INT_STATE_MCALL || csr_state != CSR_STATE_IDLE) && !jump_flag_i && !hold_flag_i,
                                                             break_addr_soft, {`DATA_BUS_WIDTH{1'b0}},
                                                             break_addr_soft_1r);

assign break_cause_ext[`DATA_BUS_WIDTH-1:0]  = {32{int_type[1] & ~int_type[0]}} & 32'h8000_0003;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        csr_state   <= CSR_STATE_IDLE;
    end
    else begin
    case (csr_state)
        CSR_STATE_IDLE    ,
        CSR_STATE_WAIT    : begin
        case (int_state)
            INT_STATE_MCALL : begin
                if (jump_flag_i || hold_flag_i) begin
                    csr_state <= CSR_STATE_WAIT;
                end
                else begin
                    csr_state <= CSR_STATE_MEPC;
                end
            end
            INT_STATE_MRET  : begin
                csr_state <= CSR_STATE_MRET;
            end
        endcase
        end

        CSR_STATE_MEPC    : csr_state <= (jump_flag_i ? CSR_STATE_MEPC : CSR_STATE_MSTATUS);
        CSR_STATE_MSTATUS : csr_state <= CSR_STATE_MCAUSE;
        CSR_STATE_MCAUSE  : csr_state <= CSR_STATE_IDLE;

        CSR_STATE_MRET    : csr_state <= CSR_STATE_IDLE;

        default : begin
            csr_state <= CSR_STATE_IDLE;
        end
    endcase
    end
end

wire [`DATA_BUS_WIDTH-1:0]                  break_cause;
pa_dff_en_2 #(`DATA_BUS_WIDTH)          dff_break_cause (clk_i, rst_n_i,
                                                            (int_state == INT_STATE_MCALL || csr_state != CSR_STATE_IDLE) && !jump_flag_i && !hold_flag_i,
                                                            (break_cause_soft | break_cause_ext | break_cause), {`DATA_BUS_WIDTH{1'b0}},
                                                             break_cause);

reg  [`CSR_BUS_WIDTH-1:0]               csr_waddr;
reg                                     csr_waddr_vld;
reg  [`DATA_BUS_WIDTH-1:0]              csr_wdata;

always @ (*) begin
case (csr_state)
    CSR_STATE_MEPC    : begin
        csr_waddr     = {20'h0, `CSR_MEPC};
        csr_waddr_vld = `VALID;
        csr_wdata     = break_addr_soft_1r
                       | break_addr_ext;
    end

    CSR_STATE_MSTATUS : begin
        csr_waddr     = {20'h0, `CSR_MSTATUS};
        csr_waddr_vld = `VALID;
        csr_wdata     = {csr_mstatus_i[31:8], csr_mstatus_i[3], csr_mstatus_i[6:4], 1'b0, csr_mstatus_i[2:0]};
    end

    CSR_STATE_MCAUSE  : begin
        csr_waddr     = {20'h0, `CSR_MCAUSE};
        csr_waddr_vld = `VALID;
        csr_wdata     = break_cause;
    end

    CSR_STATE_MRET    : begin
        csr_waddr     = {20'h0, `CSR_MSTATUS};
        csr_waddr_vld = `VALID;
        csr_wdata     = {csr_mstatus_i[31:8], 1'b0, csr_mstatus_i[6:4], csr_mstatus_i[7], csr_mstatus_i[2:0]};
    end

    default : begin
        csr_waddr     = `ZERO_WORD;
        csr_waddr_vld = `INVALID;
        csr_wdata     = `ZERO_WORD;
    end
endcase
end

wire [`DATA_BUS_WIDTH-1:0]              csr_mtvec;
wire [`DATA_BUS_WIDTH-1:0]              csr_mepc;

assign csr_mtvec[`DATA_BUS_WIDTH-1:0] =  csr_mtvec_i[`DATA_BUS_WIDTH-1:0];

assign csr_mepc[`DATA_BUS_WIDTH-1:0]  = csr_mepc_i[`DATA_BUS_WIDTH-1:0];

reg                                     int_jump_flag;
reg  [`DATA_BUS_WIDTH-1:0]              int_jump_addr;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        int_jump_flag <= `INVALID;
        int_jump_addr <= `ZERO_WORD;
    end
    else begin
    case (csr_state)
        CSR_STATE_MCAUSE : begin
            int_jump_flag <= `VALID;
            int_jump_addr <= csr_mtvec;
        end
        CSR_STATE_MRET   : begin
            int_jump_flag <= `VALID;
            int_jump_addr <= csr_mepc;
        end
        default : begin
            int_jump_flag <= `INVALID;
            int_jump_addr <= `ZERO_WORD;
        end
    endcase
    end
end

assign csr_waddr_o[`CSR_BUS_WIDTH-1:0]  = csr_waddr[`CSR_BUS_WIDTH-1:0];
assign csr_waddr_vld_o = csr_waddr_vld;
assign csr_wdata_o[`DATA_BUS_WIDTH-1:0] = csr_wdata[`DATA_BUS_WIDTH-1:0];

assign hold_flag_o = csr_state != CSR_STATE_IDLE;

assign jump_flag_o = int_jump_flag;
assign jump_addr_o[`DATA_BUS_WIDTH-1:0] = int_jump_addr[`DATA_BUS_WIDTH-1:0];

endmodule
