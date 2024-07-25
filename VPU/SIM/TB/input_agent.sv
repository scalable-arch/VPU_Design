class input_agent extends uvm_agent;
    `uvm_component_utils(input_agent)

    typedef uvm_sequencer #(packet) packet_sequencer;

    virtual vpu_io vif;
    packet_sequencer  sqr;
    driver            drv;

    iMonitor mon;

    // Pass-through port for the iMonitor's analysis port
    uvm_analysis_port #(packet) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        // Construct Sub-Component
        if (is_active == UVM_ACTIVE) begin
            sqr = packet_sequencer::type_id::create("sqr", this);
            drv = driver::type_id::create("drv", this);
        end
        mon = iMonitor::type_id::create("mon", this);

        // Construct the analysis_port object
        analysis_port = new("analysis_port", this);

        // Factory for vif
        uvm_config_db#(virtual vpu_io)::get(this, "", "vif", vif);
        uvm_config_db#(virtual vpu_io)::set(this, "*", "vif", vif);
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
endclass: input_agent
