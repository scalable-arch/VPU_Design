`include "VPU_PKG.svh"

interface VPU_REQ_IF
(
        input   wire                        clk,
        input   wire                        rst_n,
);
    import VPU_PKG::*;

    vpu_h2d_req_instr_t                     h2d_req_instr;
    logic                                   valid;

    // Write Back Response??
    logic                                   rsp;
    
    modport device (
        output      rsp,
        input       h2d_req_instr, valid
    );

    modport host (
        input       rsp,
        output      h2d_req_instr, valid
    );

    modport mon (
        input       rsp,
        input       h2d_req_instr, valid
    );

    modport dut (
        output      rsp,
        input       h2d_req_instr, valid
    );

    clocking drvClk @(posedge clk);
        output  h2d_req_instr;
        output  valid;
        input   rsp;
    endclocking: drvClk

    clocking iMonClk @(posedge clk);
        input  h2d_req_instr;
        input  valid;
        input  rsp;
    endclocking: iMonClk

    clocking oMonClk @(posedge clk);
        input  h2d_req_instr;
        input  valid;
        input  rsp;
    endclocking: oMonClk

    //---------------------------------
    // Task For Verification
    //---------------------------------
    task init();
        h2d_req_instr           = {$bits(vpu_h2d_req_instr_t){1'b0}};
        valid                   = 1'b0;
    endtask

    task automatic gen_request(input int opcode);
        #1
            h2d_req_instr.opcode    = opcode;
            h2d_req_instr.src2      = 32'h0000_0100;
            h2d_req_instr.src1      = 32'h0000_0200;
            h2d_req_instr.src0      = 32'h0000_0300;
            h2d_req_instr.dst0      = 32'h0000_0400;
            valid                   = 1'b1;
            
        @(posedege clk);
                valid               = 1'b0;
    endtask

endinterface

interface VPU_SRC_PORT_IF
(
    input   wire                        clk,
    input   wire                        rst_n,
);
    import VPU_PKG::*;

    logic   [SRAM_R_PORT_CNT-1:0]       req;
    logic   [SRAM_R_PORT_CNT-1:0]       ack;
    logic   [SRAM_BANK_CNT_LG2-1:0]     rid     [SRAM_R_PORT_CNT];
    logic   [SRAM_BANK_DEPTH_LG2-1:0]   addr    [SRAM_R_PORT_CNT];
    logic   [SRAM_R_PORT_CNT-1:0]       reb;
    logic   [SRAM_R_PORT_CNT-1:0]       rlast;
    logic   [SRAM_DATA_WIDTH-1:0]       rdata   [SRAM_R_PORT_CNT];
    logic   [SRAM_R_PORT_CNT-1:0]       rvalid;

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

    //---------------------------------
    // Task For Verification
    //---------------------------------
    task init();
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            ack[i]              = 1'b0;
            rdata[i]            = {SRAM_DATA_WIDTH{1'b0}};
            rvalid[i]           = 1'b0;
        end
    endtask

    task automatic sram_r_response();
        while (~|req) begin
            @(posedge clk);
        end
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            ack[i]              = 1'b1;
        end
        
        repeat (5) @(posedge clk);
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            rdata[i]            = 'd2;
            rvalid[i]           = 1'b1;
        end
        @(posedge clk);
            rvalid[i]           = 1'b0;
    endtask

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
        input       req, wid, addr, web, wlast, wdata,
        input       ack
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

    task init();
        ack                     = 1'b0;
    endtask

    task automatic sram_w_response();
        while (!req) begin
            @(posedge clk);
        end
            ack                 = 1'b1;
        
        repeat (5) @(posedge clk);
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            rdata[i]            = 'd2;
            rvalid[i]           = 1'b1;
        end
        @(posedge clk);
            rvalid[i]           = 1'b0;
    endtask

endinterface

// For UVM-Testbench
interface VPU_RESET_IF(input logic clk);
    logic        reset_n;

    clocking mst @(posedge clk);
        output reset_n;
    endclocking

    clocking mon @(posedge clk);
        input reset_n;
    endclocking

    modport dut(input reset_n);
endinterface: VPU_RESET_IF

// VPU-Internal Interface
interface REQ_IF
(
    input   wire                        clk,
    input   wire                        rst_n,
);
    import VPU_PKG::*;

    logic   [OPCODE_WIDTH-1:0]          opcode;
    
    logic   [SRAM_R_PORT_CNT]           rvalid;
    logic   [OPERAND_ADDR_WIDTH-1:0]    raddr   [SRAM_R_PORT_CNT];
    logic   [OPERAND_ADDR_WIDTH-1:0]    waddr;
    logic   [MAX_DELAY_LG2-1:0]         delay;
    vpu_exec_req_t                      op_func;
    logic                               valid;
    logic                               ready;
    
    
    modport src (
        output      opcode, rvalid, raddr, waddr, exec_req, valid, delay
        input       ready
    );

    modport dst (
        input       opcode, rvalid, raddr, waddr, exec_req, valid, delay
        output      ready
    );
    
    modport mon (
        input       opcode, rvalid, raddr, waddr, exec_req, valid, delay
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
