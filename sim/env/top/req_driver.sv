`ifndef REQ_DRIVER
`define REQ_DRIVER

class req_driver extends uvm_driver #(req_packet);

  `uvm_component_utils(req_driver)
  vpu_req_if req_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    uvm_config_db#(vpu_req_if)::get(this, "", "req_vif", req_vif);
  endfunction: build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    if (req_vif == null) begin
    `uvm_fatal("CFGERR", "Interface for Driver not set");
    end
  endfunction: end_of_elaboration_phase
  
  virtual task run_phase(uvm_phase phase);
    forever begin
        // Get the next response item from sequencer
        seq_item_port.get_next_item(req);
        // Drive the response onto the interface
        send_req(req);
        // Consume the response item
        seq_item_port.item_done();
    end
  endtask: run_phase

  virtual task send_req(input req_packet item);
    //wait(req_vif.rst_n !== 1'b0);
    //@(req_vif.drvClk);
    wait (req_vif.rst_n !== 1'b0);
    @(req_vif.drvClk iff (req_vif.rst_n === 1'b1)) begin
      req_vif.drvClk.valid          <= 1'b1;
      req_vif.drvClk.h2d_req_instr  <= {{item.opcode}, {item.dst0}, {item.src0}, 
                                        {item.src1}, {item.src2}, {item.imm}};
      req_vif.drvClk.stream_id      <= item.stream_id;
    end

    @(req_vif.drvClk iff req_vif.drvClk.ready);
      req_vif.drvClk.valid          <= 1'b0;
  endtask
endclass
`endif // req_driver