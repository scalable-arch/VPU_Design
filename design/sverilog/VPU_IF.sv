`include "VPU_PKG.svh"

interface VPU_REQ_IF
(
        input   wire                        clk,
        input   wire                        rst_n
);
    import VPU_PKG::*;
    
    vpu_h2d_req_instr_t                     h2d_req_instr;
    logic                                   valid;
    logic                                   ready;
    logic   [STREAM_ID_WIDTH-1:0]           stream_id;
    modport device (
        output      ready,
        input       h2d_req_instr, valid, stream_id
    );

    modport host (
        input       ready,
        output      h2d_req_instr, valid, stream_id
    );

    modport mon (
        input       ready,
        input       h2d_req_instr, valid, stream_id
    );

    modport dut (
        output      ready,
        input       h2d_req_instr, valid, stream_id
    );

    // synopsys translate_off
    clocking drvClk @(posedge clk);
        output  h2d_req_instr;
        output  valid;
        output  stream_id;
        input   ready;
    endclocking: drvClk

    clocking iMonClk @(posedge clk);
        input  h2d_req_instr;
        input  valid;
        input  stream_id;
        input  ready;
    endclocking: iMonClk

    clocking oMonClk @(posedge clk);
        input  h2d_req_instr;
        input  valid;
        input  stream_id;
        input  ready;
    endclocking: oMonClk

    //---------------------------------
    // Task For Verification
    //---------------------------------
    task automatic init();
        h2d_req_instr           = {$bits(vpu_h2d_req_instr_t){1'b0}};
        valid                   = 1'b0;
        stream_id               = {(STREAM_ID_WIDTH){1'b0}};
    endtask

    task automatic gen_request(input vpu_h2d_req_instr_t instr, input [STREAM_ID_WIDTH-1:0] streamID);
        @(posedge clk);
        #1
            h2d_req_instr.opcode    = instr.opcode;
            h2d_req_instr.src2      = instr.src2;
            h2d_req_instr.src1      = instr.src1;
            h2d_req_instr.src0      = instr.src0;
            h2d_req_instr.dst0      = instr.dst0;
            valid                   = 1'b1;
            stream_id               = streamID;
        if(ready == 1'b1) begin
            @(posedge clk);
            valid                   = 1'b0;
        end else begin
            while (!ready) begin
                @(posedge clk);
            end
            valid               = 1'b0;
        end
    endtask
    // synopsys translate_on

endinterface

interface VPU_RESPONSE_IF
(
        input   wire                        clk,
        input   wire                        rst_n
);
    import VPU_PKG::*;

    logic                                   resp_valid;
    logic                                   resp_ready;
    logic   [STREAM_ID_WIDTH-1:0]           resp_stream_id;

    modport host (
        output      resp_ready,
        input       resp_valid, resp_stream_id
    );

    modport device (
        input       resp_ready,
        output      resp_valid, resp_stream_id
    );

    //---------------------------------
    // Task For Verification
    //---------------------------------
    task automatic init();
        resp_ready                = 1'b0;
    endtask

    task automatic response();
        while (!resp_valid) begin
            @(posedge clk);
        end
        resp_ready                = 1'b1;
        
        @(posedge clk);
        resp_ready                = 1'b0;

        @(posedge clk);
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
