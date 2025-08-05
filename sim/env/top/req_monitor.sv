`ifndef REQ_MONITOR
`define REQ_MONITOR

class req_monitor extends uvm_monitor;
  `uvm_component_utils(req_monitor)

  vpu_req_if req_vif;
  uvm_analysis_port #(req_packet) transaction_aport; // full

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

    uvm_config_db#(vpu_req_if)::get(this, "", "req_vif", req_vif);
    transaction_aport = new("transaction_aport", this);
  endfunction: build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (req_vif == null) begin
        `uvm_fatal("CFGERR", "Interface for req_monitor not set");
    end
  endfunction: end_of_elaboration_phase

  virtual task run_phase(uvm_phase phase);
    fork
        monitor_bus();
    join
  endtask

  task monitor_bus();
    req_packet tr;
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    forever begin
        tr = req_packet::type_id::create("tr", this);
        monitor_req(tr);
        `uvm_info("Send Src_Rsp Packet", {"\n", tr.sprint()}, UVM_MEDIUM);
        transaction_aport.write(tr); // publish full
    end
  endtask

  virtual task monitor_req(req_packet tr);
    wait (req_vif.rst_n !== 0);

    do begin
        @(req_vif.oMonClk);     
    end while (!req_vif.oMonClk.valid);
     
    tr.opcode     = req_vif.oMonClk.h2d_req_instr.opcode;
    tr.src0       = req_vif.oMonClk.h2d_req_instr.src0;
    tr.src1       = req_vif.oMonClk.h2d_req_instr.src1;
    tr.src2       = req_vif.oMonClk.h2d_req_instr.src2;
    tr.dst0       = req_vif.oMonClk.h2d_req_instr.dst0;
    tr.stream_id  = req_vif.oMonClk.stream_id;
    tr.imm        = req_vif.oMonClk.imm;
    `uvm_info("REQ MONITOR", {"\n", tr.sprint()}, UVM_MEDIUM);
  endtask
endclass
`endif // req_monitor