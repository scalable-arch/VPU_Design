//`include "/home/sg05060/generic_npu/src/VPU/RTL/Header/VPU_PKG.svh"
import VPU_PKG::*;

module VPU_TOP_WRAPPER (
    input   wire                            clk,
    input   wire                            rst_n,

    // VPU_REQ_IF
    // REQ from/to Host
    output                                  ready_o,
    input   VPU_PKG::vpu_h2d_req_instr_t    h2d_req_instr_i,
    input                                   valid_i,

    // VPU_SRC_PORT_IF
    output  [SRAM_R_PORT_CNT-1:0]           rreq_o,
    output  [SRAM_BANK_CNT_LG2-1:0]         rid_o     [SRAM_R_PORT_CNT],
    output  [SRAM_BANK_DEPTH_LG2-1:0]       raddr_o    [SRAM_R_PORT_CNT],
    output  [SRAM_R_PORT_CNT-1:0]           reb_o,
    output  [SRAM_R_PORT_CNT-1:0]           rlast_o,

    input   [SRAM_R_PORT_CNT-1:0]           rack_i,
    input   [SRAM_DATA_WIDTH-1:0]           rdata_i   [SRAM_R_PORT_CNT],
    input   [SRAM_R_PORT_CNT-1:0]           rvalid_i,

    // VPU_DST_PORT_IF
    output                                  wreq_o,
    output  [SRAM_BANK_CNT_LG2-1:0]         wid_o,
    output  [SRAM_BANK_DEPTH_LG2-1:0]       waddr_o,
    output                                  web_o,
    output                                  wlast_o,
    output  [SRAM_DATA_WIDTH-1:0]           wdata_o,

    input                                   wack_i
);
    // VPU_REQ_IF
    VPU_REQ_IF  vpu_req_if  (.clk(clk), .rst_n(rst_n));

    assign  vpu_req_if.h2d_req_instr        = h2d_req_instr_i;
    assign  vpu_req_if.valid                = valid_i;
    assign  ready_o                         = vpu_req_if.ready;

    // VPU_SRC_PORT_IF
    VPU_SRC_PORT_IF vpu_src0_port_if (.clk(clk), .rst_n(rst_n));
    
    assign  vpu_src0_port_if.ack             = rack_i[0];
    assign  vpu_src0_port_if.rdata           = rdata_i[0];
    assign  vpu_src0_port_if.rvalid          = rvalid_i[0];
    assign  rreq_o[0]                        = vpu_src0_port_if.req;
    assign  rid_o[0]                         = vpu_src0_port_if.rid;
    assign  raddr_o[0]                       = vpu_src0_port_if.addr;
    assign  reb_o[0]                         = vpu_src0_port_if.reb;
    assign  rlast_o[0]                       = vpu_src0_port_if.rlast;

    // VPU_SRC_PORT_IF
    VPU_SRC_PORT_IF vpu_src1_port_if (.clk(clk), .rst_n(rst_n));
    
    assign  vpu_src1_port_if.ack             = rack_i[1];
    assign  vpu_src1_port_if.rdata           = rdata_i[1];
    assign  vpu_src1_port_if.rvalid          = rvalid_i[1];
    assign  rreq_o[1]                        = vpu_src1_port_if.req;
    assign  rid_o[1]                         = vpu_src1_port_if.rid;
    assign  raddr_o[1]                       = vpu_src1_port_if.addr;
    assign  reb_o[1]                         = vpu_src1_port_if.reb;
    assign  rlast_o[1]                       = vpu_src1_port_if.rlast;

    // VPU_SRC_PORT_IF
    VPU_SRC_PORT_IF vpu_src2_port_if (.clk(clk), .rst_n(rst_n));
    
    assign  vpu_src2_port_if.rdata           = rdata_i[2];
    assign  vpu_src2_port_if.rvalid          = rvalid_i[2];
    assign  vpu_src2_port_if.ack             = rack_i[2];
    assign  rreq_o[2]                        = vpu_src2_port_if.req;
    assign  rid_o[2]                         = vpu_src2_port_if.rid;
    assign  raddr_o[2]                       = vpu_src2_port_if.addr;
    assign  reb_o[2]                         = vpu_src2_port_if.reb;
    assign  rlast_o[2]                       = vpu_src2_port_if.rlast;

    // VPU_DST_PORT_IF
    VPU_DST_PORT_IF vpu_dst0_port_if (.clk(clk), .rst_n(rst_n));

    assign  vpu_dst0_port_if.ack             = wack_i;
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
        .vpu_req_if                         (vpu_req_if),
        .vpu_src0_port_if                   (vpu_src0_port_if),
        .vpu_src1_port_if                   (vpu_src1_port_if),
        .vpu_src2_port_if                   (vpu_src2_port_if),
        .vpu_dst0_port_if                   (vpu_dst0_port_if)
    );
endmodule