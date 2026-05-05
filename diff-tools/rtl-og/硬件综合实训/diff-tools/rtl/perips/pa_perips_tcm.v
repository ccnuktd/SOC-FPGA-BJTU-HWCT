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

module pa_perips_tcm (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    input  wire [`ADDR_BUS_WIDTH-1:0]   addr1_i,
    input  wire                         rd1_i,
    input  wire                         we1_i,
    input  wire [2:0]                   size1_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   data1_i,
    output wire [`DATA_BUS_WIDTH-1:0]   data1_o,

    input  wire [`ADDR_BUS_WIDTH-1:0]   addr2_i,
    input  wire                         rd2_i,
    output wire [`DATA_BUS_WIDTH-1:0]   data2_o
);


// ============================================================================
// Local RAM (256KB word-addressable)
// ============================================================================

// RAM using word array
reg [31:0] _ram[0:32'h10000-1];  // 256KB / 4 = 64K words

// Temporary buffer for file read (byte-swapped)
reg [31:0] _ram_tmp[0:32'h10000-1];

// Initialize memory from binary file at simulation start
integer i;
integer mem_file;
initial begin
    // Initialize memory to zero
    for (i = 0; i < 32'h10000; i = i + 1) begin
        _ram[i] = 32'h0;
    end
    
    // Open binary file
    mem_file = $fopen("riscv.bin", "rb");
    if (mem_file == 0) begin
        $display("[ERROR] TCM: Open riscv.bin failed!");
        $fatal;
    end
    
    // Read binary file into temp buffer
    // $fread packs bytes into 32-bit words: byte[3] -> [31:24], byte[2] -> [23:16], etc.
    // So file bytes "97 01 01 00" become _ram_tmp[0] = 0x97010100
    $display("[INFO] TCM: Loading riscv.bin ...");
    $fread(_ram_tmp, mem_file);
    $fclose(mem_file);
    
    // Byte swap: convert Verilog's word format to little-endian
    // $fread gives us {byte3, byte2, byte1, byte0}
    // But we want little-endian: {byte0, byte1, byte2, byte3}
    for (i = 0; i < 32'h10000; i = i + 1) begin
        _ram[i] = {_ram_tmp[i][7:0], _ram_tmp[i][15:8], _ram_tmp[i][23:16], _ram_tmp[i][31:24]};
    end
    
    $display("[INFO] TCM: Memory initialized successfully");
end

// ============================================================================
// Data port (port 1) - immediate read/write
// ============================================================================

wire [15:0] index1;
assign index1[15:0] = addr1_i[17:2];

// Write logic
always @(posedge clk_i) begin
    if (we1_i) begin
        case(size1_i[2:1])
            2'b10: begin  // word
                _ram[index1] <= data1_i;
            end
            2'b01: begin  // halfword
                if (addr1_i[1]) begin
                    _ram[index1][31:16] <= data1_i[15:0];
                end else begin
                    _ram[index1][15:0] <= data1_i[15:0];
                end
            end
            2'b00: begin  // byte
                _ram[index1][addr1_i[1:0]*8 +: 8] <= data1_i[7:0];
            end
            default: ;
        endcase
    end
end

// Data port read - immediate (combinational)
assign data1_o = rd1_i ? _ram[index1] : `ZERO_WORD;

// ============================================================================
// Instruction port (port 2) - immediate read
// ============================================================================

wire [15:0] index2;
assign index2[15:0] = addr2_i[17:2];

// Instruction port read - immediate (combinational)
assign data2_o = rd2_i ? _ram[index2] : `ZERO_WORD;

endmodule
