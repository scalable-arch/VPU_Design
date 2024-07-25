`include "VPU_PKG.svh"

module VPU_DECODER
#(
    //...
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    VPU_IF.device                           vpu_if,
    
    output  wire                            aempty_o,
    output  wire                            empty_o,
    
    //From VPU_Controller
    input   wire                            rden_i,

    REQ_IF.src                              req_if        
);
    import VPU_PKG::*;

    //logic   wire                            rden;
    logic   [INSTR_WIDTH-1:0]               rdata;
    logic   wire                            empty;
    logic   wire                            aempty;

    //REQ_IF
    logic                                   rvalid  [SRAM_R_PORT_CNT];
    logic   [OPERAND_ADDR_WIDTH-1:0]        raddr   [SRAM_R_PORT_CNT];
    logic   [VEC_LEN_LG2-1:0]               vlen; //skip
    logic   [OPERAND_ADDR_WIDTH-1:0]        waddr; //skip
    logic                                   valid;

    always_comb begin
        valid                               = 1'b0;
        for(int i = 0; i < SRAM_R_PORT_CNT; i = i+1) begin
            rvalid[i]                       = 1'b0;
            raddr[i]                        = {SRAM_BANK_DEPTH_LG2{1'b0}};
        end

        if(!empty) begin
            valid                           = 1'b1;
            for(int i = 0; i < SRAM_R_PORT_CNT; i = i+1) begin
                if(/*opcode decoding*/) begin
                    rvalid[i]               = 1'b1;
                    //raddr[i]                = vpu_if.h2d_req_instr_i[(i+1)*(OPERAND_ADDR_WIDTH)+:OPERAND_ADDR_WIDTH];
                    raddr[i]                = get_src_operand(rdata,i);
                end
            end
        end
    end

    SAL_SA_FIFO #(
        DEPTH_LG2                           = REQ_FIFO_DEPTH_LG2,
        DATA_WIDTH                          = INSTR_WIDTH,
        AFULL_THRES                         = (1 << DEPTH_LG2),
        AEMPTY_THRES                        = 0,
        RDATA_FF_OUT                        = 0,
        RST_MEM                             = 0
    ) REQ_FIFO (
        .clk                                (clk),
        .rst_n                              (rst_n), 
        .full_o                             (),
        .afull_o                            (vpu_if.afull),
        .wren_i                             (vpu_if.we),
        .wdata_i                            (vpu_if.h2d_req_instr_i),   
        .empty_o                            (empty),
        .aempty_o                           (aempty),
        .rden_i                             (rden_i),
        .rdata_o                            (rdata),   
        .debug_o                            ()
    );
    
    // REQ_IF
    assign  req_if.rvalid                   = rvalid;
    assign  req_if.raddr                    = raddr;
    assign  req_if.vlen                     = vlen;
    assign  req_if.waddr                    = waddr;
    assign  req_if.valid                    = valid;
endmodule