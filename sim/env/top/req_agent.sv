`ifndef REQ_AGENT
`define REQ_AGENT

class req_agent extends uvm_agent;
  `uvm_component_utils(req_agent)

  typedef uvm_sequencer #(req_packet) req_packet_sequencer;
  vpu_req_if            req_vif;
  req_packet_sequencer  sqr;
  req_driver            drv;
  req_monitor           mon;
  uvm_analysis_port #(req_packet) analysis_port; // full transaction

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    sqr = req_packet_sequencer::type_id::create("sqr", this);
    drv = req_driver::type_id::create("drv", this);
    mon = req_monitor::type_id::create("mon", this);
    analysis_port = new("analysis_port", this);

    uvm_config_db#(vpu_req_if)::get(this, "", "req_vif", req_vif);
    uvm_config_db#(vpu_req_if)::set(this, "*", "req_vif", req_vif);
  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    mon.transaction_aport.connect(this.analysis_port);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (req_vif == null) begin
        `uvm_fatal("CFGERR", "Interface for req_agent not set");
    end
  endfunction: end_of_elaboration_phase
endclass
`endif // REQ_AGENT