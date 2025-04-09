`include "VPU_PKG.svh"

module VPU_DECODER
#(
    //...
)
(
    input   wire                                clk,
    input   wire                                rst_n,

    VPU_REQ_IF.device                           vpu_req_if,
    
    output  VPU_PKG::vpu_h2d_req_instr_t        instr_latch_o,
    output  wire                                is_sum_o,
    output  wire                                is_reduction_o,
    output  wire [VPU_PKG::SRAM_READ_PORT_CNT-1:0] operand_rvalid_o,
    output  wire [VPU_PKG::STREAM_ID_WIDTH-1:0] stream_id_o,
    input   wire                                ctrl_ready_i,
    output  wire                                ctrl_valid_o
);
    import VPU_PKG::*;

    vpu_h2d_req_instr_t                         instr_latch, instr_latch_n;
    logic                                       is_sum, is_sum_n;
    logic                                       is_reduction, is_reduction_n;
    logic   [STREAM_ID_WIDTH-1:0]               stream_id_latch, stream_id_latch_n;
    logic   [SRAM_READ_PORT_CNT-1:0]            operand_rvalid, operand_rvalid_n;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            instr_latch                         <= {$bits(vpu_h2d_req_instr_t){1'b0}};
            is_sum                              <= 1'b0;
            is_reduction                        <= 1'b0;
            stream_id_latch                     <= {STREAM_ID_WIDTH{1'b0}};
            operand_rvalid                      <= {SRAM_READ_PORT_CNT{1'b0}};
        end else begin
            instr_latch                         <= instr_latch_n;
            is_sum                              <= is_sum_n;
            is_reduction                        <= is_reduction_n;
            stream_id_latch                     <= stream_id_latch_n;
            operand_rvalid                      <= operand_rvalid_n;
        end
    end

    always_comb begin
        instr_latch_n                           = instr_latch;
        stream_id_latch_n                       = stream_id_latch;
        is_sum_n                                = is_sum;
        is_reduction_n                          = is_reduction;
        operand_rvalid_n                        = operand_rvalid;
        if(vpu_req_if.valid & vpu_req_if.ready) begin
            instr_latch_n                       = vpu_req_if.h2d_req_instr;
            stream_id_latch_n                   = vpu_req_if.stream_id;
            is_sum_n                            = (vpu_req_if.h2d_req_instr.opcode == VPU_H2D_REQ_OPCODE_FSUM);
            is_reduction_n                      = (vpu_req_if.h2d_req_instr.opcode == VPU_H2D_REQ_OPCODE_FSUM)
                                                    || (vpu_req_if.h2d_req_instr.opcode == VPU_H2D_REQ_OPCODE_FMAX);
            case(vpu_req_if.h2d_req_instr.opcode)
                VPU_H2D_REQ_OPCODE_FSUM,
                VPU_H2D_REQ_OPCODE_FMAX: begin
                    operand_rvalid_n            = 3'b001; 
                end 
                VPU_H2D_REQ_OPCODE_FSQRT,
                VPU_H2D_REQ_OPCODE_FEXP,
                VPU_H2D_REQ_OPCODE_FRECIP: begin
                    operand_rvalid_n            = 3'b001; 
                end
                VPU_H2D_REQ_OPCODE_FADD3,
                VPU_H2D_REQ_OPCODE_FMAX3,
                VPU_H2D_REQ_OPCODE_FAVG3: begin
                    operand_rvalid_n            = 3'b111;
                end
                default: begin
                    operand_rvalid_n            = 3'b011;
                end
            endcase
        end
    end

    assign  instr_latch_o                       = instr_latch;
    assign  is_sum_o                            = is_sum;
    assign  is_reduction_o                      = is_reduction;
    assign  operand_rvalid_o                    = operand_rvalid;
    assign  stream_id_o                         = stream_id_latch;
    assign  vpu_req_if.ready                    = ctrl_ready_i;
    assign  ctrl_valid_o                        = vpu_req_if.valid;
endmodule