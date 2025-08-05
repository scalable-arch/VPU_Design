module top();
  timeunit 1ns;
  timeprecision 1ps;
  
  import uvm_pkg::*;
  import  vpu_uvm_pkg::*;

  bit clk  = 0;
  initial begin
    forever begin
      #(10ns);
      clk  ^= 1'b1;
    end
  end

  bit rst_n  = 0;
  initial begin
    repeat (20) @(posedge clk);
    rst_n  = 1;
  end

    VPU_REQ_IF                  vpu_req_if (.clk(clk), .rst_n(rst_n));
    VPU_RESPONSE_IF             vpu_response_if (.clk(clk), .rst_n(rst_n));
    VPU_SRC_PORT_IF             vpu_src_port_if[3](.clk(clk), .rst_n(rst_n));
    VPU_DST_PORT_IF             vpu_dst_port_if (.clk(clk), .rst_n(rst_n));

    VPU_TOP #(
        //...
    ) u_DUT (
        .clk                (clk),
        .rst_n              (rst_n),

        .vpu_req_if         (vpu_req_if),
        .vpu_response_if    (vpu_response_if),
        .vpu_src0_port_if   (vpu_src_port_if[0]),
        .vpu_src1_port_if   (vpu_src_port_if[1]),
        .vpu_src2_port_if   (vpu_src_port_if[2]),
        .vpu_dst0_port_if   (vpu_dst_port_if)
    );

  initial begin
    uvm_config_db #(vpu_src_if)::set(null, "uvm_test_top.env.src_agt[0]", "src_vif", vpu_src_port_if[0]);
    uvm_config_db #(vpu_src_if)::set(null, "uvm_test_top.env.src_agt[1]", "src_vif", vpu_src_port_if[1]);
    uvm_config_db #(vpu_src_if)::set(null, "uvm_test_top.env.src_agt[2]", "src_vif", vpu_src_port_if[2]);
    uvm_config_db #(vpu_dst_if)::set(null, "", "dst_vif", vpu_dst_port_if);
    run_test();
  end

  // simple request test
  initial begin
    vpu_req_if.init();
    @(posedge rst_n); 
    repeat (10) @(posedge clk);

    @(posedge clk);
      vpu_req_if.h2d_req_instr.opcode    <= 'h01;
      vpu_req_if.h2d_req_instr.src2      <= 'hF0F0;
      vpu_req_if.h2d_req_instr.src1      <= 'hCA00;
      vpu_req_if.h2d_req_instr.src0      <= 'h0CF0;
      vpu_req_if.h2d_req_instr.dst0      <= 'h10F0;
      vpu_req_if.valid                   <= 1'b1;
      vpu_req_if.stream_id               <= 'd0;

    if(vpu_req_if.ready == 1'b1) begin
        @(posedge clk);
        vpu_req_if.valid                 = 1'b0;
    end else begin
        while (!vpu_req_if.ready) begin
            @(posedge clk);
        end
        vpu_req_if.valid                 = 1'b0;
    end
    @(posedge clk);

    wait(vpu_response_if.resp_valid);
      vpu_response_if.resp_ready         = 1'b1;
    @(posedge clk);
      vpu_response_if.resp_ready         = 1'b0;
    @(posedge clk);
  end
endmodule