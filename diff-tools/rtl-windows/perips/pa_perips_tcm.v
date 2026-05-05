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


wire [`ADDR_BUS_WIDTH-1:0]              index1;
wire [`ADDR_BUS_WIDTH-1:0]              index2;

assign index1[`ADDR_BUS_WIDTH-1:0] = {2'b0, 4'b0, addr1_i[27:2]};
assign index2[`ADDR_BUS_WIDTH-1:0] = {2'b0, 4'b0, addr2_i[27:2]};

reg  [3:0]                              addr_mask;

wire                                    size_word;
wire                                    size_half;

assign size_word = size1_i[2];
assign size_half = size1_i[1];

always @ (*) begin
case (addr1_i[1:0])
    2'b00 : addr_mask[3:0] <= {size_word, size_word, (size_word || size_half), 1'b1};
    2'b01 : addr_mask[3:0] <= {4'b0010};
    2'b10 : addr_mask[3:0] <= {size_half, 3'b100};
    2'b11 : addr_mask[3:0] <= {4'b1000};
endcase
end


// `ifdef MEMORY_MODEL_REG

// // memory size define(KByte)
// localparam MEM_SIZE = 32'd64;

// reg  [7:0]                              _ram[0:MEM_SIZE*1024-1];

// wire [7:0]                              byte0;
// wire [7:0]                              byte1;
// wire [7:0]                              byte2;
// wire [7:0]                              byte3;

// assign byte0[7:0] = addr_mask[0] ? data1_i[ 7: 0] : _ram[index1*4+0][7:0];
// assign byte1[7:0] = addr_mask[1] ? data1_i[15: 8] : _ram[index1*4+1][7:0];
// assign byte2[7:0] = addr_mask[2] ? data1_i[23:16] : _ram[index1*4+2][7:0];
// assign byte3[7:0] = addr_mask[3] ? data1_i[31:24] : _ram[index1*4+3][7:0];

// always @ (posedge clk_i) begin
//     if (we1_i) begin
//         _ram[index1*4+0] <= byte0[7:0];
//         _ram[index1*4+1] <= byte1[7:0];
//         _ram[index1*4+2] <= byte2[7:0];
//         _ram[index1*4+3] <= byte3[7:0];
//     end
// end

// reg  [`DATA_BUS_WIDTH-1:0]              _data1;
// reg  [`DATA_BUS_WIDTH-1:0]              _data2;

// always @ (posedge clk_i or negedge rst_n_i) begin
//     if (!rst_n_i) begin
//         _data1[`DATA_BUS_WIDTH-1:0] = `ZERO_WORD;
//     end
//     else if (rd1_i) begin
//         _data1[`DATA_BUS_WIDTH-1:0] = {_ram[index1*4+3], _ram[index1*4+2], _ram[index1*4+1], _ram[index1*4+0]};
//     end
// end

// always @ (posedge clk_i or negedge rst_n_i) begin
//     if (!rst_n_i) begin
//         _data2[`DATA_BUS_WIDTH-1:0] = `ZERO_WORD;
//     end
//     else if (rd2_i) begin
//         _data2[`DATA_BUS_WIDTH-1:0] = {_ram[index2*4+3], _ram[index2*4+2], _ram[index2*4+1], _ram[index2*4+0]};
//     end
// end

// `endif // `ifdef MEMORY_MODEL_REG


// `ifdef MEMORY_MODEL_BRAM

wire [`DATA_BUS_WIDTH-1:0]              _data1;
wire [`DATA_BUS_WIDTH-1:0]              _data2;

blk_mem_gen_0 _ram0 (
    .clka (clk_i),
    .wea ({4{we1_i}} & addr_mask[3:0]),
    .addra (addr1_i[17:2]),
    .dina (data1_i[31:0]),
    .douta (_data1[31:0]),
    .clkb (clk_i),
    .web (4'b0),
    .addrb (addr2_i[17:2]),
    .dinb (32'b0),
    .doutb (_data2[31:0])
);

// `endif // `ifdef MEMORY_MODEL_BRAM


assign data1_o[`DATA_BUS_WIDTH-1:0] = _data1[`DATA_BUS_WIDTH-1:0];
assign data2_o[`DATA_BUS_WIDTH-1:0] = _data2[`DATA_BUS_WIDTH-1:0];

endmodule
