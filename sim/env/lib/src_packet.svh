`ifndef SRC_PACKET
`define SRC_PACKET

class src_packet extends uvm_sequence_item;

  // rand  bit [VPU_PKG::SRAM_BANK_CNT_LG2-1:0]    rid;
  // rand  bit [VPU_PKG::SRAM_BANK_DEPTH_LG2-1:0]  addr;
  // rand  bit [VPU_PKG::DIM_SIZE-1:0]             rdata;

  rand  bit [SRAM_BANK_CNT_LG2-1:0]    rid;
  rand  bit [SRAM_BANK_DEPTH_LG2-1:0]   addr;
  rand  bit [DIM_SIZE-1:0]             rdata;

  `uvm_object_utils_begin(src_packet)
      `uvm_field_int(rid, UVM_ALL_ON | UVM_NOCOMPARE)
      `uvm_field_int(addr, UVM_ALL_ON | UVM_NOCOMPARE)
      `uvm_field_int(rdata, UVM_ALL_ON)
  `uvm_object_utils_end

  //constraint valid {
  //  payload.size inside {[1:10]};
  //}

  function new(string name = "src_packet");
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

endclass: src_packet
`endif // SRC_PACKET