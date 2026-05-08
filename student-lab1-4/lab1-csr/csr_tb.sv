`include "pa_chip_param.v"

module csr_tb;

    // 时钟和复位信号
    reg clk_i;
    reg rst_n_i;

    // 输出信号
    wire [`DATA_BUS_WIDTH-1:0] csr_mtvec_o;
    wire [`DATA_BUS_WIDTH-1:0] csr_mepc_o;
    wire [`DATA_BUS_WIDTH-1:0] csr_mstatus_o;

    // 输入信号
    reg [`CSR_BUS_WIDTH-1:0] csr_raddr_i;
    reg [`CSR_BUS_WIDTH-1:0] csr_waddr_i;
    reg csr_waddr_vld_i;
    reg [`DATA_BUS_WIDTH-1:0] csr_wdata_i;

    // 输出信号
    wire [`DATA_BUS_WIDTH-1:0] csr_rdata_o;

    // 测试统计变量
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    // 辅助任务：检查寄存器值并记录结果
    task check_register;
        input reg [31:0] expected;
        input reg [31:0] actual;
        input integer reg_id;
        
        reg [128:0] reg_names [0:10];
        
        begin
            // 初始化寄存器名称数组
            reg_names[0] = "CYCLE_LOW_INIT";
            reg_names[1] = "CYCLEH_INIT";
            reg_names[2] = "MTVEC";
            reg_names[3] = "MEPC";
            reg_names[4] = "MCAUSE";
            reg_names[5] = "MIE";
            reg_names[6] = "MIP";
            reg_names[7] = "MTVAL";
            reg_names[8] = "MSCRATCH";
            reg_names[9] = "MSCRATCHCSWL";
            reg_names[10] = "MSTATUS";
            
            test_count = test_count + 1;
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("  [PASS] %0s | expected=%h actual=%h", reg_names[reg_id], expected, actual);
            end else begin
                fail_count = fail_count + 1;
                $display("  [FAIL] %0s | expected=%h actual=%h", reg_names[reg_id], expected, actual);
                $display("    Debug: raddr=%h waddr=%h we=%b wdata=%h rdata=%h", csr_raddr_i, csr_waddr_i, csr_waddr_vld_i, csr_wdata_i, csr_rdata_o);
                $display("    Hint : check reset value, write enable timing, CSR address decode, and read mux for this register.");
            end
        end
    endtask

    // 辅助任务：显示测试摘要
    task show_summary;
        begin
            $display("");
            $display("========================================================");
            $display("CSR TEST SUMMARY");
            $display("Total : %0d", test_count);
            $display("Passed: %0d", pass_count);
            $display("Failed: %0d", fail_count);
            $display("========================================================");
            if (fail_count == 0) begin
                $display("[PASS] csr_tb");
            end else begin
                $display("[FAIL] csr_tb errors=%0d", fail_count);
            end
        end
    endtask

    // 实例化CSR模块
    pa_core_csr dut (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .csr_mtvec_o(csr_mtvec_o),
        .csr_mepc_o(csr_mepc_o),
        .csr_mstatus_o(csr_mstatus_o),
        .csr_raddr_i(csr_raddr_i),
        .csr_waddr_i(csr_waddr_i),
        .csr_waddr_vld_i(csr_waddr_vld_i),
        .csr_wdata_i(csr_wdata_i),
        .csr_rdata_o(csr_rdata_o)
    );

    // 时钟生成
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 10ns周期
    end

    // 波形输出
    initial begin
        $dumpfile("csr.vcd");
        $dumpvars(0, csr_tb);
    end

    // 测试过程
    initial begin
        // 初始化
        rst_n_i = 0;
        csr_raddr_i = 0;
        csr_waddr_i = 0;
        csr_waddr_vld_i = 0;
        csr_wdata_i = 0;

        // 复位
        #10 rst_n_i = 1;

        // 等待几个周期
        @(posedge clk_i);
        @(posedge clk_i);

        // ==================== 测试cycle初始值 ====================
        $display("\n========== Test 1: Cycle Register Initial Value ==========");
        csr_raddr_i = `CSR_CYCLE;
        @(posedge clk_i);
        check_register(32'h0000_0002, csr_rdata_o, 0);

        csr_raddr_i = `CSR_CYCLEH;
        @(posedge clk_i);
        check_register(32'h0000_0000, csr_rdata_o, 1);

        // ==================== 测试 MTVEC ====================
        $display("\n========== Test 2: MTVEC Register ==========");
        csr_waddr_i = `CSR_MTVEC;
        csr_waddr_vld_i = 1;
        csr_wdata_i = 32'hAAAA_AAAA;
        @(posedge clk_i);
        csr_waddr_vld_i = 0;

        csr_raddr_i = `CSR_MTVEC;
        @(posedge clk_i);
        check_register(32'hAAAA_AAAA, csr_rdata_o, 2);

        // ==================== 测试 MEPC ====================
        $display("\n========== Test 3: MEPC Register ==========");
        csr_waddr_i = `CSR_MEPC;
        csr_waddr_vld_i = 1;
        csr_wdata_i = 32'h1234_5678;
        @(posedge clk_i);
        csr_waddr_vld_i = 0;

        csr_raddr_i = `CSR_MEPC;
        @(posedge clk_i);
        check_register(32'h1234_5678, csr_rdata_o, 3);

        // ==================== 测试 MCAUSE ====================
        $display("\n========== Test 4: MCAUSE Register ==========");
        csr_waddr_i = `CSR_MCAUSE;
        csr_waddr_vld_i = 1;
        csr_wdata_i = 32'h0000_000B;
        @(posedge clk_i);
        csr_waddr_vld_i = 0;

        csr_raddr_i = `CSR_MCAUSE;
        @(posedge clk_i);
        check_register(32'h0000_000B, csr_rdata_o, 4);

        // ==================== 测试 MIE ====================
        $display("\n========== Test 5: MIE Register ==========");
        csr_waddr_i = `CSR_MIE;
        csr_waddr_vld_i = 1;
        csr_wdata_i = 32'h0000_0888;
        @(posedge clk_i);
        csr_waddr_vld_i = 0;

        csr_raddr_i = `CSR_MIE;
        @(posedge clk_i);
        check_register(32'h0000_0888, csr_rdata_o, 5);

        // ==================== 测试 MIP ====================
        $display("\n========== Test 6: MIP Register ==========");
        csr_waddr_i = `CSR_MIP;
        csr_waddr_vld_i = 1;
        csr_wdata_i = 32'h0000_0444;
        @(posedge clk_i);
        csr_waddr_vld_i = 0;

        csr_raddr_i = `CSR_MIP;
        @(posedge clk_i);
        check_register(32'h0000_0444, csr_rdata_o, 6);

        // ==================== 测试 MTVAL ====================
        $display("\n========== Test 7: MTVAL Register ==========");
        csr_waddr_i = `CSR_MTVAL;
        csr_waddr_vld_i = 1;
        csr_wdata_i = 32'hDEAD_BEEF;
        @(posedge clk_i);
        csr_waddr_vld_i = 0;

        csr_raddr_i = `CSR_MTVAL;
        @(posedge clk_i);
        check_register(32'hDEAD_BEEF, csr_rdata_o, 7);

        // ==================== 测试 MSCRATCH ====================
        $display("\n========== Test 8: MSCRATCH Register ==========");
        csr_waddr_i = `CSR_MSCRATCH;
        csr_waddr_vld_i = 1;
        csr_wdata_i = 32'h5555_5555;
        @(posedge clk_i);
        csr_waddr_vld_i = 0;

        csr_raddr_i = `CSR_MSCRATCH;
        @(posedge clk_i);
        check_register(32'h5555_5555, csr_rdata_o, 8);

        // ==================== 测试 MSCRATCHCSWL ====================
        $display("\n========== Test 9: MSCRATCHCSWL Register ==========");
        csr_waddr_i = `CSR_MSCRATCHCSWL;
        csr_waddr_vld_i = 1;
        csr_wdata_i = 32'h6666_6666;
        @(posedge clk_i);
        csr_waddr_vld_i = 0;

        csr_raddr_i = `CSR_MSCRATCHCSWL;
        @(posedge clk_i);
        check_register(32'h6666_6666, csr_rdata_o, 9);

        // ==================== 测试 MSTATUS ====================
        $display("\n========== Test 10: MSTATUS Register ==========");
        csr_waddr_i = `CSR_MSTATUS;
        csr_waddr_vld_i = 1;
        csr_wdata_i = 32'h0000_0000;
        @(posedge clk_i);
        csr_waddr_vld_i = 0;

        csr_raddr_i = `CSR_MSTATUS;
        @(posedge clk_i);
        check_register(32'h0000_0000, csr_rdata_o, 10);

        // ==================== 完成测试 ====================
        show_summary;
        if (fail_count == 0) begin
            $finish;
        end
        else begin
            $fatal(1);
        end
    end

endmodule
