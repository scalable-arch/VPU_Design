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
    input   wire                                ctrl_ready_i,
    output  wire                                ctrl_valid_o
);
    import VPU_PKG::*;

    logic   [OPERAND_ADDR_WIDTH-1:0]            dst0_addr, dst0_addr_n;
    logic   [OPERAND_ADDR_WIDTH-1:0]            src0_addr, src0_addr_n;
    logic   [OPERAND_ADDR_WIDTH-1:0]            src1_addr, src1_addr_n;
    logic   [OPERAND_ADDR_WIDTH-1:0]            src2_addr, src2_addr_n;

    vpu_h2d_req_instr_t                         instr_latch, instr_latch_n;
    vpu_instr_decoded_t                         instr_decoded;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            instr_latch                         <= {$bits(vpu_h2d_req_instr_t){1'b0}};
        end else begin
            instr_latch                         <= instr_latch_n;
        end
    end

    always_comb begin
        instr_latch_n                           = instr_latch;
        if(vpu_req_if.valid & vpu_req_if.ready) begin
            instr_latch_n                       = vpu_req_if.h2d_req_instr;
        end
    end

    always_comb begin
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
            VPU_H2D_REQ_OPCODE_FADD,
            VPU_H2D_REQ_OPCODE_FADD3 : begin
                instr_decoded.op_func.fp_req    = 'b1000_0000_00;
                instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FSUB : begin
                instr_decoded.op_func.fp_req    = 'b0100_0000_00;
                instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FMUL : begin
                instr_decoded.op_func.fp_req    = 'b0010_0000_00;
                instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;   
            end
            VPU_H2D_REQ_OPCODE_FDIV : begin
                instr_decoded.op_func.fp_req    = 'b0001_0000_00;
                instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FEXP : begin
                instr_decoded.op_func.fp_req    = 'b0000_0100_00;
                instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FSQRT : begin
                instr_decoded.op_func.fp_req    = 'b0000_1000_00;
                instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FRECIP : begin
                instr_decoded.op_func.fp_req    = 'b0000_0010_00;
                instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FSUM : begin
                instr_decoded.op_func.fp_req    = 'b0000_0000_01;
                instr_decoded.op_func.red_req   = 'b10;
                instr_decoded.op_func.op_type   = RED;
            end
            VPU_H2D_REQ_OPCODE_FMAX : begin
                instr_decoded.op_func.fp_req    = 'b0000_0000_01;
                instr_decoded.op_func.red_req   = 'b01;
                instr_decoded.op_func.op_type   = RED;
            end
            VPU_H2D_REQ_OPCODE_FMAX2,
            VPU_H2D_REQ_OPCODE_FMAX3 : begin
                instr_decoded.op_func.fp_req    = 'b0000_0001_00;
                instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end
            VPU_H2D_REQ_OPCODE_FAVG2,
            VPU_H2D_REQ_OPCODE_FAVG3 : begin
                instr_decoded.op_func.fp_req    = 'b0000_0000_10;
                instr_decoded.op_func.red_req   = 'b00;
                instr_decoded.op_func.op_type   = EXEC;
            end

            default : begin
                instr_decoded.op_func           = {$bits(vpu_exec_req_t){1'b0}};
            end
        endcase

        // for(int i = 0; i < SRC_OPERAND_CNT; i = i + 1) begin
        //     instr_decoded.raddr[i]              = get_src_operand(instr_latch,i);
        // end
        instr_decoded.raddr0                    = instr_latch.src0;
        instr_decoded.raddr1                    = instr_latch.src1;
        instr_decoded.raddr2                    = instr_latch.src2;
        instr_decoded.waddr                     = instr_latch.dst0;
    end

    assign  instr_decoded_o                     = instr_decoded;
    assign  vpu_req_if.ready                    = ctrl_ready_i;
    assign  ctrl_valid_o                        = vpu_req_if.valid;
endmodule