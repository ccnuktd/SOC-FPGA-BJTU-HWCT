`timescale 1ns / 1ps
/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2023-06-19     Lyons        first version
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../rtl/pa_chip_param.v"
`endif

module core_data_monitor_tb (
    input  wire                 clk_i,
    input  wire                 rst_n_i,

    input  wire [31:0]          data_i 
);


reg  [7:0]                      csr_rx_data;

always @ (posedge data_i[31]) begin
    csr_rx_data[7:0] <= data_i[7:0];
end

reg  [7:0]                      data_buffer [0:127];
reg  [7:0]                      data_length;

integer                         i;

reg                             debug_mode;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        data_length <= 0;
        debug_mode <= 0;
    end
    else if (debug_mode || (csr_rx_data == 8'h1b)) begin
        if (csr_rx_data == 8'h1b) begin
            debug_mode <= 1;
        end
        else if (debug_mode) begin
            if (csr_rx_data == 8'h04) begin
                $write("[%10d] DEBG: SIMULATION END.\n", $time);
                $finish();
            end
            if (csr_rx_data != 8'hff) begin // 0xff is default rx value
                debug_mode <= 0;
            end
        end
    end
    else if (csr_rx_data == 8'h0a) begin
        $write("[%10d] UART: ", $time);
        for (i=0; i<data_length; i=i+1) begin
            $write("%s", data_buffer[i]);
        end
        $write("\n");

        data_length <= 0;
    end
    else if (csr_rx_data == 8'h0d) begin
        // '\r' is no used under simulation.
    end
    else if (csr_rx_data != 8'hff) begin
        data_buffer[data_length] <= csr_rx_data;
        data_length <= data_length + 1;

        if (data_length == 8'd128) begin
            $write("UART: ");
            for (i=0; i<data_length; i=i+1) begin
                $write("%s", data_buffer[i]);
            end
            $write("\n");

            data_length <= 0;
        end
    end

    csr_rx_data <= 8'hff;
end

endmodule
