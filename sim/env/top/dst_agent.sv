`ifndef DST_AGENT
`define DST_AGENT


class dst_agent extends uvm_agent;
    `uvm_component_utils(dst_agent);

    vpu_dst_if  dst_vif;
    simple_dst_responder dst_responder;
    simple_sram_model storage;
    uvm_analysis_port #(dst_packet) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        dst_responder = simple_dst_responder::type_id::create("dst_responder", this);
        analysis_port = new("analysis_port", this);

        uvm_config_db#(vpu_dst_if)::get(this, "", "dst_vif", dst_vif);
        uvm_config_db#(vpu_dst_if)::set(this, "*", "dst_vif", dst_vif);
        uvm_config_db#(simple_sram_model)::get(this, "", "storage", storage);
        uvm_config_db#(simple_sram_model)::set(this, "*", "storage", storage);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        dst_responder.analysis_port.connect(this.analysis_port);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        if (dst_vif == null) begin
            `uvm_fatal("CFGERR", "Interface for dst_agent not set");
        end
  endfunction: end_of_elaboration_phase
endclass

`endif // DST_AGENT