`ifndef SRC_PACKET_SEQUENCE
`define SRC_PACKET_SEQUENCE

class src_packet_sequence_base extends uvm_sequence #(src_packet);
    `uvm_object_utils(src_packet_sequence_base)

    function new(string name = "src_packet_sequence_base");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

		`ifndef UVM_VERSION_1_1
		set_automatic_phase_objection(1);
		`endif
  	endfunction: new

	`ifdef UVM_VERSION_1_1
	virtual task pre_start();
		if ((get_parent_sequence() == null) && (starting_phase != null)) begin
			starting_phase.raise_objection(this);
		end
	endtask: pre_start

	virtual task post_start();
		if ((get_parent_sequence() == null) && (starting_phase != null)) begin
			starting_phase.drop_objection(this);
		end
	endtask: post_start
	`endif
endclass: src_packet_sequence_base

class src_packet_sequence extends src_packet_sequence_base;

	`uvm_object_utils(src_packet_sequence)
	`uvm_declare_p_sequencer(src_sequencer)

	src_packet src_req_packet;
	src_packet src_rsp_packet;

	function new(string name = "src_packet_sequence");
		super.new(name);
		`uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
	endfunction: new

	virtual task body();
		`uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
		forever begin
			p_sequencer.request_fifo.get(src_req_packet);
			`uvm_info("FIFO GET",  $sformatf("FIFO_GET\n"), UVM_MEDIUM);
			// `uvm_do_with(src_rsp_packet, {
			// 	src_rsp_packet.addr == src_req_packet.addr;
			// 	src_rsp_packet.rdata == src_sequencer.storage.read(src_req_packet.addr);
			// });
			src_rsp_packet = src_packet::type_id::create("src_rsp_packet");
			src_rsp_packet.randomize() with {
				addr == src_req_packet.addr;
			};
			src_rsp_packet.rdata = p_sequencer.storage.read(src_req_packet.addr);
			`uvm_info("SRC_SEQUENCER", {"\n", src_rsp_packet.sprint()}, UVM_MEDIUM);
			start_item(src_rsp_packet);
    		finish_item(src_rsp_packet);
		end
 	endtask: body

endclass: src_packet_sequence
`endif // SRC_PACKET_SEQUENCE