`include "pa_chip_param.v"

module timer_tb;

localparam TIMER_CR    = 8'h00;
localparam TIMER_SR    = 8'h04;
localparam TIMER_PSC   = 8'h08;
localparam TIMER_LOAD  = 8'h0c;
localparam TIMER_COUNT = 8'h10;

reg clk_i;
reg rst_n_i;

reg [7:0] addr_i;
reg data_rd_i;
reg data_we_i;
reg [`DATA_BUS_WIDTH-1:0] data_i;
wire [`DATA_BUS_WIDTH-1:0] data_o;
wire irq_o;

integer test_count;
integer pass_count;
integer fail_count;
integer actual_cycles;
reg [31:0] read_data;

pa_perips_timer dut (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),
    .addr_i(addr_i),
    .data_rd_i(data_rd_i),
    .data_we_i(data_we_i),
    .data_i(data_i),
    .data_o(data_o),
    .irq_o(irq_o)
);

initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
end

initial begin
    $dumpfile("timer.vcd");
    $dumpvars(0, timer_tb);
end

task cycle;
    begin
        @(posedge clk_i);
        #1;
    end
endtask

task write_reg;
    input [7:0] addr;
    input [31:0] data;
    begin
        addr_i = addr;
        data_i = data;
        data_we_i = 1'b1;
        data_rd_i = 1'b0;
        cycle();
        data_we_i = 1'b0;
        data_i = `ZERO_WORD;
    end
endtask

task read_reg;
    input [7:0] addr;
    output [31:0] data;
    begin
        addr_i = addr;
        data_rd_i = 1'b1;
        data_we_i = 1'b0;
        cycle();
        data = data_o;
        data_rd_i = 1'b0;
    end
endtask

task check_value;
    input [1023:0] test_name;
    input [31:0] expected;
    input [31:0] actual;
    begin
        test_count = test_count + 1;
        if (actual === expected) begin
            pass_count = pass_count + 1;
            $display("  [PASS] %0s | expected=%h actual=%h", test_name, expected, actual);
        end
        else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] %0s | expected=%h actual=%h", test_name, expected, actual);
            $display("    Debug: addr=%h rd=%b we=%b wdata=%h rdata=%h irq=%b",
                     addr_i, data_rd_i, data_we_i, data_i, data_o, irq_o);
            $display("    Hint : inspect CR/SR/PSC/LOAD/COUNT update timing, disable behavior, and IRQ clear pulse.");
        end
    end
endtask

task check_irq;
    input [1023:0] test_name;
    input expected;
    begin
        check_value(test_name, {31'b0, expected}, {31'b0, irq_o});
    end
endtask

task wait_for_interrupt;
    input integer timeout_cycles;
    output integer cycles_waited;
    integer count;
    begin
        count = 0;
        cycles_waited = 0;
        while (!irq_o && count < timeout_cycles) begin
            cycle();
            count = count + 1;
        end
        cycles_waited = count;
    end
endtask

task expect_no_interrupt_for;
    input integer cycles_to_wait;
    input [1023:0] label;
    integer i;
    reg ok;
    begin
        ok = 1'b1;
        for (i = 0; i < cycles_to_wait; i = i + 1) begin
            cycle();
            if (irq_o !== 1'b0) begin
                ok = 1'b0;
            end
        end
        check_value(label, 32'h1, {31'b0, ok});
    end
endtask

task reset_timer;
    begin
        rst_n_i = 1'b0;
        addr_i = 8'h00;
        data_rd_i = 1'b0;
        data_we_i = 1'b0;
        data_i = `ZERO_WORD;
        repeat (3) cycle();
        rst_n_i = 1'b1;
        repeat (2) cycle();
    end
endtask

task show_summary;
    begin
        $display("");
        $display("========================================================");
        $display("TIMER TEST SUMMARY");
        $display("Total : %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("========================================================");
        if (fail_count == 0) begin
            $display("[PASS] timer_tb");
        end
        else begin
            $display("[FAIL] timer_tb errors=%0d", fail_count);
        end
    end
endtask

initial begin
    test_count = 0;
    pass_count = 0;
    fail_count = 0;

    reset_timer();

    $display("");
    $display("========== Test 1: Reset Defaults ==========");
    read_reg(TIMER_CR, read_data);
    check_value("CR reset value", 32'h0, read_data);
    read_reg(TIMER_SR, read_data);
    check_value("SR reset value", 32'h0, read_data);
    read_reg(TIMER_PSC, read_data);
    check_value("PSC reset value", 32'h0, read_data);
    read_reg(TIMER_LOAD, read_data);
    check_value("LOAD reset value", 32'h0, read_data);
    read_reg(TIMER_COUNT, read_data);
    check_value("COUNT reset value", 32'h0, read_data);
    check_irq("IRQ reset value", 1'b0);

    $display("");
    $display("========== Test 2: Register Readback While Disabled ==========");
    write_reg(TIMER_PSC, 32'h0000_0002);
    write_reg(TIMER_LOAD, 32'h0000_0007);
    write_reg(TIMER_CR, 32'h0000_0000);
    read_reg(TIMER_PSC, read_data);
    check_value("PSC readback", 32'h0000_0002, read_data);
    read_reg(TIMER_LOAD, read_data);
    check_value("LOAD readback", 32'h0000_0007, read_data);
    read_reg(TIMER_CR, read_data);
    check_value("CR disabled readback", 32'h0000_0000, read_data);
    expect_no_interrupt_for(8, "disabled timer should not raise IRQ");
    read_reg(TIMER_COUNT, read_data);
    check_value("COUNT stays zero while disabled", 32'h0000_0000, read_data);

    $display("");
    $display("========== Test 3: Enable, Load, Count Down, IRQ Pulse ==========");
    write_reg(TIMER_PSC, 32'h0000_0001);
    write_reg(TIMER_LOAD, 32'h0000_0004);
    write_reg(TIMER_CR, 32'h0000_0001);
    read_reg(TIMER_CR, read_data);
    check_value("CR enabled readback", 32'h0000_0001, read_data);
    read_reg(TIMER_COUNT, read_data);
    check_value("COUNT loads from LOAD after enable", 32'h0000_0004, read_data);
    repeat (2) cycle();
    read_reg(TIMER_COUNT, read_data);
    check_value("COUNT decrements across elapsed read cycles", 32'h0000_0002, read_data);
    wait_for_interrupt(32, actual_cycles);
    check_value("IRQ eventually triggers after countdown", 32'h0000_0001, {31'b0, irq_o});
    read_reg(TIMER_SR, read_data);
    check_value("SR exposes latched IRQ flag when read", 32'h0000_0001, read_data & 32'h1);
    check_irq("IRQ is low again after auto clear", 1'b0);

    $display("");
    $display("========== Test 4: Clear Register Write And Restart ==========");
    write_reg(TIMER_SR, 32'h0000_0000);
    read_reg(TIMER_SR, read_data);
    check_value("SR remains clear after writing zero", 32'h0000_0000, read_data & 32'h1);
    write_reg(TIMER_CR, 32'h0000_0000);
    cycle();
    read_reg(TIMER_COUNT, read_data);
    check_value("COUNT clears when timer disabled", 32'h0000_0000, read_data);
    write_reg(TIMER_LOAD, 32'h0000_0002);
    write_reg(TIMER_PSC, 32'h0000_0000);
    write_reg(TIMER_CR, 32'h0000_0001);
    wait_for_interrupt(32, actual_cycles);
    check_value("restart with new LOAD/PSC triggers IRQ", 32'h0000_0001, {31'b0, irq_o});
    write_reg(TIMER_CR, 32'h0000_0000);

    $display("");
    $display("========== Test 5: Unknown Address And Disable Stability ==========");
    write_reg(8'hfc, 32'hffff_ffff);
    read_reg(8'hfc, read_data);
    check_value("unknown address reads zero", 32'h0000_0000, read_data);
    expect_no_interrupt_for(10, "disabled timer remains quiet after unknown write");

    show_summary();
    if (fail_count == 0) begin
        $finish;
    end
    else begin
        $fatal(1);
    end
end

endmodule
