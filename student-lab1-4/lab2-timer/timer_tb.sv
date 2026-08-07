`timescale 1ns/1ps
`define TESTBENCH_VCS
`include "pa_chip_param.v"

module timer_tb;

localparam TIMER_CR    = 8'h00;
localparam TIMER_SR    = 8'h04;
localparam TIMER_PSC   = 8'h08;
localparam TIMER_LOAD  = 8'h0c;
localparam TIMER_COUNT = 8'h10;

reg                         clk_i;
reg                         rst_n_i;
reg  [7:0]                  addr_i;
reg                         data_rd_i;
reg                         data_we_i;
reg  [`DATA_BUS_WIDTH-1:0]  data_i;
wire [`DATA_BUS_WIDTH-1:0]  data_o;
wire                        irq_o;

integer tests;
integer failures;
integer checked_cycles;
integer i;
reg [31:0] read_data;
reg [31:0] lfsr;

// Cycle-accurate external reference model. It deliberately models the
// specified register and pulse timing so an implementation one cycle early or
// late cannot pass merely because it eventually reaches the same value.
reg [31:0] ref_cr;
reg [31:0] ref_sr;
reg [31:0] ref_psc;
reg [31:0] ref_load;
reg [31:0] ref_count;
reg [31:0] ref_clk_cnt;
reg        ref_timeup;
reg [31:0] ref_data;
wire       ref_clk_timeup = (ref_clk_cnt == ref_psc);

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

always #5 clk_i = ~clk_i;

initial begin
    $dumpfile("timer.vcd");
    $dumpvars(0, timer_tb);
end

initial ref_data = `ZERO_WORD;

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        ref_clk_cnt <= `ZERO_WORD;
    else if (ref_cr[0]) begin
        if (ref_clk_timeup) ref_clk_cnt <= `ZERO_WORD;
        else                ref_clk_cnt <= ref_clk_cnt + 32'h1;
    end
    else
        ref_clk_cnt <= `ZERO_WORD;
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        ref_timeup <= 1'b0;
    else if (ref_cr[0]) begin
        if (ref_timeup)          ref_timeup <= 1'b0;
        else if (ref_count == 0) ref_timeup <= 1'b1;
    end
    else
        ref_timeup <= 1'b0;
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        ref_count <= `ZERO_WORD;
    else if (ref_cr[0]) begin
        if (ref_count == 0)       ref_count <= ref_load;
        else if (ref_clk_timeup)  ref_count <= ref_count - 32'h1;
    end
    else
        ref_count <= `ZERO_WORD;
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        ref_cr   <= `ZERO_WORD;
        ref_sr   <= `ZERO_WORD;
        ref_psc  <= `ZERO_WORD;
        ref_load <= `ZERO_WORD;
    end
    else begin
        if (data_we_i) begin
            case (addr_i)
                TIMER_CR:   ref_cr   <= data_i;
                TIMER_SR:   ref_sr   <= {data_i[31:1], (ref_sr[0] & ~data_i[0])};
                TIMER_PSC:  ref_psc  <= data_i;
                TIMER_LOAD: ref_load <= data_i;
            endcase
        end
        else if (ref_sr[0])
            ref_sr <= {data_i[31:1], 1'b0};
        else if (ref_cr[0] && ref_timeup)
            ref_sr <= {data_i[31:1], 1'b1};
    end
end

always @(posedge clk_i) begin
    if (data_rd_i) begin
        case (addr_i)
            TIMER_CR:    ref_data <= ref_cr;
            TIMER_SR:    ref_data <= ref_sr;
            TIMER_PSC:   ref_data <= ref_psc;
            TIMER_LOAD:  ref_data <= ref_load;
            TIMER_COUNT: ref_data <= ref_count;
            default:     ref_data <= `ZERO_WORD;
        endcase
    end
end

task check32;
    input [1023:0] name;
    input [31:0] expected;
    input [31:0] actual;
begin
    tests = tests + 1;
    if (actual !== expected) begin
        failures = failures + 1;
        $display("[FAIL] %0s expected=%08h actual=%08h time=%0t", name, expected, actual, $time);
        $display("       addr=%02h rd=%b we=%b wdata=%08h irq=%b ref_count=%08h ref_psc=%08h",
                 addr_i, data_rd_i, data_we_i, data_i, irq_o, ref_count, ref_psc);
    end
end
endtask

// Check every externally observable output after every active clock edge.
always @(posedge clk_i) begin
    #1;
    if (rst_n_i) begin
        checked_cycles = checked_cycles + 1;
        check32("cycle-accurate bus read output", ref_data, data_o);
        check32("cycle-accurate IRQ output", {31'b0, ref_sr[0]}, {31'b0, irq_o});
    end
end

task idle_bus;
begin
    addr_i    = 8'h00;
    data_rd_i = 1'b0;
    data_we_i = 1'b0;
    data_i    = `ZERO_WORD;
end
endtask

task reset_dut;
begin
    @(negedge clk_i);
    rst_n_i = 1'b0;
    idle_bus();
    repeat (3) @(negedge clk_i);
    #1;
    check32("reset drives IRQ low", 32'h0, {31'b0, irq_o});
    rst_n_i = 1'b1;
end
endtask

task bus_write;
    input [7:0] addr;
    input [31:0] data;
begin
    @(negedge clk_i);
    addr_i    = addr;
    data_i    = data;
    data_we_i = 1'b1;
    data_rd_i = 1'b0;
    @(negedge clk_i);
    idle_bus();
end
endtask

task bus_read;
    input [7:0] addr;
    output [31:0] data;
begin
    @(negedge clk_i);
    addr_i    = addr;
    data_rd_i = 1'b1;
    data_we_i = 1'b0;
    @(negedge clk_i);
    #1 data = data_o;
    data_rd_i = 1'b0;
end
endtask

task idle_cycles;
    input integer count;
begin
    @(negedge clk_i);
    idle_bus();
    repeat (count) @(negedge clk_i);
end
endtask

task wait_irq_high;
    input integer limit;
    input [1023:0] name;
    integer n;
    reg found;
begin
    found = 1'b0;
    for (n = 0; n < limit; n = n + 1) begin
        if (!found) begin
            @(negedge clk_i);
            if (irq_o === 1'b1) found = 1'b1;
        end
    end
    check32(name, 32'h1, {31'b0, found});
end
endtask

initial begin
    clk_i = 1'b0;
    rst_n_i = 1'b1;
    idle_bus();
    tests = 0;
    failures = 0;
    checked_cycles = 0;
    lfsr = 32'h1ace_b00c;

    $display("[TEST] timer reset, synchronous read latency, and register decode");
    reset_dut();
    bus_read(TIMER_CR, read_data);    check32("CR reset", 32'h0, read_data);
    bus_read(TIMER_SR, read_data);    check32("SR reset", 32'h0, read_data);
    bus_read(TIMER_PSC, read_data);   check32("PSC reset", 32'h0, read_data);
    bus_read(TIMER_LOAD, read_data);  check32("LOAD reset", 32'h0, read_data);
    bus_read(TIMER_COUNT, read_data); check32("COUNT reset", 32'h0, read_data);
    bus_write(TIMER_PSC, 32'h1234_5678);
    bus_write(TIMER_LOAD, 32'h89ab_cdef);
    bus_read(TIMER_PSC, read_data);   check32("PSC full-width readback", 32'h1234_5678, read_data);
    bus_read(TIMER_LOAD, read_data);  check32("LOAD full-width readback", 32'h89ab_cdef, read_data);
    bus_write(8'hfc, 32'hffff_ffff);
    bus_read(8'hfc, read_data);       check32("unknown address reads zero", 32'h0, read_data);
    bus_read(TIMER_PSC, read_data);   check32("unknown write does not corrupt PSC", 32'h1234_5678, read_data);

    $display("[TEST] exact prescaler/count/reload/IRQ waveform");
    reset_dut();
    bus_write(TIMER_PSC, 32'd2);
    bus_write(TIMER_LOAD, 32'd4);
    bus_write(TIMER_CR, 32'd1);
    // Keep COUNT selected for many consecutive cycles. The reference checker
    // compares the registered read value, count reload, prescale cadence, and
    // the one-cycle IRQ pulse at every edge.
    @(negedge clk_i);
    addr_i = TIMER_COUNT;
    data_rd_i = 1'b1;
    data_we_i = 1'b0;
    repeat (32) @(negedge clk_i);
    data_rd_i = 1'b0;
    check32("timer remains enabled", 32'h1, ref_cr);

    $display("[TEST] disable clears active timing state on the next edge");
    bus_write(TIMER_CR, 32'd0);
    idle_cycles(1);
    bus_read(TIMER_COUNT, read_data); check32("disabled COUNT is zero", 32'h0, read_data);
    check32("disabled prescaler phase is zero", 32'h0, ref_clk_cnt);
    check32("disabled timeup pulse is zero", 32'h0, {31'b0, ref_timeup});
    check32("disabled IRQ is low", 32'h0, {31'b0, irq_o});

    $display("[TEST] SR write-zero-to-keep, write-one-to-clear, and pulse width");
    reset_dut();
    bus_write(TIMER_PSC, 32'd0);
    bus_write(TIMER_LOAD, 32'd1);
    bus_write(TIMER_CR, 32'd1);
    // Initial enable/reload generates the reference design's first pulse.
    wait_irq_high(16, "initial IRQ arrives within exact small configuration bound");
    check32("IRQ is asserted exactly with SR[0]", 32'h1, {31'b0, irq_o});
    bus_write(TIMER_SR, 32'h0000_0000);
    // The write occurs after the pulse's normal auto-clear edge; use a new
    // pulse and write one during it to verify W1C independently.
    wait_irq_high(16, "next IRQ arrives within exact small configuration bound");
    bus_write(TIMER_SR, 32'h0000_0001);
    check32("writing one clears SR[0]", 32'h0, {31'b0, irq_o});
    idle_cycles(1);

    $display("[TEST] deterministic mixed-traffic reference comparison");
    reset_dut();
    for (i = 0; i < 180; i = i + 1) begin
        @(negedge clk_i);
        lfsr = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        data_i = lfsr ^ (32'h9e37_79b9 * i);
        case (i % 12)
            0: begin addr_i = TIMER_PSC;  data_we_i = 1'b1; data_rd_i = 1'b0; data_i = i % 4; end
            1: begin addr_i = TIMER_LOAD; data_we_i = 1'b1; data_rd_i = 1'b0; data_i = (i % 7) + 1; end
            2: begin addr_i = TIMER_CR;   data_we_i = 1'b1; data_rd_i = 1'b0; data_i = 1; end
            7: begin addr_i = TIMER_SR;   data_we_i = 1'b1; data_rd_i = 1'b0; data_i = lfsr; end
            9: begin addr_i = TIMER_CR;   data_we_i = 1'b1; data_rd_i = 1'b0; data_i = 0; end
            default: begin
                data_we_i = 1'b0;
                data_rd_i = 1'b1;
                case (i % 6)
                    0: addr_i = TIMER_CR;
                    1: addr_i = TIMER_SR;
                    2: addr_i = TIMER_PSC;
                    3: addr_i = TIMER_LOAD;
                    4: addr_i = TIMER_COUNT;
                    default: addr_i = 8'hec;
                endcase
            end
        endcase
    end
    @(negedge clk_i);
    idle_bus();
    repeat (2) @(negedge clk_i);

    $display("\n========================================================");
    $display("TIMER STRICT TEST SUMMARY: assertions=%0d checked_cycles=%0d failed=%0d",
             tests, checked_cycles, failures);
    $display("========================================================");
    if (failures != 0) $fatal(1, "timer_tb failed");
    $display("[PASS] timer_tb");
    $finish;
end

endmodule
