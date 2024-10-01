`include "VPU_PKG.svh"
`define TIMEOUT_DELAY   100000000
`define MEM_DEPTH 10
`define RANDOM_SEED     12123344

module VPU_TOP_TB ();

    import VPU_PKG::*;
    reg                     clk;
    reg                     rst_n;
    
    localparam              REQ_CNT = `MEM_DEPTH;

    typedef struct  {
        bit [VPU_PKG::DIM_SIZE-1:0] operand; 
    } operand_t;

    // Input Argument
    int                             opcode_value;
    string                          test_vector_f;
    string                          golden_ref_f;
    // Data Structure
    //VPU_PKG::vpu_h2d_req_opcode_t   opcode_queue[$];
    
    VPU_PKG::vpu_h2d_req_opcode_t   opcode = 'h0D;
    VPU_PKG::vpu_h2d_req_instr_t    instr_queue[$];
    typedef operand_t               src_queue[$];
    typedef operand_t               dst_queue[$];
    src_queue                       tot_src_queue[VPU_PKG::SRAM_R_PORT_CNT];
    dst_queue                       tot_dst_queue[VPU_PKG::SRAM_W_PORT_CNT];

    reg [VPU_PKG::OPERAND_WIDTH-1:0] mem_dump[VPU_PKG::ELEM_PER_DIM_CNT * VPU_PKG::SRAM_R_PORT_CNT * `MEM_DEPTH];
    reg [VPU_PKG::OPERAND_WIDTH-1:0] golden_ref_dump[VPU_PKG::ELEM_PER_DIM_CNT * REQ_CNT];


    // timeout
	initial begin
		#`TIMEOUT_DELAY $display("Timeout!");
		$finish;
	end
    
    // opcode generation
    initial begin
        if ($value$plusargs("OPCODE=%d", opcode_value)) begin
            //opcode = vpu_h2d_req_opcode_t'(opcode_value & {8{1'b1}});
            $display("OPCODE : %05d", opcode_value);
            //opcode = vpu_h2d_req_opcode_t'(opcode_value);
        end else begin
            $display("OPCODE Not Found");
        end
    end

    // opcode generation
    initial begin
        if ($value$plusargs("TESTVECTOR=%s", test_vector_f)) begin
            $display("TESTVECTOR : %s", test_vector_f);
            //opcode = vpu_h2d_req_opcode_t'(opcode_value);
        end else begin
            $display("TESTVECTOR Not Found");
        end
    end
    //w

    // opcode generation
    initial begin
        if ($value$plusargs("GOLDEN_FILE=%s", golden_ref_f)) begin
            $display("GOLDEN_FILE : %s", golden_ref_f);
            //opcode = vpu_h2d_req_opcode_t'(opcode_value);
        end else begin
            $display("GOLDEN_FILE Not Found");
        end
    end

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

    // inject random seed
    initial begin
        $srandom(`RANDOM_SEED);
    end

    //----------------------------------------------------------
    // Connection between DUT and test modules
    //----------------------------------------------------------

    VPU_REQ_IF                  vpu_req_if (.clk(clk), .rst_n(rst_n));
    VPU_SRC_PORT_IF             vpu_src0_port_if (.clk(clk), .rst_n(rst_n));
    VPU_SRC_PORT_IF             vpu_src1_port_if (.clk(clk), .rst_n(rst_n));
    VPU_SRC_PORT_IF             vpu_src2_port_if (.clk(clk), .rst_n(rst_n));
    VPU_DST_PORT_IF             vpu_dst0_port_if (.clk(clk), .rst_n(rst_n));
    
    VPU_TOP #(
        //...
    ) u_DUT (
        .clk                (clk),
        .rst_n              (rst_n),

        .vpu_req_if         (vpu_req_if),
        .vpu_src0_port_if   (vpu_src0_port_if),
        .vpu_src1_port_if   (vpu_src1_port_if),
        .vpu_src2_port_if   (vpu_src2_port_if),
        .vpu_dst0_port_if   (vpu_dst0_port_if)
    );

    // enable waveform dump
    initial begin
        $dumpvars(0, u_DUT);
        $dumpfile("dump.vcd");
    end

    task test_init();
        vpu_req_if.init();
        vpu_src0_port_if.init();
        vpu_src1_port_if.init();
        vpu_src2_port_if.init();
        vpu_dst0_port_if.init();

        $display("Loading Data...");
        $readmemh(test_vector_f,mem_dump);

        $display("Loading Golden Ref...");
        $readmemh(golden_ref_f,golden_ref_dump);

        @(posedge rst_n); 
        repeat (10) @(posedge clk);
    endtask
    

    task gen_instr();
        VPU_PKG::vpu_h2d_req_instr_t instr;
        for(int i = 0; i < REQ_CNT; i++) begin
            instr.opcode            = vpu_h2d_req_opcode_t'(opcode_value & {8{1'b1}});
            $write("Gen Opcode...%1d\n", instr.opcode);
            instr.src2              = $random & {VPU_PKG::OPERAND_ADDR_WIDTH{1'b1}};
            instr.src1              = $random & {VPU_PKG::OPERAND_ADDR_WIDTH{1'b1}};
            instr.src0              = $random & {VPU_PKG::OPERAND_ADDR_WIDTH{1'b1}};
            instr.dst0              = $random & {VPU_PKG::OPERAND_ADDR_WIDTH{1'b1}};

            instr_queue.push_back(instr);
            $write("Gen Instr...%1d\n", i);
        end
        $write("Finish Gen Instr...\n");
    endtask

    task fill_src_operand_queue();
        operand_t operand;
        for(int i = 0; i < `MEM_DEPTH; i++) begin
            for(int j = 0; j < SRAM_R_PORT_CNT; j++) begin
                for(int k = 0; k < ELEM_PER_DIM_CNT; k++) begin
                    operand.operand[(k*VPU_PKG::OPERAND_WIDTH)+:VPU_PKG::OPERAND_WIDTH] = mem_dump[((i*VPU_PKG::ELEM_PER_DIM_CNT*VPU_PKG::SRAM_R_PORT_CNT)+(j)*(VPU_PKG::ELEM_PER_DIM_CNT))+k];
                end
                tot_src_queue[j].push_back(operand);
                $write("src[%d]port | answer : [0x%08h]\n", j, operand.operand);
            end
        end
        repeat (3) @(posedge clk);
    endtask

    task clear_dst_operand_queue();
        for(int i = 0; i < SRAM_W_PORT_CNT; i++) begin
            tot_dst_queue[i].delete();
        end 
        repeat (3) @(posedge clk);
    endtask

    task build_test();
        fill_src_operand_queue();
        clear_dst_operand_queue(); 
        gen_instr();
    endtask

    task run();
        fork
            driver_req();
            driver_src0;
            driver_src1;
            driver_src2;
            //driver_dst0;
            oMonitor();
        join
    endtask

    task run_test();
        run();
    endtask

    task driver_req();
        VPU_PKG::vpu_h2d_req_instr_t instr;
        while (instr_queue.size()!=0) begin
            $write("Push Instr...%1d\n", instr_queue.size());
            instr = instr_queue.pop_front();	// pop a request from the queue
            vpu_req_if.gen_request(instr);	    // drive to DUT
        end
        
    endtask

    task driver_src0();
        operand_t operand;
        while (tot_src_queue[0].size()!=0) begin
            operand = tot_src_queue[0].pop_front();
            vpu_src0_port_if.sram_read_transaction(operand.operand);
            $write("Read0 trans finish...%1d\n", tot_src_queue[0].size());
        end
    endtask

    task driver_src1();
        operand_t operand;
        while (tot_src_queue[1].size()!=0) begin
            operand = tot_src_queue[1].pop_front();
            vpu_src1_port_if.sram_read_transaction(operand.operand);
            $write("Read1 trans finish...%1d\n", tot_src_queue[1].size());
        end
    endtask

    task driver_src2();
        operand_t operand;
        while (tot_src_queue[2].size()!=0) begin
            operand = tot_src_queue[2].pop_front();
            vpu_src2_port_if.sram_read_transaction(operand.operand);
            $write("Read2 trans finish...%1d\n", tot_src_queue[2].size());
        end
    endtask

    /*
    task driver_dst0();
        operand_t operand;
        while (tot_dst_queue[0].size() < `MEM_DEPTH) begin
            vpu_dst0_port_if.sram_write_transaction(operand.operand);
            tot_dst_queue[0].push_back(operand);
            $write("Write trans finish...%1d\n", tot_dst_queue[0].size());
        end
    endtask
    */


    task oMonitor();
        operand_t result;
        operand_t answer;
        int cnt = 0;
        while (1) begin
            if( cnt >= REQ_CNT) begin
                $write("<< All Pass!!! %1d : ", cnt);
                $finish;
            end

            vpu_dst0_port_if.sram_write_transaction(result.operand);
            for(int i = 0; i < ELEM_PER_DIM_CNT; i++) begin
                answer.operand[(i*VPU_PKG::OPERAND_WIDTH)+:(VPU_PKG::OPERAND_WIDTH)] = golden_ref_dump[((cnt)*(VPU_PKG::ELEM_PER_DIM_CNT))+i];
            end
            if(result != answer) begin
                $write("<< %5dth request [Error][Incorrect] (OPCODE %1d) : ", cnt, opcode);
                $write("result [0x%08h] | answer : [0x%08h]\n", result.operand, answer.operand);
                @(posedge clk);
                $finish;
            end else begin
                $write("<< %5dth request [Correct] (OPCODE %1d) : ", cnt, opcode);
                $write("result [0x%08h] | answer : [0x%08h]\n", result.operand, answer.operand);
            end
            cnt++;
        end
    endtask
    

    initial begin
        $display("====================Start Simulation!====================");
        
        test_init();
        build_test();
        //fork
            run_test();
        //join
        $display("====================Simulation Done!====================");
        $finish;
    end

endmodule