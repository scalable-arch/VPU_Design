`ifndef REQ_PACKET_SEQUENCE
`define REQ_PACKET_SEQUENCE

class req_packet_sequence_base extends uvm_sequence #(req_packet);
    `uvm_object_utils(req_packet_sequence_base)

    function new(string name = "req_packet_sequence_base");
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
endclass: req_packet_sequence_base

class req_packet_sequence extends req_packet_sequence_base;

  int req_count = 10;

	`uvm_object_utils_begin(req_packet_sequence)
    `uvm_field_int(req_count, UVM_ALL_ON)
  `uvm_object_utils_end

	function new(string name = "req_packet_sequence");
		super.new(name);
		`uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
	endfunction: new

  virtual task pre_start();
    super.pre_start();
    uvm_config_db#(int)::get(get_sequencer(), get_type_name(), "req_count", req_count);
  endtask: pre_start

	virtual task body();
		`uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    repeat(req_count) begin
      `uvm_do_with(req, {
        opcode inside {[1:14]};
        dst0 inside {[0:(1<<16)]};
        src0 inside {[0:(1<<16)]};
        src1 inside {[0:(1<<16)]};
        src2 inside {[0:(1<<16)]};
      });
    end
 	endtask: body

endclass: req_packet_sequence
`endif // REQ_PACKET_SEQUENCE