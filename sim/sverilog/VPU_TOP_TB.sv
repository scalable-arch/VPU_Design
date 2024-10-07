`include "VPU_PKG.svh"
`define TIMEOUT_DELAY   100000000
`define MEM_DEPTH 100
`define RANDOM_SEED     12123344

import "DPI-C" context function string get_env_var(input string var_name);

module VPU_TOP_TB ();

    import VPU_PKG::*;
    reg                     clk;
    reg                     rst_n;
    
    localparam              REQ_CNT = `MEM_DEPTH;
    string                  testvector_path;
    string                  sub_path;
    string                  path;
    typedef struct  {
        bit [VPU_PKG::DIM_SIZE-1:0] operand; 
    } operand_t;

    // Input Argument
    int                             opcode_value;
    string                          test_vector_f;
    string                          golden_ref_f;

    bit                             done;
    int                             cnt = 0;

    // Data Structure
    VPU_PKG::vpu_h2d_req_opcode_t   opcode_queue[$];
    VPU_PKG::vpu_h2d_req_opcode_t   c_opcode;

    VPU_PKG::vpu_h2d_req_instr_t    instr_queue[$];
    typedef operand_t               src_queue[$];
    typedef operand_t               dst_queue[$];
    src_queue                       tot_src_queue[VPU_PKG::SRAM_R_PORT_CNT];
    dst_queue                       tot_dst_queue[VPU_PKG::SRAM_W_PORT_CNT];

    reg [VPU_PKG::OPERAND_WIDTH-1:0] mem_dump[VPU_PKG::ELEM_PER_DIM_CNT * VPU_PKG::SRAM_R_PORT_CNT * `MEM_DEPTH];
    reg [VPU_PKG::OPERAND_WIDTH-1:0] mem_dump_2[VPU_PKG::ELEM_PER_DIM_CNT * VPU_PKG::SRAM_R_PORT_CNT * `MEM_DEPTH];
    reg [VPU_PKG::OPERAND_WIDTH-1:0] golden_ref_dump[VPU_PKG::ELEM_PER_DIM_CNT * REQ_CNT];


    // timeout
	initial begin
		#`TIMEOUT_DELAY $display("Timeout!");
		$finish;
	end
    
    // Search Directory Path 
    initial begin
        testvector_path = get_env_var("TB_TESTVECTOR");
        $display("TESTVECTOR : %s", testvector_path);
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

        sub_path = "/bf16_numbers.txt";
        $display("Loading Data[%s]...",{testvector_path,sub_path});
        $readmemh({testvector_path,sub_path},mem_dump);
        
        sub_path = "/bf16_numbers_only_positive.txt";
        $display("Loading Data2[%s]...",{testvector_path,sub_path});
        $readmemh({testvector_path,sub_path},mem_dump_2);

        fill_opcode();
        @(posedge rst_n); 
        repeat (10) @(posedge clk);
    endtask
    
    task fill_opcode();
        VPU_PKG::vpu_h2d_req_opcode_t   opcode;
        for(int i = 1; i <= VPU_PKG::INSTR_NUM; i++) begin
            opcode = vpu_h2d_req_opcode_t'(i & {8{1'b1}});
            opcode_queue.push_back(opcode);
        end
    endtask

    task gen_instr(VPU_PKG::vpu_h2d_req_opcode_t _opcode);
        VPU_PKG::vpu_h2d_req_instr_t instr;
        for(int i = 0; i < REQ_CNT; i++) begin
            instr.opcode            = _opcode;
            instr.src2              = $random & {VPU_PKG::OPERAND_ADDR_WIDTH{1'b1}};
            instr.src1              = $random & {VPU_PKG::OPERAND_ADDR_WIDTH{1'b1}};
            instr.src0              = $random & {VPU_PKG::OPERAND_ADDR_WIDTH{1'b1}};
            instr.dst0              = $random & {VPU_PKG::OPERAND_ADDR_WIDTH{1'b1}};

            instr_queue.push_back(instr);
        end
    endtask

    task fill_src_operand_queue(VPU_PKG::vpu_h2d_req_opcode_t _opcode);
        operand_t operand;
        for(int i = 0; i < `MEM_DEPTH; i++) begin
            for(int j = 0; j < SRAM_R_PORT_CNT; j++) begin
                for(int k = 0; k < ELEM_PER_DIM_CNT; k++) begin
                    if((_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FSQRT) || (_opcode ==VPU_PKG::VPU_H2D_REQ_OPCODE_FRECIP)) begin
                        operand.operand[(k*VPU_PKG::OPERAND_WIDTH)+:VPU_PKG::OPERAND_WIDTH] = mem_dump_2[((i*VPU_PKG::ELEM_PER_DIM_CNT*VPU_PKG::SRAM_R_PORT_CNT)+(j)*(VPU_PKG::ELEM_PER_DIM_CNT))+k];
                    end else begin
                        operand.operand[(k*VPU_PKG::OPERAND_WIDTH)+:VPU_PKG::OPERAND_WIDTH] = mem_dump[((i*VPU_PKG::ELEM_PER_DIM_CNT*VPU_PKG::SRAM_R_PORT_CNT)+(j)*(VPU_PKG::ELEM_PER_DIM_CNT))+k];
                    end
                end
                tot_src_queue[j].push_back(operand);
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
    
    task clear_src_operand_queue();
        for(int i = 0; i < SRAM_R_PORT_CNT; i++) begin
            tot_src_queue[i].delete();
        end 
        repeat (3) @(posedge clk);
    endtask
    
    task fill_golden_ref_mem(VPU_PKG::vpu_h2d_req_opcode_t _opcode);
        if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FADD) begin
            sub_path = "/add_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FSUB) begin
            sub_path = "/sub_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FMUL) begin
            sub_path = "/mul_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FDIV) begin
            sub_path = "/div_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FADD3) begin
            sub_path = "/add3_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FSUM) begin
            sub_path = "/redsum_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FMAX) begin
            sub_path = "/redmax_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FMAX2) begin
            sub_path = "/max_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FMAX3) begin
            sub_path = "/max3_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FAVG2) begin
            sub_path = "/avg_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FAVG3) begin
            sub_path = "/avg3_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FEXP) begin
            sub_path = "/exp_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FSQRT) begin
            sub_path = "/sqrt_out.txt";
        end else if(_opcode == VPU_PKG::VPU_H2D_REQ_OPCODE_FRECIP) begin
            sub_path = "/reci_out.txt";
        end else begin
            sub_path = "";
        end
        $readmemh({testvector_path,sub_path},golden_ref_dump);
        $display("Loading GL Data[%s]...",{testvector_path,sub_path});
    endtask

    task build_test(VPU_PKG::vpu_h2d_req_opcode_t _opcode);
        clear_src_operand_queue();
        fill_src_operand_queue(_opcode);
        clear_dst_operand_queue();
        fill_golden_ref_mem(_opcode);
        gen_instr(_opcode);
    endtask

    task run_test();
        done = 1'b0;
        fork: fork_1
            driver_req();
            driver_src0();
            driver_src1();
            driver_src2();
            oMonitor();
        join_any: fork_1
        wait(done);
        @(posedge clk);
        disable fork_1;
    endtask

    task run();
        while (opcode_queue.size()!=0) begin
            c_opcode = opcode_queue.pop_front();
            build_test(c_opcode);
            //@(posedge clk);
            run_test();
            //@(posedge clk);
        end
    endtask
    
    task driver_req();
        VPU_PKG::vpu_h2d_req_instr_t instr;
        while (instr_queue.size()!=0) begin
            instr = instr_queue.pop_front();	// pop a request from the queue
            vpu_req_if.gen_request(instr);	    // drive to DUT
        end
        
    endtask

    task driver_src0();
        operand_t operand;
        while (tot_src_queue[0].size()!=0) begin
            operand = tot_src_queue[0].pop_front();
            vpu_src0_port_if.sram_read_transaction(operand.operand);
        end
    endtask

    task driver_src1();
        operand_t operand;
        while (tot_src_queue[1].size()!=0) begin
            operand = tot_src_queue[1].pop_front();
            vpu_src1_port_if.sram_read_transaction(operand.operand);
        end
    endtask

    task driver_src2();
        operand_t operand;
        while (tot_src_queue[2].size()!=0) begin
            operand = tot_src_queue[2].pop_front();
            vpu_src2_port_if.sram_read_transaction(operand.operand);
        end
    endtask

    task oMonitor();
        operand_t result;
        operand_t answer;
        cnt = 0;
        while (cnt < REQ_CNT) begin
            vpu_dst0_port_if.sram_write_transaction(result.operand);
            for(int i = 0; i < ELEM_PER_DIM_CNT; i++) begin
                answer.operand[(i*VPU_PKG::OPERAND_WIDTH)+:(VPU_PKG::OPERAND_WIDTH)] = golden_ref_dump[((cnt)*(VPU_PKG::ELEM_PER_DIM_CNT))+i];
            end
            if(result != answer) begin
                $write("<< %5dth request [Error][Incorrect] (OPCODE %1d) : ", cnt, c_opcode);
                $write("result [0x%08h] | answer : [0x%08h]\n", result.operand, answer.operand);
                @(posedge clk);
                $finish;
            end else begin
                $write("<< %5dth request [Correct] (OPCODE %1d) : ", cnt, c_opcode);
                $write("result [0x%08h] | answer : [0x%08h]\n", result.operand, answer.operand);
            end
            cnt++;
        end
        @(posedge clk);
        if(cnt == REQ_CNT) begin
            $write("=============[OPCODE:%08h]All Pass=============\n", c_opcode);
        end else begin
            $write("[ERROR]][OPCODE:%08h]Fail, Missing Operand Check\n", c_opcode);
        end
        done = 1'b1;
    endtask
    

    initial begin
        $display("====================Start Simulation!====================");
        test_init();
        run();
        $display("====================Simulation Done!====================");
        $finish;
    end

endmodule