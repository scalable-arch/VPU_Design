class scoreboard extends uvm_scoreboard;

    //typedef uvm_in_order_class_comparator #(packet) packet_cmp;
    //packet_cmp comparator;

    uvm_analysis_export #(packet) before_export;
    uvm_analysis_export #(packet) after_export;
    packet  tr_bf, tr_af;

    `uvm_component_utils(scoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        //comparator = packet_cmp::type_id::create("comparator", this);
        before_export = new("before_export", this);
        after_export  = new("after_export", this);
    endfunction: build_phase


    task run_phase(uvm_phase phase);
		forever
		begin
            for(int i = 0; i < 3; i++) begin
                before_export.get(tr_bf);
                $display("The expected rdata is");
                tr_bf.print();
            end

			after_export.get(tr_af);
            $display("The expected wdata is");
            tr_af.print();
		end
	endtask	
    /*
    virtual function string convert2string();
        return $sformatf("Comparator Matches = %0d, Mismatches = %0d", comparator.m_matches, comparator.m_mismatches);
    endfunction: convert2string

    virtual task wait_for_done(); endtask
    virtual function void set_timeout(realtime timeout); endfunction
    virtual function realtime get_timeout(); endfunction
    */
endclass: scoreboard
