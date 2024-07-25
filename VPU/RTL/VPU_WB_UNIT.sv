module VPU_WB_UNIT
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From/To VPU_CONTROLLER
    input   wire                            reset_cmd_i,
    output  wire                            done_o,

    // From VPU_LANE
    input   wire                            wb_data_wren_i,
    input   [OPERAND_WIDTH*VLANE_CNT-1:0]   wb_data_i,

    // REQ_IF
    REQ_IF.dst                              req_if,

    // SRAM_W_PORT
    SRAM_W_PORT_IF.host                     sram_w_port_if,
);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 2'b00;
    localparam  S_PACK                      = 2'b01;
    localparam  S_WAIT                      = 2'b10;
    localparam  S_DONE                      = 2'b11;


    // VPU_CONTROLLER
    logic                                   done;

    // SRAM_W_PORT_IF
    logic                                   req,        req_n;
    logic   [SRAM_BANK_CNT_LG2-1:0]         wid,        wid_n;
    logic   [SRAM_BANK_DEPTH_LG2-1:0]       addr,       addr_n;
    logic                                   web,        web_n;
    logic                                   wlast,      wlast_n;

    logic   [SRAM_DATA_WIDTH-1:0]           wdata;

    // ADDR_QUEUE
    logic                                   wb_addr_queue_wren;
    logic   [OPERAND_ADDR_WIDTH-1:0]        wb_addr_queue_wdata;
    logic                                   wb_addr_queue_full;
    logic                                   wb_addr_queue_afull;
    logic                                   wb_addr_queue_empty;
    logic                                   wb_addr_queue_aempty;
    
    logic                                   wb_addr_queue_rden;
    logic   [OPERAND_ADDR_WIDTH-1:0]        wb_addr_queue_rdata;

    // DATA_QUEUE
    logic                                   wb_data_queue_wren;
    logic   [OPERAND_WIDTH*VLANE_CNT-1:0]   wb_data_queue_wdata;
    logic                                   wb_data_queue_full;
    logic                                   wb_data_queue_afull;
    logic                                   wb_data_queue_empty;
    logic                                   wb_data_queue_aempty;

    logic                                   wb_data_queue_rden;
    logic   [OPERAND_WIDTH*VLANE_CNT-1:0]   wb_data_queue_rdata;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state                           <= S_IDLE;
            req                             <= 1'b0;
            wid                             <= {SRAM_BANK_CNT_LG2{1'b0}};
            addr                            <= {SRAM_BANK_DEPTH_LG2{1'b0}};
            web                             <= 1'b1;
            wlast                           <= 1'b0;
        end else begin
            state                           <= state_n;
            req                             <= req_n;
            wid                             <= wid_n;
            addr                            <= addr_n;
            web                             <= web_n;
            wlast                           <= wlast_n;
        end
    end

    always_comb begin
        state_n                             = state;
        req_n                               = req;
        wid_n                               = wid;
        addr_n                              = addr;
        web_n                               = web;
        wlast_n                             = wlast;
        
        wb_addr_queue_wren                  = 1'b0;
        wb_addr_queue_rden                  = 1'b0;
        //data_queue_wren                     = 1'b0;   
        wb_data_queue_rden                  = 1'b0; 
        
        done                                = 1'b0;

        case(state)
            S_IDLE: begin
                if(req_if.valid) begin
                    state_n                 = S_PACK;
                    wb_addr_queue_wren      = 1'b1;
                end
            end
            
            S_PACK: begin
                if(!wb_data_queue_empty) begin
                        state_n             = S_WAIT;
                        req_n               = 1'b1;
                        wid_n               = get_bank_id(wb_addr_queue_rdata);
                        addr_n              = get_waddr(wb_addr_queue_rdata);
                        web_n               = 1'b0;
                        wlast_n             = 1'b1;
                end
            end
            
            S_WAIT: begin
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
                done                        = 1'b1;
                if(reset_cmd_i) begin
                    state_n                 = S_IDLE;
                    wb_addr_queue_rden      = 1'b1; 
                    wb_data_queue_rden      = 1'b1; 
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
    ) WB_ADDR_QUEUE (
        .clk                                (clk),
        .rst_n                              (rst_n), 
        .full_o                             (),
        .afull_o                            (),
        .wren_i                             (wb_addr_queue_wren),
        .wdata_i                            (wb_addr_queue_wdata),   
        .empty_o                            (wb_addr_queue_empty),
        .aempty_o                           (wb_addr_queue_aempty),
        .rden_i                             (wb_addr_queue_rden),
        .rdata_o                            (wb_addr_queue_rdata),   
        .debug_o                            ()
    );

    VPU_NRW_FIFO #(
        .DEPTH_LG2                          ($clog2(OPERAND_QUEUE_DEPTH)),
        .WRDATA_WIDTH                       (OPERAND_WIDTH*VLANE_CNT),
        .RDDATA_WIDTH                       (SRAM_DATA_WIDTH),
        .RST_MEM                            (0) 
    ) WB_DATA_QUEUE (   
        .rst_n                              (rst_n),

        .wrclk                              (clk),
        .wren_i                             (wb_data_queue_wren),
        .wdata_i                            (wb_data_queue_wdata),
        .wrempty_o                          (),
        .wrfull_o                           (wb_data_queue_full),
        
        .rdclk                              (clk),
        .rden_i                             (wb_data_queue_rden),
        .rdata_o                            (wb_data_queue_rdata),
        .rdempty_o                          (wb_data_queue_empty),
        .rdfull_o                           ()
    );

    
    assign  sram_w_port_if.req              = req;
    assign  sram_w_port_if.wid              = wid;
    assign  sram_w_port_if.addr             = addr;
    assign  sram_w_port_if.web              = web;
    assign  sram_w_port_if.wlast            = wlast;
    assign  sram_w_port_if.wdata            = wb_data_queue_rdata;

    assign  wb_addr_queue_wdata             = req_if.waddr;

    assign  wb_data_queue_wdata             = wb_data_i;
    assign  wb_data_queue_wren              = wb_data_valid_i;

    assign  done_o                          = done;

endmodule