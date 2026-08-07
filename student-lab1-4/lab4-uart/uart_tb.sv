`timescale 1ns/1ps
`define TESTBENCH_VCS
`include "pa_chip_param.v"

module uart_tb;

localparam UART_BAUD      = 32'd115200;
localparam UART_CR        = 8'h00;
localparam UART_SR        = 8'h04;
localparam UART_BAUD_REG  = 8'h08;
localparam UART_RXD       = 8'h0c;
localparam UART_TXD       = 8'h10;
localparam STATE_IDLE     = 2'b00;
localparam STATE_START    = 2'b01;
localparam STATE_RUN      = 2'b10;
localparam STATE_END      = 2'b11;
localparam BIT_LIMIT      = (`XTAL_FREQ_HZ) / UART_BAUD;
localparam BIT_TICKS      = BIT_LIMIT + 1;
localparam HALF_LIMIT     = BIT_LIMIT / 2;

reg                         clk_i;
reg                         rst_n_i;
reg  [7:0]                  addr_i;
reg                         data_rd_i;
reg                         data_we_i;
reg  [`DATA_BUS_WIDTH-1:0]  data_i;
wire [`DATA_BUS_WIDTH-1:0]  data_o;
reg                         pad_rxd;
wire                        pad_txd;

integer tests;
integer failures;
integer checked_cycles;
integer i;
integer j;
reg [31:0] read_data;
reg [31:0] lfsr;

// Cycle-accurate reference model. Only public DUT outputs are compared; the
// model exists to make every bit boundary and bus-visible state transition an
// assertion instead of accepting a byte that happens to decode eventually.
reg [31:0] ref_cr;
reg [31:0] ref_sr;
reg [31:0] ref_baud;
reg [31:0] ref_rxd;
reg [31:0] ref_txd;
reg [31:0] ref_tx_clk_cnt;
reg [31:0] ref_rx_clk_cnt;
reg [19:0] ref_tx_pipe;
reg [7:0]  ref_rx_pipe;
reg [1:0]  ref_tx_state;
reg [1:0]  ref_rx_state;
reg        ref_tx_start;
reg [31:0] ref_data;

wire ref_tx_clk_timeup = (ref_tx_clk_cnt == BIT_LIMIT);
wire ref_rx_clk_timeup = (ref_rx_state == STATE_START)
                       ? (ref_rx_clk_cnt == HALF_LIMIT)
                       : (ref_rx_clk_cnt == BIT_LIMIT);
wire ref_tx_idle = (ref_tx_state == STATE_IDLE);
wire ref_rx_idle = (ref_rx_state == STATE_IDLE);
wire ref_pad_txd = ref_tx_pipe[10];

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

always #5 clk_i = ~clk_i;

initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0, uart_tb);
end

initial ref_data = `ZERO_WORD;

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        ref_tx_clk_cnt <= `ZERO_WORD;
    else if (ref_tx_clk_timeup)
        ref_tx_clk_cnt <= `ZERO_WORD;
    else
        ref_tx_clk_cnt <= ref_tx_clk_cnt + 32'h1;
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        ref_tx_start <= 1'b0;
    else if (ref_tx_state == STATE_IDLE) begin
        if (ref_cr[0] && addr_i == UART_TXD && data_we_i)
            ref_tx_start <= 1'b1;
    end
    else if (ref_tx_state == STATE_RUN)
        ref_tx_start <= 1'b0;
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        ref_tx_state <= STATE_IDLE;
    else if (ref_tx_clk_timeup) begin
        if (ref_tx_state == STATE_START)
            ref_tx_state <= STATE_RUN;
        else if (ref_tx_start)
            ref_tx_state <= STATE_START;
        else if (ref_tx_state == STATE_RUN) begin
            if (!ref_tx_pipe[0]) ref_tx_state <= STATE_END;
        end
        else if (ref_tx_state == STATE_END)
            ref_tx_state <= STATE_IDLE;
    end
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        ref_tx_pipe <= 20'hf_ffff;
    else if (ref_tx_clk_timeup && ref_cr[0]) begin
        case (ref_tx_state)
            STATE_IDLE:  ref_tx_pipe <= 20'hf_ffff;
            STATE_START: ref_tx_pipe <= {1'b1, ref_txd[7:0], 1'b0, 10'h3ff};
            STATE_RUN:   ref_tx_pipe <= {1'b1, ref_tx_pipe[19:1]};
            STATE_END:   ref_tx_pipe <= 20'hf_ffff;
        endcase
    end
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        ref_rx_clk_cnt <= `ZERO_WORD;
    else if (ref_rx_state == STATE_IDLE)
        ref_rx_clk_cnt <= `ZERO_WORD;
    else if (ref_rx_clk_timeup)
        ref_rx_clk_cnt <= `ZERO_WORD;
    else
        ref_rx_clk_cnt <= ref_rx_clk_cnt + 32'h1;
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        ref_rx_state <= STATE_IDLE;
    else if (ref_rx_state == STATE_IDLE) begin
        if (!pad_rxd) ref_rx_state <= STATE_START;
    end
    else if (ref_rx_state == STATE_START) begin
        if (!pad_rxd && ref_rx_clk_timeup) ref_rx_state <= STATE_RUN;
    end
    else if (ref_rx_clk_timeup) begin
        if (ref_rx_state == STATE_RUN) begin
            if (!ref_rx_pipe[0]) ref_rx_state <= STATE_END;
        end
        else if (ref_rx_state == STATE_END)
            ref_rx_state <= STATE_IDLE;
    end
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        ref_rx_pipe <= 8'hff;
    else if (ref_cr[1] && ref_rx_clk_timeup) begin
        case (ref_rx_state)
            STATE_IDLE:  ref_rx_pipe <= 8'hff;
            STATE_START: ref_rx_pipe <= {pad_rxd, ref_rx_pipe[7:1]};
            STATE_RUN:   ref_rx_pipe <= {pad_rxd, ref_rx_pipe[7:1]};
            STATE_END:   ref_rx_pipe <= 8'hff;
        endcase
    end
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        ref_cr   <= 32'h0000_0003;
        ref_sr   <= 32'h0000_0000;
        ref_baud <= UART_BAUD;
        ref_rxd  <= 32'hffff_ffff;
        ref_txd  <= 32'hffff_ffff;
    end
    else if (ref_cr[0] && ref_tx_state == STATE_END) begin
        if (addr_i == UART_SR)
            ref_sr <= {data_i[31:2], (ref_sr[1] & ~data_i[1]), 1'b1};
        else
            ref_sr <= {ref_sr[31:1], 1'b1};
    end
    else if (ref_cr[1] && ref_rx_state == STATE_END) begin
        if (addr_i == UART_SR)
            ref_sr <= {data_i[31:2], 1'b1, (ref_sr[0] & ~data_i[0])};
        else
            ref_sr <= {ref_sr[31:2], 1'b1, ref_sr[0]};
        ref_rxd <= {24'b0, ref_rx_pipe};
    end
    else if (data_we_i) begin
        case (addr_i)
            UART_CR:  ref_cr  <= data_i;
            UART_SR:  ref_sr  <= {data_i[31:2], (ref_sr[1] & ~data_i[1]),
                                  (ref_sr[0] & ~data_i[0])};
            UART_TXD: ref_txd <= {24'b0, data_i[7:0]};
        endcase
    end
end

always @(posedge clk_i) begin
    if (data_rd_i) begin
        case (addr_i)
            UART_CR:       ref_data <= ref_cr;
            UART_SR:       ref_data <= {ref_sr[31:2], (ref_rx_idle & ref_sr[1]),
                                        (ref_tx_idle & ref_sr[0])};
            UART_BAUD_REG: ref_data <= ref_baud;
            UART_RXD:      ref_data <= {24'b0, ref_rxd[7:0]};
            UART_TXD:      ref_data <= {24'b0, ref_txd[7:0]};
            default:       ref_data <= `ZERO_WORD;
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
        $display("       addr=%02h rd=%b we=%b wdata=%08h rxd=%b txd=%b ref_tx_state=%b ref_rx_state=%b",
                 addr_i, data_rd_i, data_we_i, data_i, pad_rxd, pad_txd,
                 ref_tx_state, ref_rx_state);
    end
end
endtask

always @(posedge clk_i) begin
    #1;
    if (rst_n_i) begin
        checked_cycles = checked_cycles + 1;
        check32("cycle-accurate UART bus output", ref_data, data_o);
        check32("cycle-accurate TX pin", {31'b0, ref_pad_txd}, {31'b0, pad_txd});
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
    pad_rxd = 1'b1;
    repeat (3) @(negedge clk_i);
    #1;
    check32("reset keeps TX pin high", 32'h1, {31'b0, pad_txd});
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

task capture_tx_byte;
    input [7:0] expected;
    input [1023:0] name;
    integer timeout;
    integer bit_index;
    reg found;
    reg [7:0] captured;
begin : capture_body
    found = 1'b0;
    captured = 8'h00;
    for (timeout = 0; timeout < (BIT_TICKS * 3); timeout = timeout + 1) begin
        @(negedge clk_i);
        if (pad_txd === 1'b0) begin
            found = 1'b1;
            timeout = BIT_TICKS * 3;
        end
    end
    check32({name, " start bit observed"}, 32'h1, {31'b0, found});
    if (!found) disable capture_body;
    repeat (BIT_TICKS / 2) @(negedge clk_i);
    check32({name, " start bit center is low"}, 32'h0, {31'b0, pad_txd});
    for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        repeat (BIT_TICKS) @(negedge clk_i);
        captured[bit_index] = pad_txd;
    end
    repeat (BIT_TICKS) @(negedge clk_i);
    check32({name, " stop bit is high"}, 32'h1, {31'b0, pad_txd});
    check32({name, " LSB-first byte"}, {24'b0, expected}, {24'b0, captured});
    repeat (BIT_TICKS * 2) @(negedge clk_i);
end
endtask

task send_rx_byte;
    input [7:0] value;
    integer bit_index;
begin
    @(negedge clk_i);
    addr_i = UART_SR;
    data_rd_i = 1'b1;
    data_we_i = 1'b0;
    data_i = 32'h0;
    pad_rxd = 1'b0;
    repeat (BIT_TICKS) @(negedge clk_i);
    for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        pad_rxd = value[bit_index];
        repeat (BIT_TICKS) @(negedge clk_i);
    end
    pad_rxd = 1'b1;
    repeat (BIT_TICKS * 3) @(negedge clk_i);
    data_rd_i = 1'b0;
end
endtask

task wait_tx_complete;
    output [31:0] status;
    input [1023:0] name;
    integer timeout;
    reg found;
begin
    status = 32'h0;
    found = 1'b0;
    for (timeout = 0; timeout < (BIT_TICKS * 3); timeout = timeout + 1) begin
        if (!found) begin
            bus_read(UART_SR, status);
            if (status[0]) found = 1'b1;
        end
    end
    check32({name, " completion becomes visible while idle"}, 32'h1, {31'b0, found});
end
endtask

initial begin
    clk_i = 1'b0;
    rst_n_i = 1'b1;
    pad_rxd = 1'b1;
    idle_bus();
    tests = 0;
    failures = 0;
    checked_cycles = 0;
    lfsr = 32'hcafe_1234;

    $display("[TEST] UART reset values, register decode, and synchronous reads");
    reset_dut();
    bus_read(UART_CR, read_data);       check32("CR reset", 32'h0000_0003, read_data);
    bus_read(UART_SR, read_data);       check32("SR reset", 32'h0000_0000, read_data);
    bus_read(UART_BAUD_REG, read_data); check32("BAUD is fixed at 115200", 32'd115200, read_data);
    bus_read(UART_RXD, read_data);      check32("RXD reset low byte", 32'h0000_00ff, read_data);
    bus_read(UART_TXD, read_data);      check32("TXD reset low byte", 32'h0000_00ff, read_data);
    bus_read(8'hfc, read_data);         check32("unknown address reads zero", 32'h0, read_data);
    bus_write(UART_BAUD_REG, 32'd9600);
    bus_read(UART_BAUD_REG, read_data); check32("BAUD ignores writes", 32'd115200, read_data);
    bus_write(UART_CR, 32'h1234_0003);
    bus_read(UART_CR, read_data);       check32("CR preserves all writable bits", 32'h1234_0003, read_data);
    bus_write(UART_TXD, 32'hdead_be5a);
    bus_read(UART_TXD, read_data);      check32("TXD stores only low byte", 32'h0000_005a, read_data);

    $display("[TEST] exact TX framing, bit order, bit duration, and completion flag");
    reset_dut();
    for (i = 0; i < 4; i = i + 1) begin
        case (i)
            0: read_data = 32'h00;
            1: read_data = 32'hff;
            2: read_data = 32'h96;
            default: read_data = 32'h53;
        endcase
        bus_write(UART_TXD, read_data);
        capture_tx_byte(read_data[7:0], "TX frame");
        wait_tx_complete(read_data, "TX frame");
        check32("TX completion flag is set", 32'h1, read_data & 32'h1);
        bus_write(UART_SR, 32'h0000_0001);
        bus_read(UART_SR, read_data);
        check32("TX flag is write-one-to-clear", 32'h0, read_data & 32'h1);
    end

    $display("[TEST] TX disable blocks launch and preserves idle level");
    reset_dut();
    bus_write(UART_CR, 32'h0000_0002);
    bus_write(UART_TXD, 32'h0000_0069);
    for (i = 0; i < BIT_TICKS * 12; i = i + 1) begin
        @(negedge clk_i);
        if (pad_txd !== 1'b1)
            check32("disabled TX must remain high", 32'h1, {31'b0, pad_txd});
    end
    bus_read(UART_SR, read_data);
    check32("disabled TX does not set completion", 32'h0, read_data & 32'h1);
    bus_write(UART_CR, 32'h0000_0003);
    for (i = 0; i < BIT_TICKS * 3; i = i + 1) begin
        @(negedge clk_i);
        if (pad_txd !== 1'b1)
            check32("reenable without a new TXD write must not launch stale data",
                    32'h1, {31'b0, pad_txd});
    end
    bus_write(UART_TXD, 32'h0000_0036);
    capture_tx_byte(8'h36, "TX works after disable and reenable");
    wait_tx_complete(read_data, "TX after reenable");
    check32("TX completion after reenable", 32'h1, read_data & 32'h1);

    $display("[TEST] TXD write while busy does not queue an implicit second frame");
    reset_dut();
    bus_write(UART_TXD, 32'h0000_00c3);
    fork
        capture_tx_byte(8'hc3, "current TX frame survives busy write");
        begin
            repeat (BIT_TICKS * 3) @(negedge clk_i);
            bus_write(UART_TXD, 32'h0000_005a);
        end
    join
    wait_tx_complete(read_data, "busy-write TX frame");
    bus_read(UART_TXD, read_data);
    check32("busy TXD write updates holding register", 32'h0000_005a, read_data);
    for (i = 0; i < BIT_TICKS * 3; i = i + 1) begin
        @(negedge clk_i);
        if (pad_txd !== 1'b1)
            check32("busy write must not auto-queue another frame", 32'h1, {31'b0, pad_txd});
    end

    $display("[TEST] RX framing, bit order, data register, and W1C flag");
    reset_dut();
    for (i = 0; i < 4; i = i + 1) begin
        case (i)
            0: read_data = 32'h00;
            1: read_data = 32'hff;
            2: read_data = 32'h96;
            default: read_data = 32'h5a;
        endcase
        send_rx_byte(read_data[7:0]);
        bus_read(UART_RXD, lfsr);
        check32("RX byte is stored LSB-first", read_data & 32'hff, lfsr);
        bus_read(UART_SR, lfsr);
        check32("RX completion flag visible when idle", 32'h2, lfsr & 32'h2);
        bus_write(UART_SR, 32'h0000_0000);
        bus_read(UART_SR, lfsr);
        check32("writing zero preserves RX flag", 32'h2, lfsr & 32'h2);
        bus_write(UART_SR, 32'h0000_0002);
        bus_read(UART_SR, lfsr);
        check32("writing one clears RX flag", 32'h0, lfsr & 32'h2);
    end

    $display("[TEST] RX disable suppresses data and completion flag");
    reset_dut();
    bus_write(UART_CR, 32'h0000_0001);
    send_rx_byte(8'h69);
    bus_read(UART_RXD, read_data);
    check32("disabled RX keeps reset data", 32'h0000_00ff, read_data);
    bus_read(UART_SR, read_data);
    check32("disabled RX does not set completion", 32'h0, read_data & 32'h2);

    $display("[TEST] deterministic mixed register traffic while UART is idle");
    reset_dut();
    for (i = 0; i < 160; i = i + 1) begin
        @(negedge clk_i);
        lfsr = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        data_i = lfsr;
        case (i % 10)
            0: begin addr_i = UART_CR;  data_we_i = 1'b1; data_rd_i = 1'b0; data_i = 32'h3; end
            1: begin addr_i = UART_SR;  data_we_i = 1'b1; data_rd_i = 1'b0; end
            2: begin addr_i = 8'hec;    data_we_i = 1'b1; data_rd_i = 1'b0; end
            default: begin
                data_we_i = 1'b0;
                data_rd_i = 1'b1;
                case (i % 6)
                    0: addr_i = UART_CR;
                    1: addr_i = UART_SR;
                    2: addr_i = UART_BAUD_REG;
                    3: addr_i = UART_RXD;
                    4: addr_i = UART_TXD;
                    default: addr_i = 8'hfc;
                endcase
            end
        endcase
    end
    @(negedge clk_i);
    idle_bus();
    repeat (2) @(negedge clk_i);

    $display("\n========================================================");
    $display("UART STRICT TEST SUMMARY: assertions=%0d checked_cycles=%0d failed=%0d",
             tests, checked_cycles, failures);
    $display("========================================================");
    if (failures != 0) $fatal(1, "uart_tb failed");
    $display("[PASS] uart_tb");
    $finish;
end

endmodule
