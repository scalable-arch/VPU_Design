class req_iMonitor extends uvm_monitor;

    virtual vpu_if vif;
    
    uvm_analysis_port #(req_packet) analysis_port;

    `uvm_component_utils(req_iMonitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        uvm_config_db#(virtual vpu_if)::get(this, "", "vif", vif);

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

        req_packet tr;
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        forever begin
            tr = req_packet::type_id::create("tr", this);
            get_packet(tr);
            `uvm_info("Got_Input_Packet", {"\n", tr.sprint()}, UVM_MEDIUM);
            analysis_port.write(tr);
        end
    endtask: run_phase

    virtual task get_packet(req_packet tr);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        wait (vif.iMonClk.we !== 1);
        @(vif.iMonClk iff (vif.iMonClk.we === 1));
        tr.opcode = vif.iMonClk.opcode;
        tr.src0 = vif.iMonClk.src0;
        tr.src1 = vif.iMonClk.src1;
        tr.src2 = vif.iMonClk.src2;
        tr.dst0 = vif.iMonClk.dst0;
        @(vif.iMonClk);
        //return;
    endtask: get_packet

endclass: req_iMonitor

class sram_read_tr_iMonitor extends uvm_monitor;

    virtual vpu_scr_port_if vif;
    int                     port_id = -1;

    uvm_analysis_port #(sram_read_tr) analysis_port;

    `uvm_component_utils_begin(sram_read_tr_iMonitor)
        `uvm_field_int(port_id, UVM_ALL_ON | UVM_DEC)
    `uvm_component_utils_end
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        uvm_config_db#(virtual vpu_scr_port_if)::get(this, "", "vif", vif);

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

        sram_read_tr tr;
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        forever begin
            tr = sram_read_tr::type_id::create("tr", this);
            tr.sa = this.port_id;
            get_packet(tr);
            `uvm_info("Got_Input_Packet", {"\n", tr.sprint()}, UVM_MEDIUM);
            analysis_port.write(tr);
        end
    endtask: run_phase

    virtual task get_packet(sram_read_tr tr);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        wait (vif.iMonClk.rvalid[port_id] !== 1);
        @(vif.iMonClk iff (vif.iMonClk.rvalid[port_id] === 1));
        tr.rdata = vif.iMonClk.rdata[port_id];
        @(vif.iMonClk);
        //return;
    endtask: get_packet

endclass: sram_read_tr_iMonitor

class sram_write_tr_oMonitor extends uvm_monitor;

    virtual vpu_dst_port_if vif;
    
    uvm_analysis_port #(sram_write_tr) analysis_port;

    `uvm_component_utils(sram_write_tr_oMonitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        uvm_config_db#(virtual vpu_dst_port_if)::get(this, "", "vif", vif);

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

        sram_write_tr tr;
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        forever begin
            tr = sram_write_tr::type_id::create("tr", this);
            get_packet(tr);
            `uvm_info("Got_Input_Packet", {"\n", tr.sprint()}, UVM_MEDIUM);
            analysis_port.write(tr);
        end
    endtask: run_phase

    virtual task get_packet(sram_write_tr tr);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        wait (vif.oMonClk.req !== 1);
        @(vif.oMonClk iff (vif.oMonClk.req === 1));
        tr.wdata = vif.oMonClk.wdata;
        @(vif.oMonClk);
        //return;
    endtask: get_packet

endclass: sram_write_tr_oMonitor
