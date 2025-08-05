`ifndef SIMPLE_SRAM_MODEL
`define SIMPLE_SRAM_MODEL

class simple_sram_model extends uvm_component;

    `uvm_component_utils(simple_sram_model)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: build_phase

    localparam int MEM_SIZE = 1<<16;
    bit [511:0] mem[MEM_SIZE];

    function void write(int addr, bit [511:0] value);
        mem[addr] = value;
    endfunction

    function bit [511:0] read(int addr);
        return(mem[addr]);
    endfunction

    function void init();
        bit [511:0] rand_value;
        for (int i = 0; i < MEM_SIZE; i++) begin
            //std::randomize(rand_value);
            for (int chunk = 0; chunk < 16; chunk++) begin
                rand_value[chunk*32 +: 32] = $urandom;
            end
            mem[i] = rand_value;
            //`uvm_info("SIMPLE_SRAM_MODEL", $sformatf("mem[%d]: %h\n",i,rand_value), UVM_HIGH);
        end
    endfunction
endclass
`endif // SIMPLE_SRAM_MODEL