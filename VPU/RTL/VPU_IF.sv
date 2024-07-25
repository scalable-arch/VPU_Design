`include "VPU_PKG.svh"

interface VPU_IF
(
        input   wire                        clk,
        input   wire                        rst_n,
);
    import VPU_PKG::*;

    vpu_h2d_req_instr_t                     h2d_req_instr_i;
    logic                                   we;
    logic                                   afull;
    
    modport device (
        output      afull,
        input       h2d_req_instr_i, we
    );

    modport host (
        input       afull,
        output      h2d_req_instr_i, we
    );

    modport mon (
        input       afull,
        input       h2d_req_instr_i, we
    );

    modport dut (
        output      afull,
        input       h2d_req_instr_i, we
    );

    clocking drvClk @(posedge clk);
        output  h2d_req_instr_i;
        output  we;
        input   afull;
    endclocking: drvClk

    clocking iMonClk @(posedge clk);
        input  h2d_req_instr_i;
        input  we;
        input  afull;
    endclocking: iMonClk

    clocking oMonClk @(posedge clk);
        input  h2d_req_instr_i;
        input  we;
        input  afull;
    endclocking: oMonClk

endinterface

// VPU-Internal Interface
interface REQ_IF
(
    input   wire                        clk,
    input   wire                        rst_n,
);
    import VPU_PKG::*;

    logic   [OPCODE_WIDTH-1:0]          opcode;
    
    logic                               rvalid  [SRAM_R_PORT_CNT];
    logic   [OPERAND_ADDR_WIDTH-1:0]    raddr   [SRAM_R_PORT_CNT];
    logic   [VEC_LEN_LG2-1:0]           vlen;
    logic   [OPERAND_ADDR_WIDTH-1:0]    waddr;
    logic   [MAX_DELAY_LG2-1:0]         delay;
    logic                               valid;
    logic                               ready;
    
    modport src (
        output      opcode, rvalid, raddr, vlen, waddr, valid, delay
        input       ready
    );

    modport dst (
        input       opcode, rvalid, raddr, vlen, waddr, valid, delay
        output      ready
    );
    
    modport mon (
        input       opcode, rvalid, raddr, vlen, waddr, valid, delay
        input       ready
    );
endinterface

interface SRAM_R_PORT_IF
(
    input   wire                        clk,
    input   wire                        rst_n,
);
    import VPU_PKG::*;

    logic                               req;
    logic                               ack;
    logic   [SRAM_BANK_CNT_LG2-1:0]     rid;
    logic   [SRAM_BANK_DEPTH_LG2-1:0]   addr;
    logic                               reb;
    logic                               rlast;
    logic   [SRAM_DATA_WIDTH-1:0]       rdata;
    logic                               rvalid;

    modport host (
        output      req, rid, addr, reb, rlast,
        input       ack, rdata, rvalid
    );

    modport mon (
        input       req, ack, rid, addr, reb,
        input       rlast, rdata, rvalid
    );

endinterface

interface VPU_SRC_PORT_IF
(
    input   wire                        clk,
    input   wire                        rst_n,
);
    import VPU_PKG::*;

    logic                               req     [SRAM_R_PORT_CNT];
    logic                               ack     [SRAM_R_PORT_CNT];
    logic   [SRAM_BANK_CNT_LG2-1:0]     rid     [SRAM_R_PORT_CNT];
    logic   [SRAM_BANK_DEPTH_LG2-1:0]   addr    [SRAM_R_PORT_CNT];
    logic                               reb     [SRAM_R_PORT_CNT];
    logic                               rlast   [SRAM_R_PORT_CNT];
    logic   [SRAM_DATA_WIDTH-1:0]       rdata   [SRAM_R_PORT_CNT];
    logic                               rvalid  [SRAM_R_PORT_CNT];

    modport host (
        output      req, rid, addr, reb, rlast,
        input       ack, rdata, rvalid
    );

    modport mon (
        input       req, ack, rid, addr, reb,
        input       rlast, rdata, rvalid
    );

    modport dut (
        output      req, rid, addr, reb, rlast,
        input       ack, rdata, rvalid
    );

    clocking drvClk @(posedge clk);
        input   req;
        input   rid;
        input   addr;
        input   reb;
        input   rlast;
        output  ack;
        output  rdata;
        output  rvalid;
    endclocking: drvClk

    clocking iMonClk @(posedge clk);
        input   req;
        input   rid;
        input   addr;
        input   reb;
        input   rlast;
        input   ack;
        input   rdata;
        input   rvalid;
    endclocking: iMonClk

    clocking oMonClk @(posedge clk);
        input   req;
        input   rid;
        input   addr;
        input   reb;
        input   rlast;
        input   ack;
        input   rdata;
        input   rvalid;
    endclocking: oMonClk

endinterface

interface SRAM_W_PORT_IF
(
    input   wire                        clk,
    input   wire                        rst_n,
);
    import VPU_PKG::*;

    logic                               req;
    logic                               ack;
    logic   [SRAM_BANK_CNT_LG2-1:0]     wid;
    logic   [SRAM_BANK_DEPTH_LG2-1:0]   addr;
    logic                               web;
    logic                               wlast;
    logic   [SRAM_DATA_WIDTH-1:0]       wdata;

    modport host (
        output      req, wid, addr, web, wlast, wdata,
        input       ack
    );

    modport mon (
        input       req, ack, wid, addr, web,
        input       wlast, wdata
    );

endinterface

interface VPU_DST_PORT_IF
(
    input   wire                        clk,
    input   wire                        rst_n,
);
    import VPU_PKG::*;

    logic                               req;
    logic                               ack;
    logic   [SRAM_BANK_CNT_LG2-1:0]     wid;
    logic   [SRAM_BANK_DEPTH_LG2-1:0]   addr;
    logic                               web;
    logic                               wlast;
    logic   [SRAM_DATA_WIDTH-1:0]       wdata;

    modport host (
        output      req, wid, addr, web, wlast, wdata,
        input       ack
    );

    modport mon (
        input       req, ack, wid, addr, web,
        input       wlast, wdata
    );
    
    modport dut (
        output      req, wid, addr, web, wlast, wdata,
        input       ack         
    );

    clocking drvClk @(posedge clk);
        input   req;
        input   wid;
        input   addr;
        input   web;
        input   wlast;
        input   wdata;
        output  ack;
    endclocking: drvClk

    clocking iMonClk @(posedge clk);
        input   req;
        input   wid;
        input   addr;
        input   web;
        input   wlast;
        input   wdata;
        input   ack;
    endclocking: iMonClk

    clocking oMonClk @(posedge clk);
        input  req;
        input  wid;
        input  addr;
        input  web;
        input  wlast;
        input  wdata;
        input  ack;
    endclocking: oMonClk

endinterface


