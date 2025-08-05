`ifndef SRC_SEQUENCER
`define SRC_SEQUENCER


class src_sequencer extends uvm_sequencer #(src_packet);
    
    `uvm_component_utils(src_sequencer)

    uvm_analysis_export #(src_packet) request_export;
    uvm_tlm_analysis_fifo #(src_packet) request_fifo;

    simple_sram_model storage;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

     virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        request_fifo = new("request_fifo", this);
        request_export = new("request_export", this);
        if (!uvm_config_db#(simple_sram_model)::get(this, "", "storage", storage))
            `uvm_fatal("CFG_ERR", "Storage handle not found for sequencer")
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        request_export.connect(request_fifo.analysis_export);
    endfunction
endclass 
`endif // SRC_SEQUENCER