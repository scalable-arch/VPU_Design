class req_agent extends uvm_agent;
    `uvm_component_utils(req_agent)

    typedef uvm_sequencer #(req_packet) req_packet_sequencer;

    virtual vpu_if          vif;
    req_packet_sequencer    sqr;
    req_driver              drv;

    req_iMonitor            mon;

    // Pass-through port for the iMonitor's analysis port
    uvm_analysis_port #(req_packet) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        // Construct Sub-Component
        if (is_active == UVM_ACTIVE) begin
            sqr = req_packet_sequencer::type_id::create("sqr", this);
            drv = req_driver::type_id::create("drv", this);
        end
        mon = req_iMonitor::type_id::create("mon", this);

        // Construct the analysis_port object
        analysis_port = new("analysis_port", this);

        // Factory for vif
        uvm_config_db#(virtual vpu_if)::get(this, "", "vif", vif);
        uvm_config_db#(virtual vpu_if)::set(this, "*", "vif", vif);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end

        // Connect the monitor's analysis_port to the agent's pass-through analysis_port
        mon.analysis_port.connect(this.analysis_port);
    endfunction: connect_phase

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        if (vif == null) begin
            `uvm_fatal("CFGERR", "Interface for input agent not set");
        end
    endfunction: end_of_elaboration_phase
endclass: req_agent

class sram_read_agent extends uvm_agent;
    `uvm_component_utils(sram_read_agent)

    typedef uvm_sequencer #(sram_read_tr) sram_read_tr_sequencer;

    virtual vpu_scr_port_if     vif;
    sram_read_tr_sequencer      sqr;
    sram_read_tr_driver         drv;

    sram_read_tr_iMonitor mon;

    // Pass-through port for the iMonitor's analysis port
    uvm_analysis_port #(sram_read_tr) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        // Construct Sub-Component
        if (is_active == UVM_ACTIVE) begin
            sqr = sram_read_tr_sequencer::type_id::create("sqr", this);
            drv = sram_read_tr_driver::type_id::create("drv", this);
        end
        mon = sram_read_tr_iMonitor::type_id::create("mon", this);

        // Construct the analysis_port object
        analysis_port = new("analysis_port", this);

        // Factory for vif
        uvm_config_db#(virtual vpu_scr_port_if)::get(this, "", "vif", vif);
        uvm_config_db#(virtual vpu_scr_port_if)::set(this, "*", "vif", vif);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end

        // Connect the monitor's analysis_port to the agent's pass-through analysis_port
        mon.analysis_port.connect(this.analysis_port);
    endfunction: connect_phase

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        if (vif == null) begin
            `uvm_fatal("CFGERR", "Interface for input agent not set");
        end
    endfunction: end_of_elaboration_phase
endclass: sram_read_agent


class sram_write_agent extends uvm_agent;
    `uvm_component_utils(sram_write_agent)

    typedef uvm_sequencer #(sram_write_tr) sram_write_tr_sequencer;

    virtual vpu_dst_port_if         vif;
    sram_write_tr_sequencer         sqr;
    sram_write_tr_driver            drv;

    sram_write_tr_oMonitor          mon;

    // Pass-through port for the iMonitor's analysis port
    uvm_analysis_port #(sram_write_tr) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        // Construct Sub-Component
        if (is_active == UVM_ACTIVE) begin
            sqr = sram_write_tr_sequencer::type_id::create("sqr", this);
            drv = sram_write_tr_driver::type_id::create("drv", this);
        end
        mon = sram_write_tr_oMonitor::type_id::create("mon", this);

        // Construct the analysis_port object
        analysis_port = new("analysis_port", this);

        // Factory for vif
        uvm_config_db#(virtual vpu_dst_port_if)::get(this, "", "vif", vif);
        uvm_config_db#(virtual vpu_dst_port_if)::set(this, "*", "vif", vif);
    endfunction: build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end

        // Connect the monitor's analysis_port to the agent's pass-through analysis_port
        mon.analysis_port.connect(this.analysis_port);
    endfunction: connect_phase

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        if (vif == null) begin
            `uvm_fatal("CFGERR", "Interface for input agent not set");
        end
    endfunction: end_of_elaboration_phase
endclass: sram_write_agent
