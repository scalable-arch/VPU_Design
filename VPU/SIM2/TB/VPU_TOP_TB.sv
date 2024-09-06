`include "VPU_PKG.svh"
`define TIMEOUT_DELAY   500000
module VPU_TOP_TB ();
    import VPU_PKG::*;
    reg                     clk;
    reg                     rst_n;

    VPU_PKG::vpu_h2d_req_opcode_t opcode;
    // clock generation
    initial begin
        clk                     = 1'b0;

        forever #10 clk         = !clk;
    end


    // reset generation
    initial begin
        rst_n                   = 1'b0;     // active at time 0

        repeat (3) @(posedge clk);          // after 3 cycles,
        rst_n                   = 1'b1;     // release the reset
    end
    
    //timeout
    initial begin
        #`TIMEOUT_DELAY $display("Timeout!");
        $finish;
    end

    //----------------------------------------------------------
    // Connection between DUT and test modules
    //----------------------------------------------------------

    VPU_REQ_IF                  vpu_req_if (
        .clk                        (clk),
        .rst_n                      (rst_n)
    );

    VPU_SRC_PORT_IF             vpu_src_port_if (
        .clk                        (clk),
        .rst_n                      (rst_n)
    );

    VPU_DST_PORT_IF             vpu_dst_port_if (
        .clk                        (clk),
        .rst_n                      (rst_n)
    );

    VPU_TOP #(
        //...
    ) u_DUT (
        .clk                (clk),
        .rst_n              (rst_n),

        .vpu_req_if         (vpu_req_if),
        .vpu_src_port_if    (vpu_src_port_if),
        .vpu_dst_port_if    (vpu_dst_port_if)
    );

    // enable waveform dump
    initial begin
        $dumpvars(0, u_DUT);
        $dumpfile("dump.vcd");
    end

    task test_init();
        vpu_req_if.init();
        vpu_src_port_if.init();
        vpu_dst_port_if.init();
        @(posedge rst_n); 
        repeat (10) @(posedge clk);
    endtask

    task gen_request(input int gen_num);
        VPU_PKG::vpu_h2d_req_opcode_t opcode;
        integer i;
        for(i = 0; i < gen_num; i++) begin
            opcode = vpu_h2d_req_opcode_t'($random % 23);
            vpu_req_if.gen_request(opcode);
            repeat (($random % 2) + 1) @(posedge clk);
        end
    endtask
    
    initial begin
        $display("Start Simulation!");
        opcode = VPU_PKG::VPU_H2D_REQ_OPCODE_UISUM;
        
        test_init();
        fork
            vpu_req_if.gen_request(opcode);
            vpu_src_port_if.sram_r_response();
            vpu_dst_port_if.sram_w_response();
        join
        $display("Simulation Done!");
        $finish;
    end

endmodule