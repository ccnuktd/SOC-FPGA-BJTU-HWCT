`timescale 1ns/1ps

module tb_clint;

`include "../rtl/pa_chip_param.v"

reg                         clk;
reg                         rst_n;
reg                         inst_set;
reg  [2:0]                  inst_func;
reg  [`ADDR_BUS_WIDTH-1:0]  pc;
reg  [`DATA_BUS_WIDTH-1:0]  inst;
reg  [`DATA_BUS_WIDTH-1:0]  csr_mtvec;
reg  [`DATA_BUS_WIDTH-1:0]  csr_mepc;
reg  [`DATA_BUS_WIDTH-1:0]  csr_mstatus;
reg                         irq;
reg                         jump_flag;
reg  [`DATA_BUS_WIDTH-1:0]  jump_addr;
reg                         hold_flag;
reg  [`ADDR_BUS_WIDTH-1:0]  next_pc;
reg                         inst_retire;

wire [`CSR_BUS_WIDTH-1:0]   csr_waddr;
wire                        csr_waddr_vld;
wire [`DATA_BUS_WIDTH-1:0]  csr_wdata;
wire                        hold_flag_o;
wire                        jump_flag_o;
wire [`DATA_BUS_WIDTH-1:0]  jump_addr_o;

integer                     errors;

pa_core_clint dut (
    .clk_i                  (clk),
    .rst_n_i                (rst_n),
    .inst_set_i             (inst_set),
    .inst_func_i            (inst_func),
    .pc_i                   (pc),
    .inst_i                 (inst),
    .csr_mtvec_i            (csr_mtvec),
    .csr_mepc_i             (csr_mepc),
    .csr_mstatus_i          (csr_mstatus),
    .irq_i                  (irq),
    .jump_flag_i            (jump_flag),
    .jump_addr_i            (jump_addr),
    .hold_flag_i            (hold_flag),
    .next_pc_i              (next_pc),
    .inst_retire_i          (inst_retire),
    .csr_waddr_o            (csr_waddr),
    .csr_waddr_vld_o        (csr_waddr_vld),
    .csr_wdata_o            (csr_wdata),
    .hold_flag_o            (hold_flag_o),
    .jump_flag_o            (jump_flag_o),
    .jump_addr_o            (jump_addr_o)
);

always #5 clk = ~clk;

task fail;
    input [255:0] msg;
    begin
        errors = errors + 1;
        $display("[FAIL] %0t %0s", $time, msg);
    end
endtask

task check_eq32;
    input [255:0] name;
    input [`DATA_BUS_WIDTH-1:0] got;
    input [`DATA_BUS_WIDTH-1:0] exp;
    begin
        if (got !== exp) begin
            errors = errors + 1;
            $display("[FAIL] %0t %0s got=%h exp=%h", $time, name, got, exp);
        end
    end
endtask

task check_eq1;
    input [255:0] name;
    input got;
    input exp;
    begin
        if (got !== exp) begin
            errors = errors + 1;
            $display("[FAIL] %0t %0s got=%b exp=%b", $time, name, got, exp);
        end
    end
endtask

task cycle;
    begin
        @(negedge clk);
    end
endtask

task reset_case;
    begin
        rst_n       = 1'b0;
        inst_set    = 1'b0;
        inst_func   = 3'b000;
        pc          = 32'h8000_0100;
        inst        = 32'h0000_0013;
        csr_mtvec   = 32'h8000_017c;
        csr_mepc    = 32'h8000_2000;
        csr_mstatus = 32'h0000_1888;
        irq         = 1'b0;
        jump_flag   = 1'b0;
        jump_addr   = 32'h8000_1000;
        hold_flag   = 1'b0;
        next_pc     = 32'h8000_0104;
        inst_retire = 1'b0;
        repeat (3) cycle();
        rst_n       = 1'b1;
        repeat (2) cycle();
    end
endtask

task expect_no_csr_for;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1) begin
            cycle();
            if (csr_waddr_vld) fail("unexpected csr write");
        end
    end
endtask

task expect_csr;
    input [`CSR_BUS_WIDTH-1:0] exp_addr;
    input [`DATA_BUS_WIDTH-1:0] exp_data;
    input [255:0] label;
    integer i;
    reg found;
    begin
        found = 1'b0;
        if (csr_waddr_vld) begin
            found = 1'b1;
            if (csr_waddr !== exp_addr || csr_wdata !== exp_data) begin
                errors = errors + 1;
                $display("[FAIL] %0t %0s csr got addr=%h data=%h exp addr=%h data=%h",
                         $time, label, csr_waddr, csr_wdata, exp_addr, exp_data);
            end
        end
        for (i = 0; i < 16; i = i + 1) begin
            if (!found) begin
                cycle();
            end
            if (!found && csr_waddr_vld) begin
                found = 1'b1;
                if (csr_waddr !== exp_addr || csr_wdata !== exp_data) begin
                    errors = errors + 1;
                    $display("[FAIL] %0t %0s csr got addr=%h data=%h exp addr=%h data=%h",
                             $time, label, csr_waddr, csr_wdata, exp_addr, exp_data);
                end
                i = 16;
            end
        end
        if (!found) begin
            errors = errors + 1;
            $display("[FAIL] %0t %0s csr write not observed", $time, label);
        end
        else begin
            cycle();
        end
    end
endtask

task expect_jump;
    input [`DATA_BUS_WIDTH-1:0] exp_addr;
    input [255:0] label;
    integer i;
    reg found;
    begin
        found = 1'b0;
        if (jump_flag_o) begin
            found = 1'b1;
            check_eq32(label, jump_addr_o, exp_addr);
        end
        for (i = 0; i < 16; i = i + 1) begin
            if (!found) begin
                cycle();
            end
            if (!found && jump_flag_o) begin
                found = 1'b1;
                check_eq32(label, jump_addr_o, exp_addr);
                i = 16;
            end
        end
        if (!found) begin
            errors = errors + 1;
            $display("[FAIL] %0t %0s jump not observed", $time, label);
        end
        else begin
            cycle();
        end
    end
endtask

task pulse_irq;
    begin
        irq = 1'b1;
        cycle();
        irq = 1'b0;
    end
endtask

task retire_seq;
    input [`DATA_BUS_WIDTH-1:0] target;
    begin
        next_pc     = target;
        inst_retire = 1'b1;
        jump_flag   = 1'b0;
        cycle();
        inst_retire = 1'b0;
    end
endtask

task retire_jump;
    input [`DATA_BUS_WIDTH-1:0] target;
    begin
        next_pc     = target;
        jump_addr   = target;
        jump_flag   = 1'b1;
        inst_retire = 1'b1;
        cycle();
        inst_retire = 1'b0;
        jump_flag   = 1'b0;
    end
endtask

initial begin
    clk = 1'b0;
    errors = 0;

    $display("[TEST] interrupt waits for precise retire and saves next PC");
    reset_case();
    pulse_irq();
    expect_no_csr_for(5);
    check_eq1("wait state must not hold the pipe before trap entry", hold_flag_o, 1'b0);
    retire_seq(32'h8000_0104);
    expect_csr(`CSR_MEPC, 32'h8000_0104, "interrupt mepc");
    expect_csr(`CSR_MSTATUS, 32'h0000_1880, "interrupt mstatus");
    expect_csr(`CSR_MCAUSE, 32'h8000_0003, "interrupt mcause");
    expect_jump(32'h8000_017c, "interrupt mtvec jump");

    $display("[TEST] interrupt after taken jump saves target PC");
    reset_case();
    pulse_irq();
    retire_jump(32'h8000_0738);
    expect_csr(`CSR_MEPC, 32'h8000_0738, "interrupt jump mepc");
    expect_csr(`CSR_MSTATUS, 32'h0000_1880, "interrupt jump mstatus");
    expect_csr(`CSR_MCAUSE, 32'h8000_0003, "interrupt jump mcause");
    expect_jump(32'h8000_017c, "interrupt jump mtvec jump");

    $display("[TEST] ecall exception saves current EX PC");
    reset_case();
    inst_set  = 1'b1;
    inst_func = 3'b100;
    pc        = 32'h8000_0208;
    expect_csr(`CSR_MEPC, 32'h8000_0200, "ecall mepc");
    expect_csr(`CSR_MSTATUS, 32'h0000_1880, "ecall mstatus");
    expect_csr(`CSR_MCAUSE, 32'h0000_000b, "ecall mcause");
    expect_jump(32'h8000_017c, "ecall mtvec jump");

    $display("[TEST] mret restores mstatus and jumps to mepc");
    reset_case();
    inst_set    = 1'b1;
    inst_func   = 3'b001;
    csr_mstatus = 32'h0000_1880;
    csr_mepc    = 32'h8000_3456;
    expect_csr(`CSR_MSTATUS, 32'h0000_1808, "mret mstatus");
    expect_jump(32'h8000_3456, "mret jump");

    if (errors == 0) begin
        $display("[PASS] tb_clint");
        $finish;
    end
    else begin
        $display("[FAIL] tb_clint errors=%0d", errors);
        $fatal(1);
    end
end

endmodule
