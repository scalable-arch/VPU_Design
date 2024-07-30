class vpu_env extends uvm_env;
    `uvm_component_utils(vpu_env)

    req_agent req_agt;
    sram_read_agent sram_read_agt[3];
    sram_write_agent sram_write_agt;
    scoreboard sb;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        //Build request agent
        req_agt = req_agent::type_id::create("req_agt", this);
        uvm_config_db #(uvm_object_wrapper)::set(this, "req_agt.sqr.reset_phase", "default_sequence", req_packet_sequence::get_type());

        //Build sram reqd agent
        foreach (sram_read_agt[i]) begin
        sram_read_agt[i] = sram_read_agent::type_id::create($sformatf("sram_read_agt[%0d]", i), this);
        uvm_config_db #(int)::set(this, sram_read_agt[i].get_name(), "port_id", i);
        uvm_config_db #(uvm_object_wrapper)::set(this, {sram_read_agt[i].get_name(), ".", "sqr.reset_phase"}, "default_sequence", router_input_port_reset_sequence::get_type());
        uvm_config_db #(uvm_object_wrapper)::set(this, {sram_read_agt[i].get_name(), ".", "sqr.main_phase"}, "default_sequence", sram_read_tr_sequence::get_type());
        end

        //Build sram write agent
        sram_write_agt = sram_write_agent::type_id::create($sformatf("sram_write_agent"), this);
        uvm_config_db #(uvm_object_wrapper)::set(this, {sram_write_agt.get_name(), ".", "sqr.reset_phase"}, "default_sequence", router_input_port_reset_sequence::get_type());
        uvm_config_db #(uvm_object_wrapper)::set(this, {sram_write_agt.get_name(), ".", "sqr.main_phase"}, "default_sequence", sram_write_tr_sequence::get_type());

        //Build ScoreBoard
        sb = scoreboard::type_id::create("sb", this);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        foreach (sram_read_agt[i]) begin
        sram_read_agt[i].analysis_port.connect(sb.before_export);
        end
        sram_write_agt.analysis_port.connect(sb.after_export);
    endfunction: connect_phase

endclass: vpu_env
