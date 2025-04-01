module VPU_TOP_XLINX_WRAPPER 
#(
    parameter   SRAM_R_PORT_CNT             = 3
  , parameter   SRAM_BANK_CNT               = 4
  , parameter   SRAM_BANK_CNT_LG2           = 2 // $clog2(SRAM_BANK_CNT)
  , parameter   SRAM_BANK_DEPTH             = 1024
  , parameter   SRAM_BANK_DEPTH_LG2         = 10 //$clog2(SRAM_BANK_DEPTH)
  , parameter   SRAM_DATA_WIDTH             = 512
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    // VPU_REQ_IF
    // REQ from/to Host
    output  wire                            ready,
    input   wire    [7:0]                   opcode,
    input   wire    [23:0]                  dst0,
    input   wire    [23:0]                  src0,
    input   wire    [23:0]                  src1,
    input   wire    [23:0]                  src2,
    input   wire    [23:0]                  imm,
    input   wire                            valid,

    // VPU_SRC_PORT_IF
    output  wire    [SRAM_R_PORT_CNT-1:0]           rreq,
    output  wire    [(SRAM_BANK_CNT_LG2*SRAM_R_PORT_CNT)-1:0]   rid,
    output  wire    [(SRAM_BANK_DEPTH_LG2*SRAM_R_PORT_CNT)-1:0] raddr,
    output  wire    [SRAM_R_PORT_CNT-1:0]           reb,
    output  wire    [SRAM_R_PORT_CNT-1:0]           rlast,

    input   wire[SRAM_R_PORT_CNT-1:0]           rack,
    input   wire[(SRAM_DATA_WIDTH*SRAM_R_PORT_CNT)-1:0] rdata,
    input   wire[SRAM_R_PORT_CNT-1:0]           rvalid,

    // VPU_DST_PORT_IF
    output  wire                                wreq,
    output  wire[SRAM_BANK_CNT_LG2-1:0]         wid,
    output  wire[SRAM_BANK_DEPTH_LG2-1:0]       waddr,
    output  wire                                web,
    output  wire                                wlast,
    output  wire[SRAM_DATA_WIDTH-1:0]           wdata,
    input    wire                               wack
);
    // VPU_TOP_WRAPPER
    VPU_TOP_WRAPPER                             u_vpu_wrapper 
    (
        .clk                                (clk)
      , .rst_n                              (rst_n)

      , .ready_o                            (ready)
      , .opcode                             (opcode)
      , .dst0                               (dst0)
      , .src0                               (src0)
      , .src1                               (src1)
      , .src2                               (src2)
      , .imm                                (imm)
      , .valid_i                            (valid)

    // VPU_SRC_PORT_IF
      , .rreq_o                             (rreq)
      , .rid_o                              (rid)
      , .raddr_o                            (raddr)
      , .reb_o                              (reb)
      , .rlast_o                            (rlast)
      , .rack_i                             (rack)
      , .rdata_i                            (rdata)
      , .rvalid_i                           (rvalid)

    // VPU_DST_PORT_IF
      , .wreq_o                             (wreq)
      , .wid_o                              (wid)
      , .waddr_o                            (waddr)
      , .web_o                              (web)
      , .wlast_o                            (wlast)
      , .wdata_o                            (wdata)
      , .wack_i                             (wack)
    );
endmodule