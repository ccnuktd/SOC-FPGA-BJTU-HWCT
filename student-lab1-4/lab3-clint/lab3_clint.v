`ifdef TESTBENCH_VCS
`include "pa_chip_param.v"
`else
`include "../pa_chip_param.v"
`endif

module pa_core_clint (
    input  wire                         clk_i,
    input  wire                         rst_n_i,

    input  wire                         inst_set_i,
    input  wire [2:0]                   inst_func_i,

    input  wire [`ADDR_BUS_WIDTH-1:0]   pc_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   inst_i,

    input  wire [`DATA_BUS_WIDTH-1:0]   csr_mtvec_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   csr_mepc_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   csr_mstatus_i,

    input  wire                         irq_i,

    input  wire                         jump_flag_i,
    input  wire [`DATA_BUS_WIDTH-1:0]   jump_addr_i,
    input  wire                         hold_flag_i,

    output wire [`CSR_BUS_WIDTH-1:0]    csr_waddr_o,
    output wire                         csr_waddr_vld_o,
    output wire [`DATA_BUS_WIDTH-1:0]   csr_wdata_o,

    output wire                         hold_flag_o,

    output wire                         jump_flag_o,
    output wire [`DATA_BUS_WIDTH-1:0]   jump_addr_o
);

localparam INT_STATE_IDLE      = 2'd0;
localparam INT_STATE_MCALL     = 2'd1;
localparam INT_STATE_MRET      = 2'd2;

localparam INT_TYPE_NONE       = 2'b00;
localparam INT_TYPE_EXCEPTION  = 2'b01;
localparam INT_TYPE_INTERRUPT  = 2'b10;

localparam CSR_STATE_IDLE      = 3'd0;
localparam CSR_STATE_WAIT      = 3'd1;
localparam CSR_STATE_MEPC      = 3'd2;
localparam CSR_STATE_MSTATUS   = 3'd3;
localparam CSR_STATE_MCAUSE    = 3'd4;
localparam CSR_STATE_MRET      = 3'd5;

reg  [1:0]                             int_state;
reg  [1:0]                             int_type;
reg  [2:0]                             csr_state;

wire                                   inst_set_rvi;
wire                                   global_int_en;
wire                                   op_ecall;
wire                                   op_ebreak;
wire                                   op_mret;

assign inst_set_rvi  = inst_set_i;
assign global_int_en = csr_mstatus_i[3];

// TODO-1: Decode trap-related instructions.
// inst_func_i[2] -> ecall, inst_func_i[1] -> ebreak, inst_func_i[0] -> mret.
assign op_ecall  = `INVALID;
assign op_ebreak = `INVALID;
assign op_mret   = `INVALID;

wire [1:0]                             irq_1r;
pa_dff_rst_0 #(2) dff_irq_1r (
    clk_i,
    rst_n_i,
    `VALID,
    {irq_1r[0], irq_i},
    irq_1r
);

wire                                   irq_vld;
reg                                    irq_vld_t;
reg                                    irq_pending;

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        irq_vld_t <= `INVALID;
    end
    else if (int_state == INT_STATE_IDLE) begin
        irq_vld_t <= `INVALID;
    end
    else begin
        irq_vld_t <= irq_vld;
    end
end

// TODO-2: Generate a valid IRQ event.
// It should become valid on irq_i rising edge, and stay valid while CLINT is handling it.
assign irq_vld = `INVALID;

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        irq_pending <= `INVALID;
    end
    else if (csr_state == CSR_STATE_MCAUSE) begin
        irq_pending <= `INVALID;
    end
    else if (global_int_en && irq_vld) begin
        // TODO-3: Latch an enabled external interrupt as pending.
        irq_pending <= `INVALID;
    end
end

always @(*) begin
    if (!rst_n_i) begin
        int_state = INT_STATE_IDLE;
        int_type  = INT_TYPE_NONE;
    end
    else begin
        // TODO-4: Choose current interrupt state/type.
        // Priority: mret > ecall/ebreak > pending/new external interrupt > idle.
        int_state = INT_STATE_IDLE;
        int_type  = INT_TYPE_NONE;
    end
end

wire [`DATA_BUS_WIDTH-1:0]             exception_addr;
wire [`DATA_BUS_WIDTH-1:0]             interrupt_addr;

// TODO-5: Calculate the address written into mepc.
// Exception uses current pipeline convention pc_i - 8; interrupt uses jump_addr_i.
assign exception_addr = `ZERO_WORD;
assign interrupt_addr = `ZERO_WORD;

wire [`DATA_BUS_WIDTH-1:0]             break_addr_soft;
wire [`DATA_BUS_WIDTH-1:0]             break_addr_ext;
wire [`DATA_BUS_WIDTH-1:0]             break_addr_next;
wire [`DATA_BUS_WIDTH-1:0]             break_addr;

// TODO-6: Select mepc write data for exception and interrupt.
assign break_addr_soft = `ZERO_WORD;
assign break_addr_ext  = `ZERO_WORD;
assign break_addr_next = break_addr_soft | break_addr_ext;

wire [`DATA_BUS_WIDTH-1:0]             break_cause_soft;
wire [`DATA_BUS_WIDTH-1:0]             break_cause_ext;
wire [`DATA_BUS_WIDTH-1:0]             break_cause_next;
wire [`DATA_BUS_WIDTH-1:0]             break_cause;

// TODO-7: Select mcause write data.
// ecall -> 11, ebreak -> 3, external machine interrupt -> 0x80000003.
assign break_cause_soft = `ZERO_WORD;
assign break_cause_ext  = `ZERO_WORD;
assign break_cause_next = break_cause_soft | break_cause_ext;

wire                                   trap_capture;
wire                                   trap_ready;
reg                                    jump_trap_captured;

// TODO-8: Decide when the return address/cause can be captured.
// Exception can be captured in IDLE when there is no jump/hold conflict.
// Interrupt can be captured only when jump_flag_i gives a stable next PC.
assign trap_capture = `INVALID;

// TODO-9: Decide when CSR state machine may enter MEPC write.
// Interrupts must wait for hold_flag_i to drop after jump has been captured.
assign trap_ready = `INVALID;

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        jump_trap_captured <= `INVALID;
    end
    else if (csr_state == CSR_STATE_IDLE && int_state != INT_STATE_MCALL) begin
        jump_trap_captured <= `INVALID;
    end
    else if (trap_capture && jump_flag_i && int_type == INT_TYPE_INTERRUPT) begin
        jump_trap_captured <= `VALID;
    end
end

pa_dff_rst_0 #(`DATA_BUS_WIDTH) dff_break_addr (
    clk_i,
    rst_n_i,
    trap_capture,
    break_addr_next,
    break_addr
);

pa_dff_rst_0 #(`DATA_BUS_WIDTH) dff_break_cause (
    clk_i,
    rst_n_i,
    trap_capture,
    break_cause_next,
    break_cause
);

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        csr_state <= CSR_STATE_IDLE;
    end
    else begin
        case (csr_state)
            CSR_STATE_IDLE,
            CSR_STATE_WAIT: begin
                case (int_state)
                    INT_STATE_MCALL: begin
                        if (trap_ready) begin
                            csr_state <= CSR_STATE_MEPC;
                        end
                        else if (int_type == INT_TYPE_INTERRUPT && csr_state == CSR_STATE_IDLE) begin
                            csr_state <= CSR_STATE_WAIT;
                        end
                        else if (int_type == INT_TYPE_INTERRUPT && csr_state == CSR_STATE_WAIT && !trap_capture) begin
                            csr_state <= CSR_STATE_WAIT;
                        end
                        else if (jump_flag_i || hold_flag_i) begin
                            csr_state <= CSR_STATE_WAIT;
                        end
                        else begin
                            csr_state <= CSR_STATE_MEPC;
                        end
                    end

                    INT_STATE_MRET: begin
                        csr_state <= CSR_STATE_MRET;
                    end

                    default: begin
                        csr_state <= csr_state;
                    end
                endcase
            end

            CSR_STATE_MEPC:    csr_state <= (jump_flag_i ? CSR_STATE_MEPC : CSR_STATE_MSTATUS);
            CSR_STATE_MSTATUS: csr_state <= CSR_STATE_MCAUSE;
            CSR_STATE_MCAUSE:  csr_state <= CSR_STATE_IDLE;
            CSR_STATE_MRET:    csr_state <= CSR_STATE_IDLE;

            default: begin
                csr_state <= CSR_STATE_IDLE;
            end
        endcase
    end
end

reg  [`CSR_BUS_WIDTH-1:0]              csr_waddr;
reg                                    csr_waddr_vld;
reg  [`DATA_BUS_WIDTH-1:0]             csr_wdata;

always @(*) begin
    case (csr_state)
        CSR_STATE_MEPC: begin
            csr_waddr     = `CSR_MEPC;
            csr_waddr_vld = `VALID;
            csr_wdata     = break_addr;
        end

        CSR_STATE_MSTATUS: begin
            csr_waddr     = `CSR_MSTATUS;
            csr_waddr_vld = `VALID;
            // TODO-10: Save mstatus on trap entry.
            // Move MIE into MPIE and clear MIE.
            csr_wdata     = `ZERO_WORD;
        end

        CSR_STATE_MCAUSE: begin
            csr_waddr     = `CSR_MCAUSE;
            csr_waddr_vld = `VALID;
            csr_wdata     = break_cause;
        end

        CSR_STATE_MRET: begin
            csr_waddr     = `CSR_MSTATUS;
            csr_waddr_vld = `VALID;
            // TODO-11: Restore mstatus on mret.
            // Restore MIE from MPIE and clear MPIE.
            csr_wdata     = `ZERO_WORD;
        end

        default: begin
            csr_waddr     = {`CSR_BUS_WIDTH{1'b0}};
            csr_waddr_vld = `INVALID;
            csr_wdata     = `ZERO_WORD;
        end
    endcase
end

reg                                    int_jump_flag;
reg  [`DATA_BUS_WIDTH-1:0]             int_jump_addr;

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        int_jump_flag <= `INVALID;
        int_jump_addr <= `ZERO_WORD;
    end
    else begin
        case (csr_state)
            CSR_STATE_MCAUSE: begin
                // TODO-12: Jump to mtvec after trap CSR writes.
                int_jump_flag <= `INVALID;
                int_jump_addr <= `ZERO_WORD;
            end

            CSR_STATE_MRET: begin
                // TODO-13: Jump to mepc on mret.
                int_jump_flag <= `INVALID;
                int_jump_addr <= `ZERO_WORD;
            end

            default: begin
                int_jump_flag <= `INVALID;
                int_jump_addr <= `ZERO_WORD;
            end
        endcase
    end
end

assign csr_waddr_o     = csr_waddr;
assign csr_waddr_vld_o = csr_waddr_vld;
assign csr_wdata_o     = csr_wdata;

assign hold_flag_o = (csr_state != CSR_STATE_IDLE)
                  && (csr_state != CSR_STATE_WAIT);

assign jump_flag_o = int_jump_flag;
assign jump_addr_o = int_jump_addr;

endmodule
