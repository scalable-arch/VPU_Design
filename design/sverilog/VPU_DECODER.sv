`include "VPU_PKG.svh"

module VPU_DECODER
#(
    //...
)
(
    input   wire                                clk,
    input   wire                                rst_n,

    VPU_REQ_IF.device                           vpu_req_if,
    
    output  VPU_PKG::vpu_instr_decoded_t        instr_decoded_o,
    output  wire [VPU_PKG::STREAM_ID_WIDTH-1:0] stream_id_o,
    input   wire                                ctrl_ready_i,
    output  wire                                ctrl_valid_o
);
    import VPU_PKG::*;

    vpu_h2d_req_instr_t                         instr_latch, instr_latch_n;
    vpu_instr_decoded_t                         instr_decoded;
    logic   [STREAM_ID_WIDTH-1:0]               stream_id_latch, stream_id_latch_n;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            instr_latch                         <= {$bits(vpu_h2d_req_instr_t){1'b0}};
            stream_id_latch                     <= {STREAM_ID_WIDTH{1'b0}};
        end else begin
            instr_latch                         <= instr_latch_n;
            stream_id_latch                     <= stream_id_latch_n;
        end
    end

    always_comb begin
        instr_latch_n                           = instr_latch;
        stream_id_latch_n                       = stream_id_latch;
        if(vpu_req_if.valid & vpu_req_if.ready) begin
            instr_latch_n                       = vpu_req_if.h2d_req_instr;
            stream_id_latch_n                   = vpu_req_if.stream_id;
        end
    end

    always_comb begin
        instr_decoded                           = {$bits(vpu_instr_decoded_t){1'b0}};
        case(instr_latch.opcode)
            VPU_H2D_REQ_OPCODE_FSUM,
            VPU_H2D_REQ_OPCODE_FMAX, 
            VPU_H2D_REQ_OPCODE_FSQRT,
            VPU_H2D_REQ_OPCODE_FEXP,
            VPU_H2D_REQ_OPCODE_FRECIP: begin
                instr_decoded.rvalid            = 3'b001; 
            end
            VPU_H2D_REQ_OPCODE_FADD3,
            VPU_H2D_REQ_OPCODE_FMAX3,
            VPU_H2D_REQ_OPCODE_FAVG3: begin
                instr_decoded.rvalid            = 3'b111;
            end
            default: begin
                instr_decoded.rvalid            = 3'b011;
            end
        endcase

        // Decoding Operation
        case(instr_latch.opcode)
            //-----------------------------
            // FP Operation
            //-----------------------------
            VPU_H2D_REQ_OPCODE_FADD : begin
                instr_decoded.op_func.fp_req.fp_add2_r  = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FADD3 : begin
                instr_decoded.op_func.fp_req.fp_add3_r  = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FSUB : begin
                instr_decoded.op_func.fp_req.fp_sub_r   = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FMUL : begin
                instr_decoded.op_func.fp_req.fp_mul_r   = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;   
            end
            VPU_H2D_REQ_OPCODE_FDIV : begin
                instr_decoded.op_func.fp_req.fp_div_r   = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FEXP : begin
                instr_decoded.op_func.fp_req.fp_exp_r   = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FSQRT : begin
                instr_decoded.op_func.fp_req.fp_sqrt_r  = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FRECIP : begin
                instr_decoded.op_func.fp_req.fp_recip_r = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FSUM : begin
                instr_decoded.op_func.fp_req.fp_sum_r   = 1'b1;
                //instr_decoded.op_func.red_req   = 'b10;
                instr_decoded.op_func.op_type   = RED;
            end
            VPU_H2D_REQ_OPCODE_FMAX : begin
                instr_decoded.op_func.fp_req.fp_max_r   = 1'b1;
                //instr_decoded.op_func.red_req   = 'b01;
                instr_decoded.op_func.op_type   = RED;
            end
            VPU_H2D_REQ_OPCODE_FMAX2 : begin
                instr_decoded.op_func.fp_req.fp_max2_r  = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FMAX3 : begin
                instr_decoded.op_func.fp_req.fp_max3_r  = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FAVG2 : begin
                instr_decoded.op_func.fp_req.fp_avg2_r  = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FAVG3 : begin
                instr_decoded.op_func.fp_req.fp_avg3_r  = 1'b1;
                //instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            default : begin
                instr_decoded.op_func           = {$bits(vpu_exec_req_t){1'b0}};
            end
        endcase

        instr_decoded.raddr0                    = instr_latch.src0;
        instr_decoded.raddr1                    = instr_latch.src1;
        instr_decoded.raddr2                    = instr_latch.src2;

        instr_decoded.waddr                     = instr_latch.dst0;
    end

    assign  instr_decoded_o                     = instr_decoded;
    assign  stream_id_o                         = stream_id_latch;
    assign  vpu_req_if.ready                    = ctrl_ready_i;
    assign  ctrl_valid_o                        = vpu_req_if.valid;
endmodule