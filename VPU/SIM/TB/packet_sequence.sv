class req_packet_sequence_base extends uvm_sequence #(req_packet);
    // Factory Registration
    `uvm_object_utils(req_packet_sequence_base)

    function new(string name = "req_packet_sequence_base");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        // Objections
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

    int       req_count = 10;
    int       valid_opcode[$];

    typedef int int_q_t[$];

    // The `uvm_object_utils macro takes care of the added fields.
    `uvm_object_utils_begin(req_packet_sequence)
        `uvm_field_int(req_count, UVM_ALL_ON)
        `uvm_field_queue_int(valid_opcode, UVM_ALL_ON)
        //`uvm_field_int(port_id, UVM_ALL_ON)
    `uvm_object_utils_end


    virtual task pre_start();
        super.pre_start();
        uvm_config_db#(int)::get(get_sequencer(), get_type_name(), "req_count", req_count);
        uvm_config_db#(int_q_t)::get(get_sequencer(), get_type_name(), "valid_opcode", valid_opcode);
    endtask: pre_start

    function new(string name = "req_packet_sequence");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
        for (int i=0; i<16; i++) begin
            valid_opcode.push_back(i);    // Valid Opcode
        end
    endfunction: new

    virtual task body();
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        // Instead of hard coding the number of item to be generated, the hard-coded value 10 has been replaced
        // with a configuration field - item_count.
        repeat(req_count) begin

            // For UVM-1.1 & UVM-1.2
            `ifndef UVM_VERSION
                `uvm_do_with(req, {opcode inside valid_opcode;});
            // For IEEE UVM
            `else
                `uvm_do(req,,, {opcode inside valid_opcode;});
            `endif
        end
    endtask: body
endclass: req_packet_sequence

class sram_read_tr_sequence_base extends uvm_sequence #(sram_read_tr);
    // Factory Registration
    `uvm_object_utils(sram_read_tr_sequence_base)

    function new(string name = "sram_read_tr_sequence_base");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        // Objections
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
endclass: sram_read_tr_sequence_base

class sram_read_tr_sequence extends sram_read_tr_sequence_base;

    int       item_count = 10;
    int       port_id    = -1;

    `uvm_object_utils_begin(sram_read_tr_sequence)
        `uvm_field_int(item_count, UVM_ALL_ON)
        `uvm_field_int(port_id, UVM_ALL_ON)
    `uvm_object_utils_end

    virtual task pre_start();
        super.pre_start();
        uvm_config_db#(int)::get(get_sequencer(), get_type_name(), "item_count", item_count);
        uvm_config_db#(int)::get(get_sequencer().get_parent(), "", "port_id",port_id);
        if (!(port_id inside {-1, [0:2]})) begin
        `uvm_fatal("CFGERR", $sformatf("Illegal port_id value of %0d", port_id));
        end
    endtask: pre_start

    function new(string name = "sram_read_tr_sequence");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual task body();
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        repeat(item_count) begin
            // For UVM-1.1 & UVM-1.2
            `ifndef UVM_VERSION
                `uvm_do_with(req, {if (port_id == -1) sa inside {[0:2]}; else sa == port_id;});
            // For IEEE UVM
            `else
                `uvm_do(req,,, {if (port_id == -1) sa inside {[0:2]}; else sa == port_id;});
            `endif
        end
    endtask: body

endclass: sram_read_tr_sequence

class sram_write_tr_sequence_base extends uvm_sequence #(sram_write_tr);
    // Factory Registration
    `uvm_object_utils(sram_write_tr_sequence_base)

    function new(string name = "sram_write_tr_sequence_base");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        // Objections
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
endclass: sram_write_tr_sequence_base

class sram_write_tr_sequence extends sram_write_tr_sequence_base;

    int       item_count = 10;

    `uvm_object_utils_begin(sram_write_tr_sequence)
        `uvm_field_int(item_count, UVM_ALL_ON)
    `uvm_object_utils_end

    virtual task pre_start();
        super.pre_start();
        uvm_config_db#(int)::get(get_sequencer(), get_type_name(), "item_count", item_count);
    endtask: pre_start

    function new(string name = "sram_write_tr_sequence");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual task body();
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);

        repeat(item_count) begin
            // For UVM-1.1 & UVM-1.2
            `ifndef UVM_VERSION
                `uvm_do_with(req);
            // For IEEE UVM
            `else
                `uvm_do(req);
            `endif
        end
    endtask: body

endclass: sram_write_tr_sequence