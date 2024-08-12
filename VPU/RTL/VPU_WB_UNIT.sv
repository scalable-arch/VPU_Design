module VPU_WB_UNIT
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From/To VPU_CONTROLLER
    input   wire                            start_i,
    output  wire                            done_o,

    // From VPU_LANE
    input   wire                            wb_data_valid_i,
    input   [OPERAND_WIDTH*VLANE_CNT-1:0]   wb_data_i,

    // REQ_IF
    REQ_IF.dst                              req_if,

    // SRAM_W_PORT
    SRAM_W_PORT_IF.host                     sram_w_port_if,
);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 1'b0;
    localparam  S_VALID                     = 1'b1;

    logic                                   state, state_n;

    // VPU_CONTROLLER
    logic                                   done;

    // SRAM_W_PORT_IF
    logic                                   req,        req_n;
    logic   [SRAM_BANK_CNT_LG2-1:0]         wid,        wid_n;
    logic   [SRAM_BANK_DEPTH_LG2-1:0]       addr,       addr_n;
    logic                                   web,        web_n;
    logic                                   wlast,      wlast_n;

    logic   [EXEC_CNT_LG2-1:0]              cnt,        cnt_n;
    logic   [OPERAND_WIDTH*VLANE_CNT-1:0]   wb_data [EXEC_CNT];

    
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state                           <= S_IDLE;
            req                             <= 1'b0;
            wid                             <= {SRAM_BANK_CNT_LG2{1'b0}};
            addr                            <= {SRAM_BANK_DEPTH_LG2{1'b0}};
            web                             <= 1'b1;
            wlast                           <= 1'b0;
            cnt                             <= 1'b0;
            for(int i = 0; i < EXEC_CNT; i++) begin
                wb_data[i]                  <= {(OPERAND_WIDTH*VLANE_CNT){1'b0}};
            end
        end else begin
            state                           <= state_n;
            req                             <= req_n;
            wid                             <= wid_n;
            addr                            <= addr_n;
            web                             <= web_n;
            wlast                           <= wlast_n;
            cnt                             <= cnt_n;
            if(wb_data_valid_i) begin
                wb_data[cnt]                <= wb_data_i;
            end
        end
    end

    always_comb begin
        state_n                             = state;
        req_n                               = req;
        wid_n                               = wid;
        addr_n                              = addr;
        web_n                               = web;
        wlast_n                             = wlast;
        cnt_n                               = cnt;

        done                                = 1'b0;

        if(cnt == EXEC_CNT) begin
            cnt_n                           = {EXEC_CNT_LG2{1'b0}};
        end else if(wb_data_valid_i) begin
            cnt_n                           = cnt + 'd1;
        end

        case(state)
            S_IDLE: begin
                done                        = 1'b1;
                if(start_i) begin
                    req_n                   = 1'b1;
                    wid_n                   = get_bank_id(req_if.waddr);
                    addr_n                  = get_waddr(req_if.waddr);
                    web_n                   = 1'b0;
                    wlast_n                 = 1'b1;
                    state_n                 = S_VALID;
                end
            end
            
            S_VALID: begin
                if(sram_w_port_if.ack && sram_w_port_if.req) begin
                    req_n                   = 1'b0;
                    wid_n                   = {SRAM_BANK_CNT_LG2{1'b0}};
                    addr_n                  = {SRAM_BANK_DEPTH_LG2{1'b0}};
                    web_n                   = 1'b1;
                    wlast_n                 = 1'b0;
                    state_n                 = S_IDLE;
                end
            end
        endcase
    end

    
    assign  sram_w_port_if.req              = req;
    assign  sram_w_port_if.wid              = wid;
    assign  sram_w_port_if.addr             = addr;
    assign  sram_w_port_if.web              = web;
    assign  sram_w_port_if.wlast            = wlast;
    assign  sram_w_port_if.wdata            = wb_data;

    assign  done_o                          = done;

endmodule