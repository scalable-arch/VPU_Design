class iMonitor extends uvm_monitor;

    virtual vpu_io vif;
    
    uvm_analysis_port #(packet) analysis_port;

    `uvm_component_utils(iMonitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        uvm_config_db#(virtual vpu_io)::get(this, "", "vif", vif);

        analysis_port = new("analysis_port", this);
    endfunction: build_phase


    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        if (vif == null) begin
            `uvm_fatal("CFGERR", "Interface for iMonitor not set");
        end
    endfunction: end_of_elaboration_phase

    virtual task run_phase(uvm_phase phase);

        packet tr;
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        forever begin
            tr = packet::type_id::create("tr", this);
            get_packet(tr);
            `uvm_info("Got_Input_Packet", {"\n", tr.sprint()}, UVM_MEDIUM);
            analysis_port.write(tr);
        end
    endtask: run_phase

    virtual task get_packet(packet tr);
        logic [7:0] datum;
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        wait (vif.iMonClk.we !== 0);
        @(vif.iMonClk iff (vif.iMonClk.we === 0));
        tr.opcode = vif.iMonClk.opcode;
        tr.src0 = vif.iMonClk.src0;
        tr.src1 = vif.iMonClk.src1;
        tr.src2 = vif.iMonClk.src2;
        tr.dst0 = vif.iMonClk.dst0;
        @(vif.iMonClk);
        //return;
    endtask: get_packet

endclass: iMonitor
