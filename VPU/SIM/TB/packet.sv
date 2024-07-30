// All transaction classes must be extended from the uvm_sequence_item base class.
class req_packet extends uvm_sequence_item;

    rand bit [7:0]  opcode;
    rand bit [31:0] src0, src1, src2;
    rand bit [31:0] dst0;
    rand bit        we;

    `uvm_object_utils_begin(req_packet)
        `uvm_field_int(opcode, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(src0, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(src1, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(src2, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(dst0, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(we, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_object_utils_end

    constraint valid {
        we > 'd0;
    }

    function new(string name = "req_packet");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

endclass: req_packet
    
class sram_read_tr extends uvm_sequence_item;
    rand bit [1:0] sa, da;
    rand bit[511:0] rdata[$];

    `uvm_object_utils_begin(sram_read_tr)
        `uvm_field_int(sa, UVM_ALL_ON | UVM_NOCOMPARE)
        `uvm_field_int(da, UVM_ALL_ON)
        `uvm_field_queue_int(rdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "sram_read_tr");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new
endclass: sram_read_tr


class sram_write_tr extends uvm_sequence_item;
    rand bit[511:0] wdata[$];

    `uvm_object_utils_begin(sram_write_tr)
        `uvm_field_queue_int(wdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "sram_write_tr");
        super.new(name);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new
endclass: sram_write_tr