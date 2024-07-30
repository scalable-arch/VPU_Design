program automatic test;
import uvm_pkg::*;
import vpu_test_pkg::*;

initial begin

    uvm_resource_db#(virtual vpu_if)::set("vpu_if", "", vpu_test_top.vpu_if);
    uvm_resource_db#(virtual vpu_src_port_if)::set("vpu_src_port_if", "", vpu_test_top.vpu_src_port_if);
    uvm_resource_db#(virtual vpu_dst_port_if)::set("vpu_dst_port_if", "", vpu_test_top.vpu_dst_port_if);

    $timeformat(-9, 1, "ns", 10);
    run_test();
end

endprogram

