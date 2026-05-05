`timescale 1ns/1ps

module tb_exu_control;

`include "../rtl/pa_chip_param.v"

reg                         clk;
reg                         rst_n;
reg  [1:0]                  inst_set;
reg  [`INST_FUNC_WIDTH-1:0] inst_func;
reg  [`DATA_BUS_WIDTH-1:0]  pc;
reg  [`DATA_BUS_WIDTH-1:0]  reg1;
reg  [`DATA_BUS_WIDTH-1:0]  reg2;
reg  [19:0]                 uimm;
reg  [`REG_BUS_WIDTH-1:0]   reg_waddr_i;
reg                         reg_waddr_vld_i;
reg  [`DATA_BUS_WIDTH-1:0]  csr_rdata;

wire                        csr_waddr_vld;
wire [`DATA_BUS_WIDTH-1:0]  csr_wdata;
wire                        mem_en;
wire                        hold_flag;
wire                        jump_flag;
wire [`DATA_BUS_WIDTH-1:0]  jump_addr;
wire [`REG_BUS_WIDTH-1:0]   reg_waddr;
wire                        reg_waddr_vld;
wire [`DATA_BUS_WIDTH-1:0]  iresult;
wire                        iresult_vld;
integer                     errors;

pa_core_exu dut (
    .clk_i              (clk),
    .rst_n_i            (rst_n),
    .inst_set_i         (inst_set),
    .inst_func_i        (inst_func),
    .pc_i               (pc),
    .reg1_rdata_i       (reg1),
    .reg2_rdata_i       (reg2),
    .uimm_i             (uimm),
    .reg_waddr_i        (reg_waddr_i),
    .reg_waddr_vld_i    (reg_waddr_vld_i),
    .csr_rdata_i        (csr_rdata),
    .csr_waddr_vld_o    (csr_waddr_vld),
    .csr_wdata_o        (csr_wdata),
    .mem_en_o           (mem_en),
    .hold_flag_o        (hold_flag),
    .jump_flag_o        (jump_flag),
    .jump_addr_o        (jump_addr),
    .reg_waddr_o        (reg_waddr),
    .reg_waddr_vld_o    (reg_waddr_vld),
    .iresult_o          (iresult),
    .iresult_vld_o      (iresult_vld)
);

always #5 clk = ~clk;

task cycle;
    begin
        @(negedge clk);
    end
endtask

task check1;
    input [255:0] label;
    input got;
    input exp;
    begin
        if (got !== exp) begin
            errors = errors + 1;
            $display("[FAIL] %0t %0s got=%b exp=%b", $time, label, got, exp);
        end
    end
endtask

task check32;
    input [255:0] label;
    input [`DATA_BUS_WIDTH-1:0] got;
    input [`DATA_BUS_WIDTH-1:0] exp;
    begin
        if (got !== exp) begin
            errors = errors + 1;
            $display("[FAIL] %0t %0s got=%h exp=%h", $time, label, got, exp);
        end
    end
endtask

initial begin
    clk = 1'b0;
    rst_n = 1'b1;
    inst_set = 2'b01;
    inst_func = `INST_FUNC_NULL;
    pc = 32'h8000_0108;
    reg1 = 32'h0;
    reg2 = 32'h0;
    uimm = 20'h0;
    reg_waddr_i = 5'd1;
    reg_waddr_vld_i = 1'b1;
    csr_rdata = 32'h0;
    errors = 0;

    $display("[TEST] branch taken target");
    rst_n = 1'b0;
    repeat (3) cycle();
    rst_n = 1'b1;
    cycle();

    $display("[TEST] ALU add/sub");
    inst_func = `INST_FUNC_ADD;
    reg1 = 32'h10;
    reg2 = 32'h22;
    #1;
    check1("add result valid", iresult_vld, 1'b1);
    check32("add result", iresult, 32'h32);
    check1("add no jump", jump_flag, 1'b0);
    check1("add no hold", hold_flag, 1'b0);

    inst_func = `INST_FUNC_SUB;
    reg1 = 32'h30;
    reg2 = 32'h11;
    #1;
    check32("sub result", iresult, 32'h1f);

    $display("[TEST] MUL");
    inst_set = 2'b10;
    inst_func = `INST_FUNC_MUL;
    reg1 = 32'd7;
    reg2 = 32'd6;
    #1;
    check1("mul result valid", iresult_vld, 1'b1);
    check32("mul result", iresult, 32'd42);
    check1("mul no hold", hold_flag, 1'b0);

    $display("[TEST] load/store and div busy flags");
    inst_set = 2'b01;
    inst_func = `INST_FUNC_LOAD | `INST_FUNC_SUFFIX_IMM;
    reg1 = 32'h1000;
    reg2 = 32'h0;
    uimm = 20'h004;
    #1;
    check1("load mem enable", mem_en, 1'b1);
    check1("load hold", hold_flag, 1'b1);
    check32("load address", iresult, 32'h1004);

    inst_func = `INST_FUNC_STORE | `INST_FUNC_SUFFIX_IMM;
    reg1 = 32'h2000;
    reg2 = 32'h0;
    uimm = 20'h008;
    #1;
    check1("store mem enable", mem_en, 1'b1);
    check1("store hold", hold_flag, 1'b1);
    check32("store address", iresult, 32'h2008);

    inst_set = 2'b10;
    inst_func = `INST_FUNC_DIV;
    reg1 = 32'd100;
    reg2 = 32'd5;
    #1;
    check1("div starts hold", hold_flag, 1'b1);
    check1("div no immediate writeback", reg_waddr_vld, 1'b0);

    $display("[TEST] CSR");
    inst_set = 2'b01;
    inst_func = `INST_FUNC_CSRRS;
    reg1 = 32'h0000_0008;
    csr_rdata = 32'h0000_1800;
    #1;
    check1("csr write valid", csr_waddr_vld, 1'b1);
    check32("csr write data", csr_wdata, 32'h0000_1808);
    check32("csr old value result", iresult, 32'h0000_1800);

    inst_func = `INST_FUNC_B | `INST_FUNC_SUFFIX_NE;
    inst_set = 2'b01;
    reg1 = 32'h1;
    reg2 = 32'h2;
    uimm = 20'h004;
    #1;
    check1("bne jump flag", jump_flag, 1'b1);
    check32("bne target", jump_addr, 32'h8000_0108);

    $display("[TEST] branch not taken");
    reg2 = 32'h1;
    #1;
    check1("bne not taken", jump_flag, 1'b0);

    $display("[TEST] jalr target and link");
    inst_func = `INST_FUNC_JALR;
    reg1 = 32'h8000_0203;
    uimm = 20'h005;
    #1;
    check1("jalr jump flag", jump_flag, 1'b1);
    check32("jalr target", jump_addr, 32'h8000_0208);
    check32("jalr link result", iresult, 32'h8000_0104);

    if (errors == 0) begin
        $display("[PASS] tb_exu_control");
        $finish;
    end
    else begin
        $display("[FAIL] tb_exu_control errors=%0d", errors);
        $fatal(1);
    end
end

endmodule
