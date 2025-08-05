`ifndef VPU_UVM_PKG_SV
`define VPU_UVM_PKG_SV

`include  "VPU_IF.sv"
`include  "VPU_PKG.svh"

package vpu_uvm_pkg;
    import  uvm_pkg::*;
    import  VPU_PKG::*;
    typedef virtual VPU_SRC_PORT_IF vpu_src_if;
    typedef virtual VPU_DST_PORT_IF vpu_dst_if;

    `include  "uvm_macros.svh"
    `include  "dst_packet.svh"
    `include  "src_packet.svh"
    `include  "simple_sram_model.sv"
    `include  "simple_dst_responder.sv"

    `include  "src_sequencer.sv"
    `include  "src_driver.sv"
    `include  "src_monitor.sv"

    `include  "dst_agent.sv"
    `include  "src_agent.sv"

    
    `include  "vpu_seq_lib.svh"
    `include  "vpu_env.sv"

    `include  "vpu_test_lib.svh"
endpackage
`endif // VPU_UVM_PKG_SV