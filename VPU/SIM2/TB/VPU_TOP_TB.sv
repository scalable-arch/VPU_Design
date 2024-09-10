`include "VPU_PKG.svh"
`define TIMEOUT_DELAY   50000000
`define ITER 7
module VPU_TOP_TB ();
    import VPU_PKG::*;
    reg                     clk;
    reg                     rst_n;
    
    VPU_PKG::vpu_h2d_req_opcode_t opcode_queue[$];

    typedef struct  {
        bit [15:0] data[31]; 
    } rdata_t;

    typedef rdata_t rdata_queue[$];
    rdata_t rdata_0;
    rdata_queue tot_rdata_queue[$];
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

    VPU_SRC_PORT_IF             vpu_src_port_if[SRAM_R_PORT_CNT](.clk(clk),.rst_n(rst_n));
/*
    VPU_SRC_PORT_IF             vpu_src0_port_if (
        .clk                        (clk),
        .rst_n                      (rst_n)
    );

    VPU_SRC_PORT_IF             vpu_src1_port_if (
        .clk                        (clk),
        .rst_n                      (rst_n)
    );

    VPU_SRC_PORT_IF             vpu_src2_port_if (
        .clk                        (clk),
        .rst_n                      (rst_n)
    );
*/
    VPU_DST_PORT_IF             vpu_dst0_port_if (
        .clk                        (clk),
        .rst_n                      (rst_n)
    );

    VPU_TOP #(
        //...
    ) u_DUT (
        .clk                (clk),
        .rst_n              (rst_n),

        .vpu_req_if         (vpu_req_if),
        .vpu_src0_port_if   (vpu_src_port_if[0]),
        .vpu_src1_port_if   (vpu_src_port_if[1]),
        .vpu_src2_port_if   (vpu_src_port_if[2]),
        .vpu_dst0_port_if   (vpu_dst0_port_if)
    );

    // enable waveform dump
    initial begin
        $dumpvars(0, u_DUT);
        $dumpfile("dump.vcd");
    end

    task test_init();
        vpu_req_if.init();
        vpu_src_port_if[0].init();
        vpu_src_port_if[1].init();
        vpu_src_port_if[2].init();
        vpu_dst0_port_if.init();
        
        for(int i = 0; i < VPU_PKG::SRAM_R_PORT_CNT; i++) begin
            tot_rdata_queue.push_back('{});
        end
        @(posedge rst_n); 
        repeat (10) @(posedge clk);
    endtask

    task automatic gen_trans();
        VPU_PKG::vpu_h2d_req_opcode_t gen_opcode;
        integer i;
        //rdata_t rdata_t;
        for(i = 0; i < `ITER; i++) begin
            //Generate Opcode
            //gen_opcode = possible_opcode[$urandom_range(0, 6)];
            gen_opcode = 5;
            $write("%3dth opcode : %d\n", i, gen_opcode); 
            opcode_queue.push_back(gen_opcode);

            //Generate Rdata
            //rdata_t rdata;
            $write("%3dth rdata ||\n", i);
            for(int j = 0; j < VPU_PKG::SRAM_R_PORT_CNT; j=j+1) begin
                for(int k=0; k<32; k=k+1) begin
                    rdata_0.data[k] = ($random % 5) & {SRAM_DATA_WIDTH{1'b1}};
                    $write("rdata[%1d][%1d] : 0x%08h\n", j,k,rdata_0.data[k]); 
                end
                $write("\n"); 
                tot_rdata_queue[j].push_back(rdata_0);
            end
        end
    endtask

    task automatic request_tr();
        VPU_PKG::vpu_h2d_req_opcode_t gen_opcode;
        integer i;
        for(i = 0; i < `ITER; i++) begin
            gen_opcode = opcode_queue.pop_front();
            vpu_req_if.gen_request(gen_opcode);
        end
    endtask
    
    task automatic sram_read_tr_0(input int port_id);
        integer i;
        rdata_t rdata;
        bit [511:0] _rdata;
        for(i = 0; i < `ITER; i++) begin
            rdata = tot_rdata_queue[port_id].pop_front();
            for(int j=0; j < 32; j=j+1) begin
                _rdata[j*OPERAND_WIDTH+:OPCODE_WIDTH] = rdata.data[j];
            end
            vpu_src_port_if[0].sram_read_transaction(_rdata);
        end
    endtask

    task automatic sram_read_tr_1(input int port_id);
        integer i;
        rdata_t rdata;
        bit [511:0] _rdata;
        for(i = 0; i < `ITER; i++) begin
            rdata = tot_rdata_queue[port_id].pop_front();
            for(int j=0; j < 32; j=j+1) begin
                _rdata[j*OPERAND_WIDTH+:OPCODE_WIDTH] = rdata.data[j];
            end
            vpu_src_port_if[1].sram_read_transaction(_rdata);
        end
    endtask

    task automatic sram_read_tr_2(input int port_id);
        integer i;
        rdata_t rdata;
        bit [511:0] _rdata;
        for(i = 0; i < `ITER; i++) begin
            rdata = tot_rdata_queue[port_id].pop_front();
            for(int j=0; j < 32; j=j+1) begin
                _rdata[j*OPERAND_WIDTH+:OPCODE_WIDTH] = rdata.data[j];
            end
            vpu_src_port_if[2].sram_read_transaction(_rdata);
        end
    endtask

    task automatic sram_write_tr();
        integer i;
        bit [511:0] wdata;
        for(i = 0; i < `ITER; i++) begin
            $write("%3dth wdata ||\n", i);
            vpu_dst0_port_if.sram_write_transaction(wdata);
            for(int j=0; j < 32; j=j+1) begin
                $write("wdata[%1d][%1d] : 0x%08h\n", i,j, wdata[j*OPERAND_WIDTH+:OPCODE_WIDTH]); 
            end
        end
        repeat (10) @(posedge clk);
        $finish();
    endtask

    initial begin
        $display("Start Simulation!");
        
        test_init();
        gen_trans();
        fork
            request_tr();
            sram_read_tr_0(0);
            sram_read_tr_1(1);
            sram_read_tr_2(2);
            sram_write_tr();
        join
        $display("Simulation Done!");
        $finish;
    end

endmodule