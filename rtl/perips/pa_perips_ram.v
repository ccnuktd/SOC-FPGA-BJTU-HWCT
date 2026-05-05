/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date             Author      Notes
 * 2025-05-25       ketted      first version
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

module pa_perips_ram (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    input  wire [`ADDR_BUS_WIDTH-1:0]   addr_i,
    input  wire                         rd_i,
    input  wire                         we_i,
    input  wire [2:0]                   size_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   data_i,
    output wire [`DATA_BUS_WIDTH-1:0]   data_o
);


wire [`ADDR_BUS_WIDTH-1:0]              index;

assign index[`ADDR_BUS_WIDTH-1:0] = {2'b0, 4'b0, addr_i[27:2]};

reg  [3:0]                              addr_mask;

wire                                    size_word;
wire                                    size_half;

assign size_word = size_i[2];
assign size_half = size_i[1];

always @ (*) begin
case (addr_i[1:0])
    2'b00 : addr_mask[3:0] <= {size_word, size_word, (size_word || size_half), 1'b1};
    2'b01 : addr_mask[3:0] <= {4'b0010};
    2'b10 : addr_mask[3:0] <= {size_half, 3'b100};
    2'b11 : addr_mask[3:0] <= {4'b1000};
endcase
end


`ifdef MEMORY_MODEL_REG

// memory size define(KByte)
localparam MEM_SIZE = 32'd32;

reg  [7:0]                              _ram[0:MEM_SIZE*1024-1];

wire [7:0]                              byte0;
wire [7:0]                              byte1;
wire [7:0]                              byte2;
wire [7:0]                              byte3;

assign byte0[7:0] = addr_mask[0] ? data_i[ 7: 0] : _ram[index*4+0][7:0];
assign byte1[7:0] = addr_mask[1] ? data_i[15: 8] : _ram[index*4+1][7:0];
assign byte2[7:0] = addr_mask[2] ? data_i[23:16] : _ram[index*4+2][7:0];
assign byte3[7:0] = addr_mask[3] ? data_i[31:24] : _ram[index*4+3][7:0];

always @ (posedge clk_i) begin
    if (we_i) begin
        _ram[index*4+0] <= byte0[7:0];
        _ram[index*4+1] <= byte1[7:0];
        _ram[index*4+2] <= byte2[7:0];
        _ram[index*4+3] <= byte3[7:0];
    end
end

reg  [`DATA_BUS_WIDTH-1:0]              _data;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        _data[`DATA_BUS_WIDTH-1:0] = `ZERO_WORD;
    end
    else if (rd_i) begin
        _data[`DATA_BUS_WIDTH-1:0] = {_ram[index*4+3], _ram[index*4+2], _ram[index*4+1], _ram[index*4+0]};
    end
end



`endif // `ifdef MEMORY_MODEL_REG


`ifdef MEMORY_MODEL_BRAM

wire [`DATA_BUS_WIDTH-1:0]              _data;

blk_ram _ram0 (
    .clka (clk_i),
    .wea ({4{we_i}} & addr_mask[3:0]),
    .addra (addr_i[14:2]),
    .dina (data_i[31:0]),
    .douta (_data[31:0])
);

`endif // `ifdef MEMORY_MODEL_BRAM


assign data_o[`DATA_BUS_WIDTH-1:0] = _data[`DATA_BUS_WIDTH-1:0];

endmodule
