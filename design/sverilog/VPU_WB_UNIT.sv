`include "VPU_PKG.svh"

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
    input   wire [VPU_PKG::EXEC_UNIT_DATA_WIDTH-1:0] wb_data_i,
    input   VPU_PKG::vpu_instr_decoded_t    instr_decoded_i,
    // SRAM_W_PORT
    VPU_DST_PORT_IF.host                    vpu_dst0_port_if
);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 1'b0;
    localparam  S_VALID                     = 1'b1;

    logic                                   state, state_n;

    // VPU_CONTROLLER
    logic                                   done;

    // SRAM_W_PORT_IF
    logic                                   req, req_n;
    logic                                   web, web_n;
    logic                                   wlast, wlast_n;

    logic   [EXEC_CNT_LG2-1:0]              cnt, cnt_n;
    logic   [EXEC_UNIT_DATA_WIDTH-1:0]      wb_data [EXEC_CNT];
    
    wire    [SRAM_DATA_WIDTH-1:0]           wdata;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state                           <= S_IDLE;
            req                             <= 1'b0;
            web                             <= 1'b1;
            wlast                           <= 1'b0;
            cnt                             <= 1'b0;
            for(int i = 0; i < EXEC_CNT; i++) begin
                wb_data[i]                  <= {(EXEC_UNIT_DATA_WIDTH){1'b0}};
            end
        end else begin
            state                           <= state_n;
            req                             <= req_n;
            web                             <= web_n;
            wlast                           <= wlast_n;
            cnt                             <= cnt_n;
            if(wb_data_valid_i) begin
                if(instr_decoded_i.op_func.op_type == EXEC) begin
                    wb_data[cnt]            <= wb_data_i;
                end else begin
                    for(int i = 0; i < EXEC_CNT; i++) begin
                        wb_data[i]          <= wb_data_i;
                    end
                end
            end
        end
    end

    always_comb begin
        state_n                             = state;
        req_n                               = req;
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
                    web_n                   = 1'b0;
                    wlast_n                 = 1'b1;
                    state_n                 = S_VALID;
                end
            end
            
            S_VALID: begin
                if(vpu_dst0_port_if.ack && vpu_dst0_port_if.req) begin
                    req_n                   = 1'b0;
                    web_n                   = 1'b1;
                    wlast_n                 = 1'b0;
                    state_n                 = S_IDLE;
                end
            end
        endcase
    end

    assign  vpu_dst0_port_if.req            = req;
    assign  vpu_dst0_port_if.wid            = get_bank_id(instr_decoded_i.waddr);
    assign  vpu_dst0_port_if.addr           = get_bank_id(instr_decoded_i.waddr);
    assign  vpu_dst0_port_if.web            = web;
    assign  vpu_dst0_port_if.wlast          = wlast;
    assign  vpu_dst0_port_if.wdata          = wdata;

    genvar j;
    generate
        for(j = 0; j < EXEC_CNT; j++) begin : ASSIGN_WB_DATA
            assign wdata[j*EXEC_UNIT_DATA_WIDTH+:EXEC_UNIT_DATA_WIDTH] = wb_data[j];
        end
    endgenerate
    assign  done_o                          = done;

endmodule