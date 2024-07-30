class test_base extends uvm_test;
    `uvm_component_utils(test_base)

    vpu_env env;

    virtual vpu_if vpu_if;
    virtual vpu_src_port_if  vpu_src_port_if;
    virtual vpu_dst_port_if vpu_dst_port_if;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        env = vpu_env::type_id::create("env", this);

        uvm_resource_db#(virtual vpu_if)::read_by_type("vpu_if", vpu_if, this);
        uvm_resource_db#(virtual vpu_src_port_if)::read_by_type("vpu_src_port_if", vpu_src_port_if, this);
        uvm_resource_db#(virtual vpu_dst_port_if)::read_by_type("vpu_dst_port_if", vpu_dst_port_if, this);

        uvm_config_db#(virtual vpu_if)::set(this, "env.req_agt", "vif", vpu_if);
        uvm_config_db#(virtual vpu_src_port_if)::set(this, "env.sram_read_agt[*]", "vif", vpu_src_port_if);
        uvm_config_db#(virtual vpu_dst_port_if)::set(this, "env.sram_write_agt", "vif", vpu_dst_port_if);
    endfunction: build_phase

    /*
    virtual task main_phase(uvm_phase phase);
        uvm_objection objection;
        super.main_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        objection = phase.get_objection();
        objection.set_drain_time(this, 1us);
    endtask: main_phase
    */    

    virtual task shutdown_phase(uvm_phase phase);
        super.shutdown_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        phase.raise_objection(this);
        env.sb.wait_for_done();
        phase.drop_objection(this);
    endtask: shutdown_phase

    // The report phase is added to display the scoreboard results.
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: report_phase

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        if (uvm_report_enabled(UVM_DEBUG, UVM_INFO, "TOPOLOGY")) begin
        uvm_root::get().print_topology();
        end

        if (uvm_report_enabled(UVM_DEBUG, UVM_INFO, "FACTORY")) begin
        uvm_factory::get().print();
        end
    endfunction: final_phase
endclass: test_base

