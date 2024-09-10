`include "/home/sg05060/generic_npu/src/VPU/RTL/Header/VPU_PKG.svh"

module VPU_DECODER
#(
    //...
)
(
    input   wire                                clk,
    input   wire                                rst_n,

    VPU_REQ_IF.device                           vpu_req_if,
    
    REQ_IF.src                                  req_if        
);
    import VPU_PKG::*;

    //REQ_IF
    wire                                        ready;
    logic   [SRAM_R_PORT_CNT-1:0]               rvalid, rvalid_n; 
    logic   [MAX_DELAY_LG2-1:0]                 delay, delay_n;
    logic   [DECODE_CYCLE-1:0]                  valid;
    vpu_exec_req_t                              op_func, op_func_n;


    // Operation-Delay Table
    const logic [MAX_DELAY_LG2-1:0] opcode_delay [INSTR_NUM+1] = '{
        'h0, // None(opcode==0)

        // Unsigned Int
        'h2,    //ADD
        'h2,    //SUB
        'h2,    //MUL
        'h2,    //DIV
        'h2,    //ADD3
        'h2,    //SUM
        'h2,    //MAX
        'h2,    //MAX2
        'h2,    //MAX3
        'h2,    //AVG2
        'h2,    //AVG3

        // Signed Int
        'h2,    //ADD
        'h2,    //SUB
        'h2,    //MUL
        'h2,    //DIV
        'h2,    //ADD3
        'h2,    //SUM
        'h2,    //MAX
        'h2,    //MAX2
        'h2,    //MAX3
        'h2,    //AVG2
        'h2,    //AVG3  

        // FP
        'h2,    //ADD
        'h2,    //SUB
        'h2,    //MUL
        'h2,    //DIV
        'h2,    //ADD3
        'h2,    //SUM
        'h2,    //MAX
        'h2,    //MAX2
        'h2,    //MAX3
        'h2,    //AVG2
        'h2,    //AVG3
        'h2     //EXP
    };

    
    //---------------------------------------
    // Decoding Delay
    //---------------------------------------

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            rvalid                              <= 3'b000;
            op_func                             <= {$bits(vpu_exec_req_t){1'b0}};
            delay                               <= {MAX_DELAY_LG2{1'b0}};
        end else begin
            rvalid                              <= rvalid_n;
            op_func                             <= op_func_n;
            delay                               <= delay_n;
        end
    end

    always_comb begin
        rvalid_n                                = rvalid;
        op_func_n                               = op_func;
        delay_n                                 = delay;
        if(vpu_req_if.valid && req_if.ready) begin
            // Decoding Delay
            delay_n                             = opcode_delay[vpu_req_if.h2d_req_instr.opcode];
            // Decoding Source Operand Count
            case(vpu_req_if.h2d_req_instr.opcode)
                VPU_H2D_REQ_OPCODE_UISUM,
                VPU_H2D_REQ_OPCODE_UIMAX,
                VPU_H2D_REQ_OPCODE_ISUM,
                VPU_H2D_REQ_OPCODE_IMAX,
                VPU_H2D_REQ_OPCODE_FSUM,
                VPU_H2D_REQ_OPCODE_FMAX, 
                VPU_H2D_REQ_OPCODE_FEXP: begin
                    rvalid_n                    = 3'b001; 
                end
                VPU_H2D_REQ_OPCODE_UIADD3,
                VPU_H2D_REQ_OPCODE_UIMAX3,
                VPU_H2D_REQ_OPCODE_UIAVG3,
                VPU_H2D_REQ_OPCODE_IADD3,
                VPU_H2D_REQ_OPCODE_IMAX3,
                VPU_H2D_REQ_OPCODE_IAVG3,
                VPU_H2D_REQ_OPCODE_FADD3,
                VPU_H2D_REQ_OPCODE_FMAX3,
                VPU_H2D_REQ_OPCODE_FAVG3: begin
                    rvalid_n                    = 3'b111;
                end
                default: begin
                    rvalid_n                    = 3'b011;
                end
            endcase

            // Decoding Operation
            case(vpu_req_if.h2d_req_instr.opcode)
                //-----------------------------
                // UI Operation
                //-----------------------------
                VPU_H2D_REQ_OPCODE_UIADD,
                VPU_H2D_REQ_OPCODE_UIADD3 : begin
                    op_func_n.ui_req.ui_add_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_UISUB : begin
                    op_func_n.ui_req.ui_sub_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_UIMUL : begin
                    op_func_n.ui_req.ui_mul_r   = 1'b1;    
                end
                VPU_H2D_REQ_OPCODE_UIDIV : begin
                    op_func_n.ui_req.ui_div_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_UISUM : begin
                    op_func_n.red_req.ui_sum_r  = 1'b1;
                    op_func_n.red_req.sub_delay = 'd2;
                    op_func_n.op_type           = RED;
                end
                VPU_H2D_REQ_OPCODE_UIMAX : begin
                    op_func_n.red_req.ui_max_r  = 1'b1;
                    op_func_n.red_req.sub_delay = 'd1;
                    op_func_n.op_type           = RED;
                end
                VPU_H2D_REQ_OPCODE_UIMAX2,
                VPU_H2D_REQ_OPCODE_UIMAX3 : begin
                    op_func_n.ui_req.ui_max_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_UIAVG2,
                VPU_H2D_REQ_OPCODE_UIAVG3 : begin
                    op_func_n.ui_req.ui_avg_r   = 1'b1;
                end

                //-----------------------------
                // SI Operation
                //-----------------------------
                VPU_H2D_REQ_OPCODE_IADD,
                VPU_H2D_REQ_OPCODE_IADD3 : begin
                    op_func_n.si_req.si_add_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_ISUB : begin
                    op_func_n.si_req.si_sub_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_IMUL : begin
                    op_func_n.si_req.si_mul_r   = 1'b1;    
                end
                VPU_H2D_REQ_OPCODE_IDIV : begin
                    op_func_n.si_req.si_div_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_ISUM : begin
                    op_func_n.red_req.si_sum_r  = 1'b1;
                    op_func_n.red_req.sub_delay = 'd2;
                    op_func_n.op_type           = RED;
                end
                VPU_H2D_REQ_OPCODE_IMAX : begin
                    op_func_n.red_req.si_max_r  = 1'b1;
                    op_func_n.red_req.sub_delay = 'd1;
                    op_func_n.op_type           = RED;
                end
                VPU_H2D_REQ_OPCODE_IMAX2,
                VPU_H2D_REQ_OPCODE_IMAX3 : begin
                    op_func_n.si_req.si_max_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_IAVG2,
                VPU_H2D_REQ_OPCODE_IAVG3 : begin
                    op_func_n.si_req.si_avg_r   = 1'b1;
                end

                //-----------------------------
                // FP Operation
                //-----------------------------
                VPU_H2D_REQ_OPCODE_FADD,
                VPU_H2D_REQ_OPCODE_FADD3 : begin
                    op_func_n.fp_req.fp_add_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_FSUB : begin
                    op_func_n.fp_req.fp_sub_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_FMUL : begin
                    op_func_n.fp_req.fp_mul_r   = 1'b1;    
                end
                VPU_H2D_REQ_OPCODE_FDIV : begin
                    op_func_n.fp_req.fp_div_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_FSUM : begin
                    op_func_n.red_req.fp_sum_r  = 1'b1;
                    op_func_n.red_req.sub_delay = 'd2;
                    op_func_n.op_type           = RED;
                end
                VPU_H2D_REQ_OPCODE_FMAX : begin
                    op_func_n.red_req.fp_max_r  = 1'b1;
                    op_func_n.red_req.sub_delay = 'd1;
                    op_func_n.op_type           = RED;
                end
                VPU_H2D_REQ_OPCODE_FMAX2,
                VPU_H2D_REQ_OPCODE_FMAX3 : begin
                    op_func_n.fp_req.fp_max_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_FAVG2,
                VPU_H2D_REQ_OPCODE_FAVG3 : begin
                    op_func_n.fp_req.fp_avg_r   = 1'b1;
                end

                default : begin
                    op_func_n                   = {$bits(vpu_exec_req_t){1'b0}};
                end
            endcase

        end
    end

    //---------------------------------------
    // Decode Cycle
    //---------------------------------------
    wire                                        done;
    VPU_CNTR # (
        .MAX_DELAY_LG2                          (MAX_DELAY_LG2)
    ) VPU_CNTR (
        .clk                                    (clk),
        .rst_n                                  (rst_n),
        .count                                  (DECODE_CYCLE),
        .start_i                                (vpu_req_if.valid && req_if.ready),
        .done_o                                 (done)
    );

    // REQ_IF
    assign  req_if.delay                        = delay;
    assign  req_if.rvalid                       = rvalid;
    genvar k;
    generate
        for (k=0; k < SRAM_R_PORT_CNT; k=k+1) begin : SLICING
            assign req_if.raddr[k]              = get_src_operand(vpu_req_if.h2d_req_instr,k);
        end
    endgenerate

    assign  req_if.waddr                        = vpu_req_if.h2d_req_instr.dst0;
    assign  req_if.valid                        = done;
    assign  req_if.op_func                      = op_func;
    assign  vpu_req_if.ready                    = done;
    assign  req_if.opcode                       = vpu_req_if.h2d_req_instr.opcode;
endmodule