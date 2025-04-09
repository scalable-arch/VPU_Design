`include "VPU_PKG.svh"

module VPU_LANE
#(

)
(
    input   wire                                    clk,
    input   wire                                    rst_n,

    input   wire                                    start_i,
    VPU_PKG::vpu_h2d_req_opcode_t                   opcode_i,
    //input   wire    [VPU_PKG::MAX_DELAY_LG2-1:0]    delay_i,
    input   wire    [VPU_PKG::OPERAND_WIDTH-1:0]    operand_i[VPU_PKG::SRC_OPERAND_CNT],
    input   wire    [VPU_PKG::SRC_OPERAND_CNT-1:0]  operand_valid_i,

    output  wire    [VPU_PKG::OPERAND_WIDTH-1:0]    dout_o,
    output  wire                                    done_o
);
    import VPU_PKG::*;

    // DOUT
    logic    [OPERAND_WIDTH-1:0]            dout; 
    logic                                   done;   
    
    wire     [OPERAND_WIDTH-1:0]            fp_add2_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_add3_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_mul_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_div_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_max2_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_max3_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_avg2_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_avg3_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_sqrt_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_exp_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_recip_dout;
    
    wire                                    fp_add2_done;
    wire                                    fp_add3_done;
    wire                                    fp_mul_done;
    wire                                    fp_div_done;
    wire                                    fp_max2_done;
    wire                                    fp_max3_done;
    wire                                    fp_avg2_done;
    wire                                    fp_avg3_done;
    wire                                    fp_sqrt_done;
    wire                                    fp_exp_done;
    wire                                    fp_recip_done;
    
    always_comb begin
        if(((opcode_i == VPU_H2D_REQ_OPCODE_FADD) || (opcode_i == VPU_H2D_REQ_OPCODE_FSUB))) begin
            dout                            = fp_add2_dout;
            done                            = fp_add2_done;
        end else if((opcode_i == VPU_H2D_REQ_OPCODE_FADD3)) begin
            dout                            = fp_add3_dout;
            done                            = fp_add3_done;
        end
        else if((opcode_i == VPU_H2D_REQ_OPCODE_FMUL)) begin
            dout                            = fp_mul_dout;
            done                            = fp_mul_done;
        end
        else if((opcode_i == VPU_H2D_REQ_OPCODE_FDIV)) begin
            dout                            = fp_div_dout;
            done                            = fp_div_done;
        end
        else if((opcode_i == VPU_H2D_REQ_OPCODE_FMAX2)) begin
            dout                            = fp_max2_dout;
            done                            = fp_max2_done;
        end
        else if((opcode_i == VPU_H2D_REQ_OPCODE_FMAX3)) begin
            dout                            = fp_max3_dout;
            done                            = fp_max3_done;
        end
        else if((opcode_i == VPU_H2D_REQ_OPCODE_FAVG2)) begin
            dout                            = fp_avg2_dout;
            done                            = fp_avg2_done;
        end
        else if((opcode_i == VPU_H2D_REQ_OPCODE_FAVG3)) begin
            dout                            = fp_avg3_dout;
            done                            = fp_avg3_done;
        end
        else if((opcode_i == VPU_H2D_REQ_OPCODE_FSQRT)) begin
            dout                            = fp_sqrt_dout;
            done                            = fp_sqrt_done;
        end 
        else if((opcode_i == VPU_H2D_REQ_OPCODE_FEXP)) begin
            dout                            = fp_exp_dout;
            done                            = fp_exp_done;
        end
        else if((opcode_i == VPU_H2D_REQ_OPCODE_FRECIP)) begin
            dout                            = fp_recip_dout;
            done                            = fp_recip_done;
        end
        else begin
            dout                            = {OPERAND_WIDTH{1'b0}};
            done                            = 1'b0;
        end
    end

    //----------------------------------------------
    // FP_ADD2
    //----------------------------------------------
    VPU_FP_ADD2 # (
    ) fp_add2 (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .operand_0                          (operand_i[0]),
        .operand_1                          (operand_i[1]),
        .start_i                            (start_i & ((opcode_i == VPU_H2D_REQ_OPCODE_FADD) || (opcode_i == VPU_H2D_REQ_OPCODE_FSUB))),
        .sub                                (opcode_i == VPU_H2D_REQ_OPCODE_FSUB),
        .result_o                           (fp_add2_dout),
        .done_o                             (fp_add2_done)
    );

    //----------------------------------------------
    // FP_ADD3
    //----------------------------------------------
    VPU_FP_ADD3 # (
    ) fp_add3 (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .operand_0                          (operand_i[0]),
        .operand_1                          (operand_i[1]),
        .operand_2                          (operand_i[2]),
        .start_i                            (start_i & (opcode_i == VPU_H2D_REQ_OPCODE_FADD3)),
        .result_o                           (fp_add3_dout),
        .done_o                             (fp_add3_done)
    );

    //----------------------------------------------
    // FP_MUL
    //----------------------------------------------
    VPU_FP_MUL # (
    ) fp_mul (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .start_i                            (start_i & (opcode_i == VPU_H2D_REQ_OPCODE_FMUL)),
        .result_o                           (fp_mul_dout),
        .done_o                             (fp_mul_done)
    );

    //----------------------------------------------
    // FP_DIV
    //----------------------------------------------
    VPU_FP_DIV # (
    ) fp_div (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .start_i                            (start_i & (opcode_i == VPU_H2D_REQ_OPCODE_FDIV)),
        .result_o                           (fp_div_dout),
        .done_o                             (fp_div_done)
    );

    //----------------------------------------------
    // FP_MAX2
    //----------------------------------------------
    VPU_FP_MAX2 # (
    ) fp_max2 (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .operand_0                          (operand_i[0]),
        .operand_1                          (operand_i[1]),
        .start_i                            (start_i & (opcode_i == VPU_H2D_REQ_OPCODE_FMAX2)),
        .result_o                           (fp_max2_dout),
        .done_o                             (fp_max2_done)
    );

    //----------------------------------------------
    // FP_MAX3
    //----------------------------------------------
    VPU_FP_MAX3 # (
    ) fp_max3 (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .operand_0                          (operand_i[0]),
        .operand_1                          (operand_i[1]),
        .operand_2                          (operand_i[2]),
        .start_i                            (start_i & (opcode_i == VPU_H2D_REQ_OPCODE_FMAX3)),
        .result_o                           (fp_max3_dout),
        .done_o                             (fp_max3_done)
    );

    //----------------------------------------------
    // FP_AVG2
    //----------------------------------------------
    VPU_FP_AVG2 # (
    ) fp_avg2 (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .operand_0                          (operand_i[0]),
        .operand_1                          (operand_i[1]),
        .start_i                            (start_i & (opcode_i == VPU_H2D_REQ_OPCODE_FAVG2)),
        .result_o                           (fp_avg2_dout),
        .done_o                             (fp_avg2_done)
    );

    //----------------------------------------------
    // FP_AVG3
    //----------------------------------------------
    VPU_FP_AVG3 # (
    ) fp_avg3 (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .operand_0                          (operand_i[0]),
        .operand_1                          (operand_i[1]),
        .operand_2                          (operand_i[2]),
        .start_i                            (start_i & (opcode_i == VPU_H2D_REQ_OPCODE_FAVG3)),
        .result_o                           (fp_avg3_dout),
        .done_o                             (fp_avg3_done)
    );

    //----------------------------------------------
    // FP_SQRT
    //----------------------------------------------
    VPU_FP_SQRT # (
    ) fp_sqrt (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .start_i                            (start_i & (opcode_i == VPU_H2D_REQ_OPCODE_FSQRT)),
        .result_o                           (fp_sqrt_dout),
        .done_o                             (fp_sqrt_done)
    );

    //----------------------------------------------
    // FP_EXP
    //----------------------------------------------
    VPU_FP_EXP # (
    ) fp_exp (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .start_i                            (start_i & (opcode_i == VPU_H2D_REQ_OPCODE_FEXP)),
        .result_o                           (fp_exp_dout),
        .done_o                             (fp_exp_done)
    );

    //----------------------------------------------
    // FP_RECIP
    //----------------------------------------------
    VPU_FP_RECIP # (
    ) fp_recip (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .start_i                            (start_i & (opcode_i == VPU_H2D_REQ_OPCODE_FRECIP)),
        .result_o                           (fp_recip_dout),
        .done_o                             (fp_recip_done)
    );
    
    assign  dout_o                          = dout;
    assign  done_o                          = done;
endmodule
