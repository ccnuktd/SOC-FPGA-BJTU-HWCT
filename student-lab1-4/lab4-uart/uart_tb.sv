`timescale 1ns / 1ps

`include "pa_chip_param.v"

module uart_tb;

    // 时钟和复位
    reg clk_i;
    reg rst_n_i;

    // 总线接口
    reg [7:0] addr_i;
    reg data_rd_i;
    reg data_we_i;
    reg [`DATA_BUS_WIDTH-1:0] data_i;
    wire [`DATA_BUS_WIDTH-1:0] data_o;

    // UART引脚
    reg pad_rxd;
    wire pad_txd;

    // 测试统计变量
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    reg [256*8-1:0] current_case;

    // 实例化UART模块
    pa_perips_uart dut (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .addr_i(addr_i),
        .data_rd_i(data_rd_i),
        .data_we_i(data_we_i),
        .data_i(data_i),
        .data_o(data_o),
        .pad_rxd(pad_rxd),
        .pad_txd(pad_txd)
    );

    // 时钟生成：50MHz
    initial begin
        clk_i = 0;
        forever #10 clk_i = ~clk_i; // 20ns周期
    end

    // 复位
    initial begin
        rst_n_i = 0;
        #100 rst_n_i = 1;
    end

    // 任务：写寄存器
    task write_reg(input [7:0] addr, input [31:0] data);
        begin
            @(posedge clk_i);
            addr_i = addr;
            data_i = data;
            data_we_i = 1;
            data_rd_i = 0;
            @(posedge clk_i);
            data_we_i = 0;
        end
    endtask

    // 任务：读寄存器
    task read_reg(input [7:0] addr, output [31:0] data);
        begin
            @(posedge clk_i);
            addr_i = addr;
            data_rd_i = 1;
            data_we_i = 0;
            @(posedge clk_i);
            #1; // 等待组合逻辑
            data = data_o;
            data_rd_i = 0;
        end
    endtask

    // 任务：发送UART数据（模拟外部设备发送到RXD）
    task send_uart_data(input [7:0] data);
        integer i;
        begin
            // 起始位
            pad_rxd = 0;
            #(8680); // 115200波特率，位周期约8.68us

            // 数据位（LSB first）
            for (i = 0; i < 8; i = i + 1) begin
                pad_rxd = data[i];
                #(8680);
            end

            // 停止位
            pad_rxd = 1;
            #(8680);
        end
    endtask

    // 任务：接收UART数据（从TXD捕获）
    task receive_uart_data(output [7:0] data);
        integer i;
        begin
            // 等待起始位
            wait(pad_txd == 0);
            #(4340); // 半位周期

            // 数据位
            for (i = 0; i < 8; i = i + 1) begin
                #(8680);
                data[i] = pad_txd;
            end

            // 停止位
            #(8680);
        end
    endtask

    // 任务：等待RX完成
    task wait_rx_done;
        reg [31:0] sr;
        begin
            sr = 0;
            while (sr[1] == 0) begin
                read_reg(8'h04, sr); // 读SR
                #1000; // 短延迟
            end
        end
    endtask

    // 辅助任务：检查值并记录结果
    task check_value;
        input [31:0] expected;
        input [31:0] actual;
        
        begin
            test_count = test_count + 1;
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("  [PASS] %0s | expected=%h actual=%h", current_case, expected, actual);
            end else begin
                fail_count = fail_count + 1;
                $display("  [FAIL] %0s | expected=%h actual=%h", current_case, expected, actual);
                $display("    Debug: addr=%h rd=%b we=%b wdata=%h rdata=%h rxd=%b txd=%b", addr_i, data_rd_i, data_we_i, data_i, data_o, pad_rxd, pad_txd);
                $display("    Hint : inspect CR/SR/BAUD/TXD/RXD register behavior and UART bit timing in the waveform.");
            end
        end
    endtask

    // 辅助任务：显示测试摘要
    task show_summary;
        begin
            $display("");
            $display("========================================================");
            $display("UART TEST SUMMARY");
            $display("Total : %0d", test_count);
            $display("Passed: %0d", pass_count);
            $display("Failed: %0d", fail_count);
            $display("========================================================");
            if (fail_count == 0) begin
                $display("[PASS] uart_tb");
            end else begin
                $display("[FAIL] uart_tb errors=%0d", fail_count);
            end
        end
    endtask

    // 测试序列
    reg [31:0] read_data;
    reg [7:0] captured_tx_data;
    reg [7:0] captured_rx_data;
    initial begin
        // 初始化
        addr_i = 0;
        data_rd_i = 0;
        data_we_i = 0;
        data_i = 0;
        pad_rxd = 1; // 默认高电平
        current_case = "initial";

        // 等待复位完成
        #200;

        $display("Starting UART Testbench...");

        // 测试1：检查默认控制寄存器
        $display("\nTest 1: Check default Control Register");
        current_case = "Default Control Register should be 0x00000003";
        read_reg(8'h00, read_data); // 读CR
        check_value(32'h00000003, read_data);

        // 测试2：检查默认状态寄存器
        $display("\nTest 2: Check default Status Register");
        current_case = "Default Status Register should be 0x00000000";
        read_reg(8'h04, read_data); // 读SR
        check_value(32'h00000000, read_data);

        // 测试3：检查波特率寄存器
        $display("\nTest 3: Check Baud Rate Register");
        current_case = "Baud register should be 115200";
        read_reg(8'h08, read_data); // 读BAUD
        check_value(32'd115200, read_data);

        // 测试4：写控制寄存器
        $display("\nTest 4: Write Control Register");
        current_case = "Control Register write/read should keep TX and RX enabled";
        write_reg(8'h00, 32'h00000003); // 启用TX/RX
        read_reg(8'h00, read_data);
        check_value(32'h00000003, read_data);

        // 测试5：发送单个字节并验证TXD
        $display("\nTest 5: Send single byte and verify TXD");
        current_case = "TX should transmit byte 0x41";
        write_reg(8'h10, 32'h00000041); // 写TXD: 'A' (0x41)
        #1000; // 等待一点时间
        receive_uart_data(captured_tx_data);
        check_value(8'h41, captured_tx_data);

        // 等待TX完成
        #100000;

        // 测试6：接收单个字节并验证RXD
        $display("\nTest 6: Receive single byte and verify RXD");
        current_case = "RX should receive byte 0x42";
        fork
            send_uart_data(8'h42); // 发送'B'
            begin
                // 等待接收完成
                #200000;
                read_reg(8'h0c, read_data); // 读RXD
                check_value(8'h42, read_data[7:0]);
            end
        join
        // 清除RX flag
        write_reg(8'h04, 32'h00000002);

        // 测试7：发送多个字节
        $display("\nTest 7: Send multiple bytes");
        current_case = "TX should transmit byte 0x48";
        write_reg(8'h10, 32'h00000048); // 'H'
        #1000;
        receive_uart_data(captured_tx_data);
        check_value(8'h48, captured_tx_data);
        #100000;

        current_case = "TX should transmit byte 0x65";
        write_reg(8'h10, 32'h00000065); // 'e'
        #1000;
        receive_uart_data(captured_tx_data);
        check_value(8'h65, captured_tx_data);
        #100000;

        current_case = "TX should transmit byte 0x6c";
        write_reg(8'h10, 32'h0000006C); // 'l'
        #1000;
        receive_uart_data(captured_tx_data);
        check_value(8'h6C, captured_tx_data);
        #100000;

        current_case = "TX should transmit byte 0x6c again";
        write_reg(8'h10, 32'h0000006C); // 'l'
        #1000;
        receive_uart_data(captured_tx_data);
        check_value(8'h6C, captured_tx_data);
        #100000;

        current_case = "TX should transmit byte 0x6f";
        write_reg(8'h10, 32'h0000006F); // 'o'
        #1000;
        receive_uart_data(captured_tx_data);
        check_value(8'h6F, captured_tx_data);
        #100000;

        // 测试8：接收多个字节
        $display("\nTest 8: Receive multiple bytes");
        // 发送 'W'
        current_case = "RX should receive byte 0x57";
        send_uart_data(8'h57);
        wait_rx_done();
        read_reg(8'h0c, read_data);
        check_value(8'h57, read_data[7:0]);
        // 清除RX flag
        write_reg(8'h04, 32'h00000002);

        // 发送 'o'
        current_case = "RX should receive byte 0x6f";
        send_uart_data(8'h6F);
        wait_rx_done();
        read_reg(8'h0c, read_data);
        check_value(8'h6F, read_data[7:0]);
        write_reg(8'h04, 32'h00000002);

        // 发送 'r'
        current_case = "RX should receive byte 0x72";
        send_uart_data(8'h72);
        wait_rx_done();
        read_reg(8'h0c, read_data);
        check_value(8'h72, read_data[7:0]);
        write_reg(8'h04, 32'h00000002);

        // 发送 'l'
        current_case = "RX should receive byte 0x6c";
        send_uart_data(8'h6C);
        wait_rx_done();
        read_reg(8'h0c, read_data);
        check_value(8'h6C, read_data[7:0]);
        write_reg(8'h04, 32'h00000002);

        // 发送 'e'
        current_case = "RX should receive byte 0x65";
        send_uart_data(8'h65);
        wait_rx_done();
        read_reg(8'h0c, read_data);
        check_value(8'h65, read_data[7:0]);
        // 不清除最后一个RX flag, 让SR[1]=1 for test9

        // 测试9：检查最终状态
        $display("\nTest 9: Check final status");
        current_case = "Final Status Register should show TX and RX ready flags";
        read_reg(8'h04, read_data); // 读SR
        check_value(32'h00000003, read_data);

        // 显示测试摘要
        show_summary();

        // 结束仿真
        #1000;
        if (fail_count == 0) begin
            $finish;
        end
        else begin
            $fatal(1);
        end
    end

    // 生成VCD波形
    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, uart_tb);
    end

endmodule
