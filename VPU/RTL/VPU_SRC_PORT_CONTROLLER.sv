`include "VPU_PKG.svh"

module VPU_SRC_PORT_CONTROLLER
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,

    //From REQ_IF.src                            
    input   wire                            rvalid_i,
    input   wire [OPERAND_ADDR_WIDTH-1:0]   raddr_i,
    input   wire                            valid_i,
    output  logic                           ready_o,

    // From/To VPU_CONTROLLER
    input   wire                            start_i,
    output  logic                           done_o,

    // From/To OPERAND_QUEUE
    output  logic   [SRAM_DATA_WIDTH-1:0]   operand_fifo_wdata_o,
    output  logic                           operand_fifo_wren_o,

    // From/To SRAM_INCT
    SRAM_R_PORT_IF.host                     sram_rd_if
);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 1'b0;
    localparam  S_VALID                     = 1'b1;

    // State
    logic                                   state,      state_n;

    // SRAM_R_PORT_IF
    logic                                   req,        req_n;
    logic   [SRAM_BANK_CNT_LG2-1:0]         rid,        rid_n;
    logic   [SRAM_BANK_DEPTH_LG2-1:0]       addr,       addr_n;
    logic                                   reb,        reb_n;
    logic                                   rlast,      rlast_n;

    // OPERAND_QUEUE
    logic                                   operand_fifo_wren;

    // To VPU_CONTROLLER
    logic                                   done;
                            
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            // SRAM IF
            state                           <= S_IDLE;
            req                             <= 1'b0;
            rid                             <= {SRAM_BANK_CNT_LG2{1'b0}};
            addr                            <= {SRAM_BANK_DEPTH_LG2{1'b0}};
            reb                             <= 1'b1;
            rlast                           <= 1'b0;
        end
        else begin
            // SRAM IF
            state                           <= state_n;
            req                             <= req_n;
            rid                             <= rid_n;
            addr                            <= addr_n;
            reb                             <= reb_n;
            rlast                           <= rlast_n;
        end
    end

    always_comb begin
        state_n                             = state;
        req_n                               = req;
        rid_n                               = rid;
        addr_n                              = addr;
        reb_n                               = reb;
        rlast_n                             = rlast;

        operand_fifo_wren                   = 1'b0;
        done                                = 1'b0;
        
        case(state)
            S_IDLE: begin
                done                        = 1'b1;
                if(start_i & rvalid_i) begin
                    state_n                 = S_VALID;
                    req_n                   = 1'b1;
                    rid_n                   = get_bank_id(raddr_i);
                    addr_n                  = get_raddr(raddr_i);
                    reb_n                   = 1'b0;
                    rlast_n                 = 1'b1;
                end
            end

            S_VALID: begin
                if(sram_rd_if.ack && sram_rd_if.req) begin
                    req_n                   = 1'b0;
                    rid_n                   = {SRAM_BANK_CNT_LG2{1'b0}};
                    addr_n                  = {SRAM_BANK_DEPTH_LG2{1'b0}};
                    reb_n                   = 1'b1;
                    rlast_n                 = 1'b0;
                end
                if(sram_rd_if.rvalid) begin
                    operand_fifo_wren       = 1'b1;
                    state_n                 = S_IDLE;
                end
            end
        endcase
    end

    // SRAM_IF
    assign  sram_rd_if.req                          = req;
    assign  sram_rd_if.rid                          = rid;
    assign  sram_rd_if.addr                         = addr;
    assign  sram_rd_if.reb                          = reb;
    assign  sram_rd_if.rlast                        = rlast;

    // OPERAND_QUEUE
    assign  operand_fifo_wdata_o                    = sram_rd_if.rdata;
    assign  operand_fifo_wren_o                     = operand_fifo_wren;
    
    // VPU_CONTROLLER
    assign  done_o                                  = done;
    
endmodule