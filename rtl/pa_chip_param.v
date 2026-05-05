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

// memory model define(only choose one)
//`define MEMORY_MODEL_REG
`define MEMORY_MODEL_BRAM

`define FPGA_FREQ_HZ            32'd200_000_000

// xtal cpu clock freq*2 define(cpu clock may be divided)
`define XTAL_FREQ_HZ            32'd50_000_000

// bus width
`define ADDR_BUS_WIDTH          8'd32
`define DATA_BUS_WIDTH          8'd32
`define REG_BUS_WIDTH           8'd5
`define CSR_BUS_WIDTH           8'd12

// data width(bit)
`define INT_WIDTH               8'd32

// cpu reset pc address
`define RESET_PC_ADDR           32'h8000_0000

// instruct data define
`define INST_DATA_NOP           32'h0000_0000

// default data define
`define ZERO_WORD               32'h0000_0000

// valid signal value define
`define VALID                   1'b1
`define INVALID                 1'b0

// pin level define
`define LEVEL_HIGH              1'b1
`define LEVEL_LOW               1'b0

// csr register address define
`define CSR_NULL                12'h000
`define CSR_MTVEC               12'h305
`define CSR_MEPC                12'h341
`define CSR_MCAUSE              12'h342
`define CSR_MIE                 12'h304
`define CSR_MIP                 12'h344
`define CSR_MTVAL               12'h343
`define CSR_MSCRATCH            12'h340
`define CSR_MSCRATCHCSWL        12'h349
`define CSR_MSTATUS             12'h300
`define CSR_CYCLEH              12'hc80
`define CSR_CYCLE               12'hc00

// instruc define
`define INST_SET_WIDTH          8'd8
`define INST_SET_NULL           8'b0000_0000
`define INST_SET_RV32I          8'b0000_0001
`define INST_SET_RV32M          8'b0000_0010
`define INST_SET_RV32FD         8'b0000_0000

`define INST_TYPE_WIDTH         8'd8
`define INST_TYPE_NULL          8'b0000_0000
`define INST_TYPE_CSR           8'b0000_0001
`define INST_TYPE_R             8'b0000_0010
`define INST_TYPE_I             8'b0000_0100
`define INST_TYPE_S             8'b0000_1000
`define INST_TYPE_B             8'b0001_0000
`define INST_TYPE_U             8'b0010_0000
`define INST_TYPE_J             8'b0100_0000

`define INST_FUNC_WIDTH         8'd32
`define INST_FUNC_NULL          32'b0_0_00_0000_0000_0000_0000_0000_0000_0000

`define INST_FUNC_ADD           32'b0_0_00_0000_1000_0000_0000_0000_0000_0000
`define INST_FUNC_SUB           32'b0_0_00_0000_0100_0000_0000_0000_0000_0000
`define INST_FUNC_SLL           32'b0_0_00_0000_0010_0000_0000_0000_0000_0000
`define INST_FUNC_SRL           32'b0_0_00_0000_0001_0000_0000_0000_0000_0000
`define INST_FUNC_SRA           32'b0_0_00_0000_0000_1000_0000_0000_0000_0000
`define INST_FUNC_OR            32'b0_0_00_0000_0000_0100_0000_0000_0000_0000
`define INST_FUNC_AND           32'b0_0_00_0000_0000_0010_0000_0000_0000_0000
`define INST_FUNC_XOR           32'b0_0_00_0000_0000_0001_0000_0000_0000_0000
`define INST_FUNC_SLT           32'b0_0_00_0000_0000_0000_1000_0000_0000_0000
`define INST_FUNC_LOAD          32'b0_0_00_0000_0000_0000_0100_0000_0000_0000
`define INST_FUNC_STORE         32'b0_0_00_0000_0000_0000_0010_0000_0000_0000
`define INST_FUNC_FENCE         32'b0_0_00_0000_0000_0000_0001_0000_0000_0000
`define INST_FUNC_B             32'b0_0_00_0000_0000_0000_0000_1000_0000_0000
`define INST_FUNC_JAL           32'b0_0_00_0000_0000_0000_0000_0100_0000_0000
`define INST_FUNC_JALR          32'b0_0_00_0000_0000_0000_0000_0010_0000_0000
`define INST_FUNC_AUIPC         32'b0_0_00_0000_0000_0000_0000_0001_0000_0000
`define INST_FUNC_LUI           32'b0_0_00_0000_0000_0000_0000_0000_1000_0000
`define INST_FUNC_ECALL         32'b0_0_00_0000_0000_0000_0000_0000_0100_0000
`define INST_FUNC_EBREAK        32'b0_0_00_0000_0000_0000_0000_0000_0010_0000
`define INST_FUNC_MRET          32'b0_0_00_0000_0000_0000_0000_0000_0001_0000
`define INST_FUNC_WFI           32'b0_0_00_0000_0000_0000_0000_0000_0000_1000
`define INST_FUNC_CSRRW         32'b0_0_00_0000_0000_0000_0000_0000_0000_0100
`define INST_FUNC_CSRRS         32'b0_0_00_0000_0000_0000_0000_0000_0000_0010
`define INST_FUNC_CSRRC         32'b0_0_00_0000_0000_0000_0000_0000_0000_0001

`define INST_FUNC_MUL           32'b0_0_00_0000_1000_0000_0000_0000_0000_0000
`define INST_FUNC_DIV           32'b0_0_00_0000_0100_0000_0000_0000_0000_0000
`define INST_FUNC_REM           32'b0_0_00_0000_0010_0000_0000_0000_0000_0000

`define INST_FUNC_SUFFIX_UNSIGN 32'b1_0_00_0000_0000_0000_0000_0000_0000_0000

`define INST_FUNC_SUFFIX_IMM    32'b0_1_00_0000_0000_0000_0000_0000_0000_0000

`define INST_FUNC_SUFFIX_HIGH   32'b0_1_00_0000_0000_0000_0000_0000_0000_0000

`define INST_FUNC_SUFFIX_BYTE   32'b0_0_01_0000_0000_0000_0000_0000_0000_0000
`define INST_FUNC_SUFFIX_HALF   32'b0_0_10_0000_0000_0000_0000_0000_0000_0000

`define INST_FUNC_SUFFIX_U1     32'b1_0_01_0000_0000_0000_0000_0000_0000_0000
`define INST_FUNC_SUFFIX_U2     32'b1_0_10_0000_0000_0000_0000_0000_0000_0000

`define INST_FUNC_SUFFIX_EQ     32'b0_0_00_1000_0000_0000_0000_0000_0000_0000
`define INST_FUNC_SUFFIX_NE     32'b0_0_00_0100_0000_0000_0000_0000_0000_0000
`define INST_FUNC_SUFFIX_LT     32'b0_0_00_0010_0000_0000_0000_0000_0000_0000
`define INST_FUNC_SUFFIX_GT     32'b0_0_00_0001_0000_0000_0000_0000_0000_0000

`define INST_LB                 3'b000
`define INST_LH                 3'b001
`define INST_LW                 3'b010
`define INST_LBU                3'b100
`define INST_LHU                3'b101

`define INST_FENCE              3'b000
`define INST_FENCEI             3'b001

`define INST_ADD                3'b000 // INST_SUB
`define INST_SLL                3'b001
`define INST_SLT                3'b010
`define INST_SLTU               3'b011
`define INST_XOR                3'b100
`define INST_SRL                3'b101 // INST_SRA
`define INST_OR                 3'b110
`define INST_AND                3'b111

`define INST_SB                 3'b000
`define INST_SH                 3'b001
`define INST_SW                 3'b010

`define INST_BEQ                3'b000
`define INST_BNE                3'b001
`define INST_BLT                3'b100
`define INST_BGE                3'b101
`define INST_BLTU               3'b110
`define INST_BGEU               3'b111

`define INST_ECALL              3'b000 // INST_EBREAK INST_EBREAK INST_MRET INST_WFI
`define INST_CSRRW              3'b001
`define INST_CSRRS              3'b010
`define INST_CSRRC              3'b011
`define INST_CSRRWI             3'b101
`define INST_CSRRSI             3'b110
`define INST_CSRRCI             3'b111

`define INST_MUL                3'b000
`define INST_MULH               3'b001
`define INST_MULHSU             3'b010
`define INST_MULHU              3'b011
`define INST_DIV                3'b100
`define INST_DIVU               3'b101
`define INST_REM                3'b110
`define INST_REMU               3'b111
