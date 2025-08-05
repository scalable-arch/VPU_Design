`ifndef SRC_AGENT
`define SRC_AGENT


class src_agent extends uvm_agent;
    `uvm_component_utils(src_agent)

    vpu_src_if  src_vif;
    src_sequencer       sqr;
    src_driver          drv;
    src_monitor         mon;
    simple_sram_model   storage;
    uvm_analysis_port #(src_packet) analysis_port; // full transaction

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        sqr = src_sequencer::type_id::create("sqr", this);
        drv = src_driver::type_id::create("drv", this);
        mon = src_monitor::type_id::create("mon", this);
        analysis_port = new("analysis_port", this);

        uvm_config_db#(vpu_src_if)::get(this, "", "src_vif", src_vif);
        uvm_config_db#(vpu_src_if)::set(this, "*", "src_vif", src_vif);
        uvm_config_db#(simple_sram_model)::get(this, "", "storage", storage);
        uvm_config_db#(simple_sram_model)::set(this, "*", "storage", storage);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        mon.transaction_aport.connect(analysis_port);
        drv.seq_item_port.connect(sqr.seq_item_export);
        mon.request_aport.connect(sqr.request_export);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        if (src_vif == null) begin
            `uvm_fatal("CFGERR", "Interface for src_agent not set");
        end
  endfunction: end_of_elaboration_phase
endclass
`endif // SRC_AGENT