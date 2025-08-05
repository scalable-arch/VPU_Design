`ifndef RSP_AGENT
`define RSP_AGENT


class rsp_agent extends uvm_agent;
  `uvm_component_utils(rsp_agent);

  vpu_rsp_if  rsp_vif;
  simple_rsp_responder rsp_responder;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    rsp_responder = simple_rsp_responder::type_id::create("rsp_responder", this);

    uvm_config_db#(vpu_rsp_if)::get(this, "", "rsp_vif", rsp_vif);
    uvm_config_db#(vpu_rsp_if)::set(this, "*", "rsp_vif", rsp_vif);
  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (rsp_vif == null) begin
        `uvm_fatal("CFGERR", "Interface for rsp_agent not set");
    end
  endfunction: end_of_elaboration_phase
endclass

class simple_rsp_responder extends uvm_component;
    `uvm_component_utils(simple_rsp_responder)

    vpu_rsp_if  rsp_vif;

    function new(string name = "simple_rsp_responder", uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(vpu_rsp_if)::get(this, "", "rsp_vif", rsp_vif))
          `uvm_fatal("VIF_ERR", "Virtual interface for simple_rsp_responder not set");
    endfunction

    virtual task run_phase(uvm_phase phase);
      forever begin
        wait(rsp_vif.rst_n !== 0);
        do begin
          @(rsp_vif.drvClk);     
        end while (!rsp_vif.drvClk.resq_valid);
        @(posedge rsp_vif.drvClk);
          rsp_vif.drvClk.resp_ready = 1'b1;
        @(posedge rsp_vif.drvClk);
          rsp_vif.drvClk.resp_ready = 1'b0;
      end
    endtask
endclass

`endif // rsp_agent