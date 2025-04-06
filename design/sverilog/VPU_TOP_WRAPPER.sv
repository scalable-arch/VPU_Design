import VPU_PKG::*;

module VPU_TOP_WRAPPER (
    input   wire                            clk,
    input   wire                            rst_n,

    // VPU_REQ_IF
    // REQ from/to Host
    output  wire                            ready_o,
    input   wire    [7:0]                   opcode,
    input   wire    [23:0]                  dst0,
    input   wire    [23:0]                  src0,
    input   wire    [23:0]                  src1,
    input   wire    [23:0]                  src2,
    input   wire    [23:0]                  imm,
    input   wire                            valid_i,
    input   wire    [STREAM_ID_WIDTH-1:0]   stream_id_i,

    // VPU_RESPONSE_IF
    output  wire                            valid_o,
    output  wire    [STREAM_ID_WIDTH-1:0]   stream_id_o,
    input   wire                            ready_i,


    // VPU_SRC_PORT_IF
    output  wire  [SRAM_READ_PORT_CNT-1:0]                         rreq_o,
    output  wire  [(SRAM_BANK_CNT_LG2*SRAM_READ_PORT_CNT)-1:0]     rid_o,
    output  wire  [(SRAM_BANK_DEPTH_LG2*SRAM_READ_PORT_CNT)-1:0]   raddr_o,
    output  wire  [SRAM_READ_PORT_CNT-1:0]                         reb_o,
    output  wire  [SRAM_READ_PORT_CNT-1:0]                         rlast_o,
    input   wire  [SRAM_READ_PORT_CNT-1:0]                         rack_i,
    input   wire  [(SRAM_DATA_WIDTH*SRAM_READ_PORT_CNT)-1:0]       rdata_i,
    input   wire  [SRAM_READ_PORT_CNT-1:0]                         rvalid_i,

    // VPU_DST_PORT_IF
    output  wire                            wreq_o,
    output  wire [SRAM_BANK_CNT_LG2-1:0]    wid_o,
    output  wire [SRAM_BANK_DEPTH_LG2-1:0]  waddr_o,
    output  wire                            web_o,
    output  wire                            wlast_o,
    output  wire [SRAM_DATA_WIDTH-1:0]      wdata_o,
    input   wire                            wack_i
);
    // VPU_REQ_IF
    VPU_REQ_IF  vpu_req_if  (.clk(clk), .rst_n(rst_n));
    vpu_h2d_req_instr_t                     h2d_req_instr;
    assign  h2d_req_instr.opcode            = vpu_h2d_req_opcode_t'(opcode);
    assign  h2d_req_instr.dst0              = dst0;
    assign  h2d_req_instr.src0              = src0;
    assign  h2d_req_instr.src1              = src1;
    assign  h2d_req_instr.src2              = src2;
    assign  h2d_req_instr.imm               = imm;

    assign  vpu_req_if.h2d_req_instr        = h2d_req_instr;
    assign  vpu_req_if.stream_id            = stream_id_i;
    assign  vpu_req_if.valid                = valid_i;
    assign  ready_o                         = vpu_req_if.ready;

    // VPU_RESPONSE_IF
    VPU_REQ_IF  vpu_response_if  (.clk(clk), .rst_n(rst_n));
    assign  valid_o                         = vpu_response_if.valid;
    assign  stream_id_o                     = vpu_response_if.stream_id;
    assign  vpu_response_if.ready           = ready_i;

    // VPU_SRC_PORT_IF
    VPU_SRC_PORT_IF vpu_src0_port_if (.clk(clk), .rst_n(rst_n));
    
    assign  vpu_src0_port_if.ack            = rack_i[0];
    assign  vpu_src0_port_if.rdata          = rdata_i[(0*SRAM_DATA_WIDTH)+:SRAM_DATA_WIDTH];
    assign  vpu_src0_port_if.rvalid         = rvalid_i[0];
    assign  rreq_o[0]                       = vpu_src0_port_if.req;
    assign  rid_o[(0*SRAM_BANK_CNT_LG2)+:SRAM_BANK_CNT_LG2] = vpu_src0_port_if.rid;
    assign  raddr_o[(0*SRAM_BANK_DEPTH_LG2)+:SRAM_BANK_DEPTH_LG2] = vpu_src0_port_if.addr;
    assign  reb_o[0]                        = vpu_src0_port_if.reb;
    assign  rlast_o[0]                      = vpu_src0_port_if.rlast;

    // VPU_SRC_PORT_IF
    VPU_SRC_PORT_IF vpu_src1_port_if (.clk(clk), .rst_n(rst_n));
    
    assign  vpu_src1_port_if.ack            = rack_i[1];
    assign  vpu_src1_port_if.rdata          = rdata_i[(1*SRAM_DATA_WIDTH)+:SRAM_DATA_WIDTH];
    assign  vpu_src1_port_if.rvalid         = rvalid_i[1];
    assign  rreq_o[1]                       = vpu_src1_port_if.req;
    assign  rid_o[(1*SRAM_BANK_CNT_LG2)+:SRAM_BANK_CNT_LG2] = vpu_src1_port_if.rid;
    assign  raddr_o[(1*SRAM_BANK_DEPTH_LG2)+:SRAM_BANK_DEPTH_LG2] = vpu_src1_port_if.addr;
    assign  reb_o[1]                        = vpu_src1_port_if.reb;
    assign  rlast_o[1]                      = vpu_src1_port_if.rlast;

    // VPU_SRC_PORT_IF
    VPU_SRC_PORT_IF vpu_src2_port_if (.clk(clk), .rst_n(rst_n));

    assign  vpu_src2_port_if.ack            = rack_i[2];
    assign  vpu_src2_port_if.rdata          = rdata_i[(2*SRAM_DATA_WIDTH)+:SRAM_DATA_WIDTH];
    assign  vpu_src2_port_if.rvalid         = rvalid_i[2];
    assign  rreq_o[2]                       = vpu_src2_port_if.req;
    assign  rid_o[(2*SRAM_BANK_CNT_LG2)+:SRAM_BANK_CNT_LG2] = vpu_src2_port_if.rid;
    assign  raddr_o[(2*SRAM_BANK_DEPTH_LG2)+:SRAM_BANK_DEPTH_LG2] = vpu_src2_port_if.addr;
    assign  reb_o[2]                        = vpu_src2_port_if.reb;
    assign  rlast_o[2]                      = vpu_src2_port_if.rlast;

    // VPU_DST_PORT_IF
    VPU_DST_PORT_IF vpu_dst0_port_if (.clk(clk), .rst_n(rst_n));

    assign  vpu_dst0_port_if.ack            = wack_i;
    assign  wreq_o                          = vpu_dst0_port_if.req;
    assign  wid_o                           = vpu_dst0_port_if.wid;
    assign  waddr_o                         = vpu_dst0_port_if.addr;
    assign  web_o                           = vpu_dst0_port_if.web;
    assign  wlast_o                         = vpu_dst0_port_if.wlast;
    assign  wdata_o                         = vpu_dst0_port_if.wdata;

    //----------------------------------------------------------
    // design
    //----------------------------------------------------------
    VPU_TOP u_vpu
    (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .vpu_req_if                         (vpu_req_if.device),
        .vpu_response_if                    (vpu_response_if.device),
        .vpu_src0_port_if                   (vpu_src0_port_if.host),
        .vpu_src1_port_if                   (vpu_src1_port_if.host),
        .vpu_src2_port_if                   (vpu_src2_port_if.host),
        .vpu_dst0_port_if                   (vpu_dst0_port_if.host)
    );
endmodule