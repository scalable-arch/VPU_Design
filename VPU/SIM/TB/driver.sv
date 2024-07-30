class req_driver extends uvm_driver #(req_packet);
    virtual vpu_if vif;           // DUT virtual interface

    `uvm_component_utils(req_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        uvm_config_db#(virtual vpu_if)::get(this, "", "vif", vif);
    endfunction: build_phase

    //
    // The UVM end_of_elaboration phase is designed for checking the
    // correctness of testbench structure and the configuration variables.
    //
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        if (vif == null) begin
            `uvm_fatal("CFGERR", "Interface for Driver not set");
        end
    endfunction: end_of_elaboration_phase

    //
    // The UVM start_of_simulation phase is designed for displaying the testbench configuration
    // before any active verification operation starts.
    //
    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: start_of_simulation_phase

    virtual task run_phase(uvm_phase phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        forever begin
            seq_item_port.get_next_item(req);
            send(req);
            `uvm_info("DRV_RUN", {"\n", req.sprint()}, UVM_MEDIUM);
            seq_item_port.item_done();
        end
    endtask: run_phase

    virtual task send(req_packet tr);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        send_request(tr);
    endtask: send

    virtual task send_request(req_packet tr);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        while(!vif.drvClk.afull) @(vif.drvClk);
        
        vif.drvClk.we <= 1'b1;
        vif.drvClk.opcode <= tr.opcode;
        vif.drvClk.src0   <= tr.src0;
        vif.drvClk.src1   <= tr.src1;
        vif.drvClk.src2   <= tr.src3;
        vif.drvClk.dst0   <= tr.dst0;
        @(vif.drvClk);

        vif.drvClk.we <= 1'b0;
    endtask

endclass: req_driver

class sram_read_tr_driver extends uvm_driver #(sram_read_tr);
    virtual vpu_scr_port_if vif;           // DUT virtual interface

    `uvm_component_utils(sram_read_tr_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        uvm_config_db#(virtual vpu_scr_port_if)::get(this, "", "vif", vif);
    endfunction: build_phase

    //
    // The UVM end_of_elaboration phase is designed for checking the
    // correctness of testbench structure and the configuration variables.
    //
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        if (vif == null) begin
            `uvm_fatal("CFGERR", "Interface for Driver not set");
        end
    endfunction: end_of_elaboration_phase

    //
    // The UVM start_of_simulation phase is designed for displaying the testbench configuration
    // before any active verification operation starts.
    //
    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: start_of_simulation_phase

    virtual task run_phase(uvm_phase phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        forever begin
            seq_item_port.get_next_item(req);
            send(req);
            `uvm_info("DRV_RUN", {"\n", req.sprint()}, UVM_MEDIUM);
            seq_item_port.item_done();
        end
    endtask: run_phase

    virtual task send(sram_read_tr tr);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        send_ack(tr);
        send_rdata(tr);
    endtask: send

    virtual task send_ack(sram_read_tr tr);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        for(int i = 0; i < 3; i++) begin
            while(!vif.drvClk.req) @(vif.drvClk);
            vif.drvClk.ack <= 1'b1;
            @(vif.drvClk);
            vif.drvClk.ack <= 1'b0;
            @(vif.drvClk);
        end
    endtask

    virtual task send_rdata(sram_read_tr tr);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        repeat(5) @(vif.drvClk);
        for(int i = 0; i < 3; i++) begin
            vif.drvClk.rvalid[i] <= 1'b1;
            vif.drvClk.rdata[i] <= tr.rdata
        end
        @(vif.drvClk); vif.drvClk.rvalid <= 1'b0;
    endtask
endclass: sram_read_tr_driver



class sram_write_tr_driver extends uvm_driver #(sram_write_tr);
    virtual vpu_dst_port_if vif;           // DUT virtual interface

    `uvm_component_utils(sram_write_tr_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        uvm_config_db#(virtual vpu_dst_port_if)::get(this, "", "vif", vif);
    endfunction: build_phase

    //
    // The UVM end_of_elaboration phase is designed for checking the
    // correctness of testbench structure and the configuration variables.
    //
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        if (vif == null) begin
            `uvm_fatal("CFGERR", "Interface for Driver not set");
        end
    endfunction: end_of_elaboration_phase

    //
    // The UVM start_of_simulation phase is designed for displaying the testbench configuration
    // before any active verification operation starts.
    //
    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: start_of_simulation_phase

    virtual task run_phase(uvm_phase phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        forever begin
            seq_item_port.get_next_item(req);
            send(req);
            `uvm_info("DRV_RUN", {"\n", req.sprint()}, UVM_MEDIUM);
            seq_item_port.item_done();
        end
    endtask: run_phase

    virtual task send(sram_write_tr tr);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        send_ack(tr);
    endtask: send

    virtual task send_ack(sram_write_tr tr);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        while(!vif.drvClk.req) @(vif.drvClk);
        vif.drvClk.ack <= 1'b1;
        @(vif.drvClk);
        vif.drvClk.ack <= 1'b0;
        @(vif.drvClk);
    endtask
endclass: sram_write_tr_driver