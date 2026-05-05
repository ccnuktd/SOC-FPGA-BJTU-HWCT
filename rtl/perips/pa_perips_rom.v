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

module pa_perips_rom (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    input  wire [`ADDR_BUS_WIDTH-1:0]   addr_i,
    output wire [`DATA_BUS_WIDTH-1:0]   data_o
);


wire [`ADDR_BUS_WIDTH-1:0]              index;

assign index[`ADDR_BUS_WIDTH-1:0] = {2'b0, 4'b0, addr_i[27:2]};


`ifdef MEMORY_MODEL_REG

// memory size define(KByte)
localparam MEM_SIZE = 32'd32;

reg  [7:0]                              _ram[0:MEM_SIZE*1024-1];

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

blk_rom _rom0 (
    .clka (clk_i),
    .addra (addr_i[14:2]),
    .douta (_data[31:0])
);

`endif // `ifdef MEMORY_MODEL_BRAM


assign data_o[`DATA_BUS_WIDTH-1:0] = _data[`DATA_BUS_WIDTH-1:0];

endmodule
