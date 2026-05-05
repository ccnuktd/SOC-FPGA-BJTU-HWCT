`timescale 1ns / 1ps
/*
 * Copyright (c) 2020-2021, SERI Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2023-06-18     Lyons        first version
 */

`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../rtl/pa_chip_param.v"
`endif

module core_uart_iap_tb (
    input  wire                 clk_i,
    input  wire                 rst_n_i,

    input  wire                 rxd,
    output wire                 txd
);


`define UART_BAUD               (32'd115200) // fixed!

`define UART_TX_WAIT_CYCLE      (64'd50_000)
`define UART_TX_BYTE_CYCLE      (8'd10 + 8'd16)

integer                         fd;
reg  [7:0]                      data [0:1];

initial begin
    fd = $fopen("./iap.data", "r");
end

reg  [63:0]                     uart_tx_clk_wait_cycle;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        uart_tx_clk_wait_cycle <= 0;
    end
    else if (uart_tx_clk_wait_cycle >= `UART_TX_WAIT_CYCLE) begin
        uart_tx_clk_wait_cycle <= uart_tx_clk_wait_cycle;
    end
    else begin
        uart_tx_clk_wait_cycle <= uart_tx_clk_wait_cycle + 1;
    end
end

wire [31:0]                     uart_tx_clk_cycle;

reg  [31:0]                     uart_tx_clk_cnt;

wire                            uart_tx_clk_timeup;

assign uart_tx_clk_cycle[31:0] = (`XTAL_FREQ_HZ) / `UART_BAUD  / 2;

assign uart_tx_clk_timeup = (uart_tx_clk_cnt == uart_tx_clk_cycle[30:0]);

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        uart_tx_clk_cnt <= 0;
    end
    else if (uart_tx_clk_wait_cycle < `UART_TX_WAIT_CYCLE) begin
        uart_tx_clk_cnt <= 0;
    end
    else if (uart_tx_clk_timeup) begin
        uart_tx_clk_cnt <= 0;
    end
    else begin
        uart_tx_clk_cnt <= uart_tx_clk_cnt + 1;
    end
end

reg  [7:0]                      uart_tx_cnt;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        uart_tx_cnt[7:0] <= 4'b0;
    end
    else if (`UART_TX_BYTE_CYCLE == uart_tx_cnt[7:0]) begin
        uart_tx_cnt[7:0] <= 8'b0;
    end
    else if (uart_tx_clk_timeup) begin
        uart_tx_cnt[7:0] <= uart_tx_cnt[7:0] + 8'h1;
    end
end

// stop=1 datah...datal start=0

reg  [19:0]                      uart_tx_pipe;

always @ (posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        uart_tx_pipe[9:0] <= 20'hfffff;
    end
    else if (`UART_TX_BYTE_CYCLE == uart_tx_cnt[7:0]) begin
        data[0] = $fgetc(fd);
        data[1] = $fgetc(fd);
        
        if ( ($signed(data[0]) != -1) && ($signed(data[1]) != -1) ) begin
            uart_tx_pipe[9]   = 1'b1;
            uart_tx_pipe[8:1] = data[0];
            uart_tx_pipe[0]   = 1'b0;
            uart_tx_pipe[19]   = 1'b1;
            uart_tx_pipe[18:11] = data[1];
            uart_tx_pipe[10]   = 1'b0;
        end
        else begin
            uart_tx_pipe[19:0] = 20'hfffff;
        end
    end
    else if (uart_tx_clk_timeup) begin
        uart_tx_pipe[19:0] <= {1'b1, uart_tx_pipe[19:1]};
    end
end

assign txd = uart_tx_pipe[0];

endmodule
