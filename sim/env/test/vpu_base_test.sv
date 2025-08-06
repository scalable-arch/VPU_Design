`ifndef VPU_BASE_TEST
`define VPU_BASE_TEST

`include "uvm_macros.svh"
import uvm_pkg::*;

class vpu_base_test extends uvm_test;
  `uvm_component_utils(vpu_base_test)

  vpu_env env;
  vpu_src_if  src_vif;
  vpu_dst_if  dst_vif;
  vpu_req_if  req_vif;
  vpu_rsp_if  rsp_vif;

  function new(string name = "vpu_base_test", uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    if(!uvm_config_db#(vpu_env)::get(null, "uvm_test_top.*", "env", env)) begin
        `uvm_info(get_type_name(), $sformatf("create env..."), UVM_HIGH)
        env = vpu_env::type_id::create("env", this);
        uvm_config_db#(vpu_env)::set(this, "", "env", env);
    end

    uvm_resource_db#(vpu_src_if)::read_by_type("src_vif", src_vif, this);
    uvm_resource_db#(vpu_dst_if)::read_by_type("dst_vif", dst_vif, this);
    uvm_resource_db#(vpu_req_if)::read_by_type("req_vif", req_vif, this);
    uvm_resource_db#(vpu_rsp_if)::read_by_type("rsp_vif", rsp_vif, this);

    uvm_config_db#(vpu_src_if)::set(this, "env.src_agt[*]", "src_vif", src_vif);
    uvm_config_db#(vpu_dst_if)::set(this, "env.dst_agt", "dst_vif", dst_vif);
    uvm_config_db#(vpu_req_if)::set(this, "env.req_agt", "req_vif", req_vif);
    uvm_config_db#(vpu_rsp_if)::set(this, "env.rsp_agt", "rsp_vif", rsp_vif);

  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: connect_phase

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask:run_phase
endclass: vpu_base_test

`endif  // VPU_BASE_TEST