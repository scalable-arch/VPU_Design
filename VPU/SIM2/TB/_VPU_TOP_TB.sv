`include "VPU_PKG.svh"
`define TIMEOUT_DELAY   5000000
`define ITER 7
module VPU_TOP_TB ();
    import VPU_PKG::*;
    reg                     clk;
    reg                     rst_n;
    
    VPU_PKG::vpu_h2d_req_opcode_t opcode_queue[$];
    typedef struct  {
        bit [15:0] rdata[31]; 
    } data_16bit_32_array_t;

    typedef struct  {
        data_16bit_32_array_t rdata_array[3];
    } rdata_t;

    rdata_t rdata_queue[$];
    bit [511:0]  wdata_queue[$];

    VPU_PKG::vpu_h2d_req_opcode_t possible_opcode[1]  = '{ 
        // Unsigned Int
        //VPU_H2D_REQ_OPCODE_UIADD, 
        //VPU_H2D_REQ_OPCODE_UIADD3,
        //VPU_H2D_REQ_OPCODE_UIMUL,
        //VPU_H2D_REQ_OPCODE_UISUM,
        //VPU_H2D_REQ_OPCODE_FADD,
        //VPU_H2D_REQ_OPCODE_FSUM,
        VPU_H2D_REQ_OPCODE_FMAX
    };

    // clock generation
    initial begin
        clk                     = 1'b0;

        forever #10 clk         = !clk;
    end

    // reset generation
    initial begin
        rst_n                   = 1'b0;     // active at time 0

        repeat (3) @(posedge clk);          // after 3 cycles,
        rst_n                   = 1'b1;     // release the reset
    end
    
    //timeout
    initial begin
        #`TIMEOUT_DELAY $display("Timeout!");
        $finish;
    end

    //----------------------------------------------------------
    // Connection between DUT and test modules
    //----------------------------------------------------------

    VPU_REQ_IF                  vpu_req_if (
        .clk                        (clk),
        .rst_n                      (rst_n)
    );

    VPU_SRC_PORT_IF             vpu_src_port_if (
        .clk                        (clk),
        .rst_n                      (rst_n)
    );

    VPU_DST_PORT_IF             vpu_dst_port_if (
        .clk                        (clk),
        .rst_n                      (rst_n)
    );

    VPU_TOP #(
        //...
    ) u_DUT (
        .clk                (clk),
        .rst_n              (rst_n),

        .vpu_req_if         (vpu_req_if),
        .vpu_src_port_if    (vpu_src_port_if),
        .vpu_dst_port_if    (vpu_dst_port_if)
    );

    // enable waveform dump
    initial begin
        $dumpvars(0, u_DUT);
        $dumpfile("dump.vcd");
    end

    task test_init();
        vpu_req_if.init();
        vpu_src_port_if.init();
        vpu_dst_port_if.init();
        @(posedge rst_n); 
        repeat (10) @(posedge clk);
    endtask

    task trans_init();
        VPU_PKG::vpu_h2d_req_opcode_t gen_opcode;
        rdata_t _rdata;
        integer i;
        for(i = 0; i < `ITER; i++) begin
            //Generate Opcode
            //gen_opcode = possible_opcode[$urandom_range(0, 6)];
            gen_opcode = 17;
            $write("%3dth opcode : %d\n", i, gen_opcode); 
            opcode_queue.push_back(gen_opcode);
            //Generate Rdata
            $write("%3dth rdata ||\n", i);
            for(int j = 0; j < 3; j=j+1) begin
                for(int k=0; k<32; k=k+1) begin
                    _rdata.rdata_array[j].rdata[k] = ($random % 5) & {SRAM_DATA_WIDTH{1'b1}};
                    $write("rdata[%1d][%1d] : 0x%08h\n", j,k,_rdata.rdata_array[j].rdata[k]); 
                end
                $write("\n"); 
            end
            rdata_queue.push_back(_rdata);
        end
    endtask

    task gen_request();
        VPU_PKG::vpu_h2d_req_opcode_t gen_opcode;
        integer i;
        for(i = 0; i < `ITER; i++) begin
            gen_opcode = opcode_queue.pop_front();
            vpu_req_if.gen_request(gen_opcode);
        end
    endtask
    
    task sram_read_tr();
        integer i;
        rdata_t rdata;
        bit [511:0] _rdata [3];
        for(i = 0; i < `ITER; i++) begin
            rdata = rdata_queue.pop_front();
            for(int k =0; k<3; k=k+1) begin
                for(int j=0; j < 32; j=j+1) begin
                    _rdata[k][j*OPERAND_WIDTH+:OPCODE_WIDTH] = rdata.rdata_array[k].rdata[j];
                end
            end
            vpu_src_port_if.sram_read_transaction(_rdata);
        end
    endtask

    task sram_write_tr();
        integer i;
        bit [511:0] wdata;
        for(i = 0; i < `ITER; i++) begin
            $write("%3dth wdata ||\n", i);
            vpu_dst_port_if.sram_write_transaction(wdata);
            for(int j=0; j < 32; j=j+1) begin
                $write("wdata[%1d][%1d] : 0x%08h\n", i,j, wdata[j*OPERAND_WIDTH+:OPCODE_WIDTH]); 
            end
        end
    endtask

    initial begin
        $display("Start Simulation!");
        
        test_init();
        trans_init();
        fork
            gen_request();
            sram_read_tr();
            sram_write_tr();
        join
        $display("Simulation Done!");
        $finish;
    end

endmodule