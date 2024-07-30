module vpu_test_top;
    parameter simulation_cycle = 100 ;
    bit  SystemClock;

    VPU_IF  vpu_if(SystemClock);
    VPU_RESET_IF vpu_rst_if(SystemClock);
    VPU_SRC_PORT_IF vpu_src_port_if(SystemClock);
    VPU_DST_PORT_IF vpu_dst_port_if(SystemClock);
    VPU_TOP dut(.clk(SystemClock), .rst_n(vpu_rst_if.reset_n), .vpu_src_port_if(vpu_src_port_if), .vpu_dst_port_if(vpu_dst_port_if));

    initial begin
        $fsdbDumpvars;
        forever #(simulation_cycle/2) SystemClock = ~SystemClock ;
    end
endmodule  