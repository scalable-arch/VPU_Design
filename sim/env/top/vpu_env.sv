`ifndef VPU_ENV
`define VPU_ENV

class vpu_env extends uvm_env;
    `uvm_component_utils(vpu_env)

    dst_agent dst_agt;
    src_agent src_agt[3];

    simple_sram_model storage;
    //scoreboard sb;

    function new(string name = "vpu_env", uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        //uvm_config_db #(uvm_object_wrapper)::set(this, "r_agt.sqr.reset_phase", "default_sequence", reset_sequence::get_type());

        foreach (src_agt[i]) begin
            src_agt[i] = src_agent::type_id::create($sformatf("src_agt[%0d]", i), this);
            uvm_config_db #(uvm_object_wrapper)::set(this, {src_agt[i].get_name(), ".", "sqr.main_phase"}, "default_sequence", src_packet_sequence::get_type());
        end
        dst_agt = dst_agent::type_id::create("dst_agt", this);

        storage = simple_sram_model::type_id::create("storage", this);
        uvm_config_db#(simple_sram_model)::set(this, "src_agt[*].*", "storage", storage);
        uvm_config_db#(simple_sram_model)::set(this, "dst_agt.*",   "storage", storage);
        //sb = scoreboard::type_id::create("sb", this);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        // foreach (i_agt[i]) begin
        //     i_agt[i].analysis_port.connect(sb.before_export);
        // end
    endfunction: connect_phase

endclass: vpu_env
`endif // VPU_ENV
