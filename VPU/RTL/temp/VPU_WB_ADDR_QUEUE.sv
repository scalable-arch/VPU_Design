`include "VPU_PKG.svh"

module VPU_WB_ADDR_QUEUE
#(
    //...
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From VPU_CONTROLLER
    input   wire                            reset_cmd_i,
    
    // From/To REQ_IF
    input   wire                            valid_i,
    input   [OPERAND_ADDR_WIDTH-1:0]        waddr_i
);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 1'b0;
    localparam  S_PUSH                      = 1'b1;

    logic                                   addr_fifo_wren;
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state                           <= S_IDLE;
        end else begin
            state                           <= state_n;
        end
    end

    always_comb begin
        state_n                             = state;
        addr_fifo_wren                      = 1'b0;
        
        case(state) 
            S_IDLE: begin
                if(valid_i) begin
                    state_n                 = S_PUSH;
                    addr_fifo_wren          = 1'b1;
                end
            end
            
            S_PUSH: begin
                addr_fifo_wren              = 1'b0;
                if(reset_cmd_i) begin
                    state_n                 = S_IDLE;
                end
            end
            
        endcase
    end
    SAL_SA_FIFO #(
        DEPTH_LG2                           = REQ_FIFO_DEPTH_LG2,
        DATA_WIDTH                          = OPERAND_ADDR_WIDTH,
        AFULL_THRES                         = (1 << DEPTH_LG2),
        AEMPTY_THRES                        = 0,
        RDATA_FF_OUT                        = 0,
        RST_MEM                             = 0
    ) WB_ADDR_FIFO (
        .clk                                (clk),
        .rst_n                              (rst_n), 
        .full_o                             (),
        .afull_o                            (),
        .wren_i                             (addr_fifo_wren),
        .wdata_i                            (waddr_i),   
        .empty_o                            (),
        .aempty_o                           (),
        .rden_i                             (),
        .rdata_o                            (),   
        .debug_o                            ()
    );
endmodule