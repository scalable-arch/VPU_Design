`ifndef REQ_PACKET
`define REQ_PACKET


class req_packet extends uvm_sequence_item;

  rand  bit [7:0] opcode;
  rand  bit [SRAM_BANK_DEPTH_LG2-1:0] src0;
  rand  bit [SRAM_BANK_DEPTH_LG2-1:0] src1;
  rand  bit [SRAM_BANK_DEPTH_LG2-1:0] src2;
  rand  bit [SRAM_BANK_DEPTH_LG2-1:0] dst0;
  rand  bit [STREAM_ID_WIDTH-1:0]     stream_id;
  rand  bit [23:0]                    imm;
  //rand  bit [23:0]   imm;

  `uvm_object_utils_begin(req_packet)
    `uvm_field_int(opcode, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(src0, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(src1, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(src2, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(dst0, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(stream_id, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(imm, UVM_ALL_ON | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name = "req_packet");
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

endclass: req_packet
`endif // REQ_PACKET