`ifndef DST_PACKET
`define DST_PACKET


class dst_packet extends uvm_sequence_item;
  rand  bit [1:0]     wid;
  rand  bit [9:0]     addr;
  rand  bit [511:0]   wdata;

  `uvm_object_utils_begin(dst_packet)
    `uvm_field_int(wid, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(addr, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(wdata, UVM_ALL_ON)
  `uvm_object_utils_end

  //constraint valid {
  //  payload.size inside {[1:10]};
  //}

  function new(string name = "dst_packet");
    super.new(name);
    `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
  endfunction: new

endclass: dst_packet
`endif // DST_PACKET