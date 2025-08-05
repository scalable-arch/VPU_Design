`ifndef SRC_DRIVER
`define SRC_DRIVER

class src_driver extends uvm_driver #(src_packet);
    src_packet src_rsp;

    vpu_src_if src_vif;

    `uvm_component_utils(src_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        uvm_config_db#(vpu_src_if)::get(this, "", "src_vif", src_vif);
    endfunction: build_phase

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        if (src_vif == null) begin
        `uvm_fatal("CFGERR", "Interface for Driver not set");
        end
    endfunction: end_of_elaboration_phase
    
    virtual task run_phase(uvm_phase phase);
        forever begin
            // Get the next response item from sequencer
            seq_item_port.get_next_item(src_rsp);
            // Drive the response onto the interface
            send_rsp(src_rsp);
            // Consume the response item
            seq_item_port.item_done();
        end
    endtask: run_phase

    virtual task send_rsp(input src_packet item);
        @(src_vif.drvClk);
            src_vif.drvClk.ack <= 1'b1;
        @(src_vif.drvClk);
            src_vif.drvClk.ack <= 1'b0;

        repeat (5) @(src_vif.drvClk);
            src_vif.drvClk.rdata  <= item.rdata;
            src_vif.drvClk.rvalid <= 1'b1;

        @(src_vif.drvClk);
            src_vif.drvClk.rvalid <= 1'b0;
    endtask
endclass
`endif // SRC_DRIVER