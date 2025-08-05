`ifndef SIMPLE_DST_RESPONDER
`define SIMPLE_DST_RESPONDER

class simple_dst_responder extends uvm_component;
    `uvm_component_utils(simple_dst_responder)

    vpu_dst_if dst_vif;
    uvm_analysis_port #(dst_packet) analysis_port;
    simple_sram_model storage;

    function new(string name = "simple_dst_responder", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_port = new("analysis_port", this);
        if (!uvm_config_db#(vpu_dst_if)::get(this, "", "dst_vif", dst_vif))
            `uvm_fatal("VIF_ERR", "Virtual interface for simple_dst_responder not set");
        if (!uvm_config_db#(simple_sram_model)::get(this, "", "storage", storage))
            `uvm_fatal("CFG_ERR", "Storage handle not found for responder");
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            wait (dst_vif.rst_n !== 0);
            do begin
                @(dst_vif.oMonClk);     
            end while (!dst_vif.oMonClk.req);  
            fork
                begin
                    @(posedge dst_vif.drvClk);
                        dst_vif.ack <= 1'b1;
                        storage.write(dst_vif.addr, dst_vif.wdata);
                    @(posedge dst_vif.drvClk);
                        dst_vif.ack <= 1'b0;
                end

                begin
                    dst_packet tr;
                    tr = dst_packet::type_id::create("tr");
                    tr.addr = dst_vif.addr;
                    tr.wid  = dst_vif.wid;
                    tr.wdata = dst_vif.wdata;
                    `uvm_info("DST_RESPONDER", {"\n", tr.sprint()}, UVM_MEDIUM);
                    analysis_port.write(tr);
                end
            join
        end
    endtask
endclass
`endif // SIMPLE_DST_RESPONDER