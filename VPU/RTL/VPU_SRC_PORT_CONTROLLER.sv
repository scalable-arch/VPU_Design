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
    input   wire                            reset_cmd_i,
    output  logic                           done_o,

    // From/To OPERAND_QUEUE
    output  logic [SRAM_DATA_WIDTH-1:0]     wdata_o,
    output  logic                           wren_o,
    input   wire                            wrempty_i,
    input   wire                            wrfull_i,

    // From/To SRAM_INCT
    SRAM_R_PORT_IF.host                     sram_rd_if
);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 2'b00;
    localparam  S_VALID                     = 2'b01;
    localparam  S_WAIT                      = 2'b10;
    localparam  S_DONE                      = 2'b11;


    // State
    logic   [1:0]                           state,      state_n;

    // SRAM_R_PORT_IF
    logic                                   req,        req_n;
    logic   [SRAM_BANK_CNT_LG2-1:0]         rid,        rid_n;
    logic   [SRAM_BANK_DEPTH_LG2-1:0]       addr,       addr_n;
    logic                                   reb,        reb_n;
    logic                                   rlast,      rlast_n;

    // To OPERAND_QUEUE
    logic                                   wren;

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
    
        wren                                = 1'b0;
        done                                = 1'b0;
        
        case(state)
            S_IDLE: begin
                if(valid_i) begin
                    if(rvalid_i) begin
                        state_n             = S_VALID;
                        req_n               = 1'b1;
                        rid_n               = get_bank_id(raddr_i);
                        addr_n              = get_raddr(raddr_i);
                        reb_n               = 1'b0;
                        rlast_n             = 1'b1;
                    end else begin
                        state_n             = S_DONE;
                    end
                end
            end

            S_VALID: begin
                if(sram_rd_if.ack && sram_rd_if.req) begin
                    state_n                 = S_WAIT;
                    req_n                   = 1'b0;
                    rid_n                   = {SRAM_BANK_CNT_LG2{1'b0}};
                    addr_n                  = {SRAM_BANK_DEPTH_LG2{1'b0}};
                    reb_n                   = 1'b1;
                    rlast_n                 = 1'b0;
                end
            end

            S_WAIT: begin
                if(sram_rd_if.rvalid) begin
                    state_n                 = S_DONE;
                    wren                    = 1'b1;
                end
            end

            S_DONE: begin
                done                        = 1'b1;
                if(reset_cmd_i) begin
                    state_n                 = S_IDLE;
                end
            end
        endcase
    end

    // SRAM_IF
    sram_rd_if.req                          = req;
    sram_rd_if.rid                          = rid;
    sram_rd_if.addr                         = addr;
    sram_rd_if.reb                          = reb;
    sram_rd_if.rlast                        = rlast;

    // OPERAND_QUEUE
    wren_o                                  = wren;
    wdata_o                                 = sram_rd_if.rdata;

    // VPU_CONTROLLER
    done_o                                  = done;
    
endmodule