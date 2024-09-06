`include "/home/sg05060/generic_npu/src/VPU/RTL/Header/VPU_PKG.svh"

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
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            ack[i]              = 1'b0;
            rdata[i]            = {SRAM_DATA_WIDTH{1'b0}};
            rvalid[i]           = 1'b0;
        end
    endtask

    task automatic sram_r_response();
        logic  [SRAM_R_PORT_CNT-1:0] req_r;
        while (~|req) begin
            @(posedge clk);
        end
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            if(req[i] == 1'b1) begin
                req_r[i]            = 1'b1;
                ack[i]              = 1'b1;
            end
        end
        
        repeat (5) @(posedge clk);
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            if(req_r[i] == 1'b1) begin
                rdata[i]            = {{128'h0000_0001_0002_0003_0004_0005_0006_0007},
                                        {128'h0008_0009_000a_000b_000c_000d_000e_000f},
                                        {128'h0010_0011_0012_0013_0014_0015_0016_0017},
                                        {128'h0018_0019_001a_001b_001c_001d_001e_001f}
                                        };
                rvalid[i]           = 1'b1;
            end
        end
        @(posedge clk);
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            rvalid[i]           = 1'b0;
            req_r[i]            = 1'b0;
        end
    endtask

    task automatic sram_read_transaction(input bit [511:0] _rdata[3]);
        logic  [SRAM_R_PORT_CNT-1:0] req_r;
        while (~|req) begin
            @(posedge clk);
        end
        #1;
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            if(req[i] == 1'b1) begin
                req_r[i]            = 1'b1;
                ack[i]              = 1'b1;
            end
        end
        
        @(posedge clk);
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            ack[i]                  = 1'b0;
        end
        
        repeat (5) @(posedge clk);
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            if(req_r[i] == 1'b1) begin
                rdata[i]            = _rdata[i];
                rvalid[i]           = 1'b1;
            end
        end
        @(posedge clk);
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            rvalid[i]           = 1'b0;
            req_r[i]            = 1'b0;
        end
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

interface SRAM_R_PORT_IF
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

endinterface

/*
interface SRAM_W_PORT_IF
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
        input       req, ack, wid, addr, web,
        input       wlast, wdata
    );

endinterface
*/