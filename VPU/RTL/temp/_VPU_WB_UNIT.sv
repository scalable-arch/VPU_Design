module VPU_WB_UNIT
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From VPU_CONTROLLER
    input   wire                            reset_cmd_i,

    //input   wire                            wb_start_i,
    input   wire                            wb_data_valid_i,
    input   [OPERAND_WIDTH*VLANE_CNT-1:0]   wb_data_i,
    output  logic                           wb_done_o,

    REQ_IF.dst                              req_if,
    SRAM_W_PORT_IF.host                     w_port_if,
);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 2'b00;
    localparam  S_PACK                      = 2'b01;
    localparam  S_WB                        = 2'b10;
    localparam  S_DONE                      = 2'b11;

    logic                                   wb_done;
    // SRAM_W_PORT_IF
    logic                                   req,        req_n;
    logic   [SRAM_BANK_CNT_LG2-1:0]         wid,        wid_n;
    logic   [SRAM_BANK_DEPTH_LG2-1:0]       addr,       addr_n;
    logic                                   web,        web_n;
    logic                                   wlast,      wlast_n;

    logic   [DIM_SIZE-1:0]                  wb_data,    wb_data_n;
    logic   [EXEC_CNT_LG2-1:0]              wb_data_wptr, wb_data_wptr_n;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state                           <= S_IDLE;
            wb_data                         <= {DIM_SIZE{1'b0}};
            wb_data_wptr                    <= {EXEC_CNT_LG2{1'b0}};

            req                             <= 1'b0;
            wid                             <= {SRAM_BANK_CNT_LG2{1'b0}};
            addr                            <= {SRAM_BANK_DEPTH_LG2{1'b0}};
            web                             <= 1'b1;
            wlast                           <= 1'b0;
        end else begin
            state                           <= state_n;
            wb_data                         <= wb_data_n;
            wb_data_wptr                    <= wb_data_wptr_n;

            req                             <= req_n;
            wid                             <= wid_n;
            addr                            <= addr_n;
            web                             <= web_n;
            wlast                           <= wlast_n;
        end
    end

    always_comb begin
        state_n                             = state;
        wb_data_n                           = wb_data;
        wb_data_wptr_n                      = wb_data_wptr;

        req_n                               = req;
        wid_n                               = wid;
        addr_n                              = addr;
        web_n                               = web;
        wlast_n                             = wlast;
        
        ready                               = 1'b0;
        done                                = 1'b0;
        wb_done                             = 1'b0;

        case(state)
            S_IDLE: begin
                if(req_if.valid) begin
                    state_n                 = S_PACK;
                end
            end
            
            S_PACK: begin
                if(wb_data_valid_i) begin
                    wb_data_n[wb_data_wptr+:(OPERAND_WIDTH*VLANE_CNT)] = wb_data_i;
                    wb_data_wptr_n          = wb_data_wptr + (OPCODE_WIDTH*VLANE_CNT);
                    if(wb_data_wptr_n == EXEC_CNT) begin
                        state_n             = S_WB;
                        wb_data_wptr_n      = {EXEC_CNT_LG2{1'b0}};
                        req_n               = 1'b1;
                        wid_n               = get_bank_id(req_if.waddr);
                        addr_n              = get_waddr(req_if.waddr);
                        web_n               = 1'b0;
                        wlast_n             = 1'b1;
                    end
                end
            end
            
            S_WB: begin
                if(w_port_if.ack && w_port_if.req) begin
                    state_n                 = S_DONE;
                    req_n                   = 1'b0;
                    wid_n                   = {SRAM_BANK_CNT_LG2{1'b0}};
                    addr_n                  = {SRAM_BANK_DEPTH_LG2{1'b0}};
                    web_n                   = 1'b1;
                    wlast_n                 = 1'b0;      
                end
            end
            
            S_DONE: begin
                wb_done                     = 1'b1;
                if(reset_cmd_i) begin
                    state_n                 = S_IDLE;
                end
            end
        endcase
    end

    assign  w_port_if.req                   = req;
    assign  w_port_if.wid                   = wid;
    assign  w_port_if.addr                  = addr;
    assign  w_port_if.web                   = web;
    assign  w_port_if.wlast                 = wlast;
    assign  w_port_if.wdata                 = wb_data_i;

    assign  wb_done_o                       = wb_done;

endmodule