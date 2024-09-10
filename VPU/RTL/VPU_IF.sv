`include "/home/sg05060/VPU_Design/VPU/RTL/Header/VPU_PKG.svh"

interface VPU_REQ_IF
(
        input   wire                        clk,
        input   wire                        rst_n
);
    import VPU_PKG::*;
    
    vpu_h2d_req_instr_t                     h2d_req_instr;
    logic                                   valid;
    logic                                   ready;
    
    modport device (
        output      ready,
        input       h2d_req_instr, valid
    );

    modport host (
        input       ready,
        output      h2d_req_instr, valid
    );

    modport mon (
        input       ready,
        input       h2d_req_instr, valid
    );

    modport dut (
        output      ready,
        input       h2d_req_instr, valid
    );

    // synopsys translate_off
    clocking drvClk @(posedge clk);
        output  h2d_req_instr;
        output  valid;
        input   ready;
    endclocking: drvClk

    clocking iMonClk @(posedge clk);
        input  h2d_req_instr;
        input  valid;
        input  ready;
    endclocking: iMonClk

    clocking oMonClk @(posedge clk);
        input  h2d_req_instr;
        input  valid;
        input  ready;
    endclocking: oMonClk

    //---------------------------------
    // Task For Verification
    //---------------------------------
    task automatic init();
        h2d_req_instr           = {$bits(vpu_h2d_req_instr_t){1'b0}};
        valid                   = 1'b0;
    endtask

    task automatic gen_request(input vpu_h2d_req_opcode_t opcode);
        @(posedge clk);
        #1
            h2d_req_instr.opcode    = opcode;
            h2d_req_instr.src2      = 32'h0000_3000;
            h2d_req_instr.src1      = 32'h0000_2000;
            h2d_req_instr.src0      = 32'h0000_1000;
            h2d_req_instr.dst0      = 32'h0000_4000;
            valid                   = 1'b1;
        
        while (!ready) begin
            @(posedge clk);
        end
        valid               = 1'b0;
    endtask
    // synopsys translate_on

endinterface

interface VPU_SRC_PORT_IF
(
    input   wire                        clk,
    input   wire                        rst_n
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

    modport dut (
        output      req, rid, addr, reb, rlast,
        input       ack, rdata, rvalid
    );

    // synopsys translate_off
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
        ack              = 1'b0;
        rdata            = {SRAM_DATA_WIDTH{1'b0}};
        rvalid           = 1'b0;
    endtask

    task automatic sram_read_transaction(input bit [511:0] _rdata);
        while (!req) begin
            @(posedge clk);
        end
        #1;

        if(req == 1'b1) begin
            ack             = 1'b1;
        end
        
        @(posedge clk);
            ack             = 1'b0;
        
        repeat (5) @(posedge clk);
        rdata               = _rdata;
        rvalid              = 1'b1;

        @(posedge clk);
            rvalid          = 1'b0;
            
        @(posedge clk);
    endtask
    // synopsys translate_on
endinterface


interface VPU_DST_PORT_IF
(
    input   wire                        clk,
    input   wire                        rst_n
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

    // synopsys translate_off
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
    
    //---------------------------------
    // Task For Verification
    //---------------------------------
    task init();
        ack                 = 1'b0;
    endtask

    task automatic sram_w_response();
        while (!req) begin
            @(posedge clk);
        end
        ack                 = 1'b1;
        
        @(posedge clk);
        ack                 = 1'b0;

        repeat (5) @(posedge clk);

    endtask

    task automatic sram_write_transaction(output bit [511:0] _wdata);
        while (!req) begin
            @(posedge clk);
        end
        ack                 = 1'b1;
        _wdata              = wdata;

        @(posedge clk);
        ack                 = 1'b0;

        repeat (5) @(posedge clk);

    endtask
    // synopsys translate_on
endinterface

// For UVM-Testbench
/*
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
*/

// VPU-Internal Interface
interface REQ_IF
(
    input   wire                        clk,
    input   wire                        rst_n
);
    import VPU_PKG::*;

    logic   [OPCODE_WIDTH-1:0]          opcode;
    
    logic   [SRAM_R_PORT_CNT-1:0]       rvalid;
    logic   [OPERAND_ADDR_WIDTH-1:0]    raddr   [SRAM_R_PORT_CNT];
    logic   [OPERAND_ADDR_WIDTH-1:0]    waddr;
    logic   [MAX_DELAY_LG2-1:0]         delay;
    vpu_exec_req_t                      op_func;
    logic                               valid;
    logic                               ready;
    
    
    modport src (
        output      opcode, rvalid, raddr, waddr, op_func, valid, delay,
        input       ready
    );

    modport dst (
        input       opcode, rvalid, raddr, waddr, op_func, valid, delay,
        output      ready
    );
    
    modport mon (
        input       opcode, rvalid, raddr, waddr, op_func, valid, delay,
        input       ready
    );
endinterface

