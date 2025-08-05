`ifndef SRC_MONITOR
`define SRC_MONITOR

class src_monitor extends uvm_monitor;

    vpu_src_if src_vif;
    simple_sram_model storage;

    uvm_analysis_port #(src_packet) transaction_aport; // full
    uvm_analysis_port #(src_packet) request_aport; // partial

    `uvm_component_utils(src_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        uvm_config_db#(vpu_src_if)::get(this, "", "src_vif", src_vif);
        uvm_config_db#(simple_sram_model)::get(this, "", "storage", storage);
        
        transaction_aport = new("transaction_aport", this);
        request_aport = new("request_aport", this);
    endfunction: build_phase

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        if (src_vif == null) begin
            `uvm_fatal("CFGERR", "Interface for src_monitor not set");
        end
    endfunction: end_of_elaboration_phase

    virtual task run_phase(uvm_phase phase);
        fork
            storage_init();
            monitor_bus();
        join
    endtask

    task storage_init();
        wait (src_vif.rst_n !== 0);
        @(src_vif.iMonClk iff (src_vif.rst_n === 1'b1));
        storage.init();
    endtask

    task monitor_bus();
        src_packet tr;
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        `uvm_info("Error Check",  $sformatf("%m"), UVM_HIGH);
        forever begin
            tr = src_packet::type_id::create("tr", this);
            monitor_req(tr);
            `uvm_info("Got Src_REQ Packet", {"\n", tr.sprint()}, UVM_MEDIUM);
            request_aport.write(tr); // publish request part
            monitor_rsp(tr);
            `uvm_info("Send Src_Rsp Packet", {"\n", tr.sprint()}, UVM_MEDIUM);
            transaction_aport.write(tr); // publish full
        end
    endtask

    virtual task monitor_req(src_packet tr);
        wait (src_vif.rst_n !== 0);
        do begin
            @(src_vif.oMonClk);     
        end while (!src_vif.oMonClk.req);  
        tr.rid  = src_vif.oMonClk.rid;
        tr.addr = src_vif.oMonClk.addr;
        `uvm_info("Request Check", {"\n", tr.sprint()}, UVM_MEDIUM);
        //`uvm_info("Request Check",  $sformatf("addr : %0d", src_vif.oMonClk.addr), UVM_MEDIUM);
    endtask

    virtual task monitor_rsp(src_packet tr);
        wait (src_vif.iMonClk.rvalid !==0);
        @(src_vif.iMonClk iff (src_vif.iMonClk.rvalid === 1'b1));
            tr.rdata  = src_vif.iMonClk.rdata;
    endtask
endclass
`endif // SRC_MONITOR