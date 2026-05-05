`timescale 1ns / 1ps
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
`include "../rtl/pa_chip_param.v"
`endif

module core_tb(
    );


reg                             sys_clk;
reg                             sys_clk_p;
wire                            sys_clk_n;
reg                             sys_rst_n;

wire                            PAD_A0;
wire                            PAD_A1;

initial begin
`ifdef DUMP_VPD
    $vcdplusfile("wave.vpd");
    $vcdpluson(0, core_tb);
`endif
end

pa_chip_top u_pa_chip_top (
    .clk_p                      (sys_clk_p),
    .clk_n                      (sys_clk_n),
    .rst_n_i                    (sys_rst_n),

    .rxd                        (PAD_A1),
    .txd                        (PAD_A0)
);

core_data_monitor_tb u_core_data_monitor_tb (
    .clk_i                      (sys_clk),
    .rst_n_i                    (sys_rst_n),

    .data_i                     (core_tb.u_pa_chip_top.u_pa_core_top.u_pa_core_rtu.u_pa_core_csr._mscratchcswl) 
);

core_uart_monitor_tb u_core_uart_monitor_tb (
    .clk_i                      (sys_clk),
    .rst_n_i                    (sys_rst_n),

    .rxd                        (PAD_A0),
    .txd                        ()
);

//`ifdef SIM_UART_IAP
core_uart_iap_tb u_core_uart_iap_tb (
    .clk_i                      (sys_clk),
    .rst_n_i                    (sys_rst_n),

    .rxd                        (),
    .txd                        (PAD_A1)
);
//`endif

assign sys_clk_n = ~sys_clk_p;

initial begin
    sys_clk_p = 1;
    sys_rst_n = 0;

`ifdef MEMORY_MODEL_REG
    $readmemh("image.pat", u_pa_chip_top.u_pa_perips_rom._ram);
`endif
`ifdef MEMORY_MODEL_BRAM
    
`endif
end

always begin
    @ (posedge sys_clk_p) sys_rst_n = 0;
    @ (posedge sys_clk_p) sys_rst_n = 1;

    while (1) begin
        @ (posedge sys_clk_p);
    end

    $stop();
end

real half_period;
initial begin
  half_period = 1_000_000_000.0 / `FPGA_FREQ_HZ / 2.0;  // 得到2.5
  forever #(half_period) sys_clk_p = ~sys_clk_p;
end

reg [2:0] clk_div_cnt = 3'd0;   // 3位计数器：可计数到7

always @(posedge sys_clk_p or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        clk_div_cnt <= 3'd0;
        sys_clk     <= 1'b0;
    end else begin
        if (clk_div_cnt == 3'd3) begin
            clk_div_cnt <= 3'd0;
            sys_clk     <= ~sys_clk;  // 每4个上升沿翻转一次，形成8周期方波
        end else begin
            clk_div_cnt <= clk_div_cnt + 1'b1;
        end
    end
end

endmodule
