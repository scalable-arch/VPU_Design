`include "VPU_PKG.svh"

module VPU_LANE
#(

)
(
    input   wire                                    clk,
    input   wire                                    rst_n,

    input   wire                                    start_i,
    VPU_PKG::vpu_exec_req_t                         op_func_i,
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
    
    wire     [OPERAND_WIDTH-1:0]            fp_add_sub_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_mul_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_div_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_max_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_avg_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_sqrt_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_exp_dout;
    wire     [OPERAND_WIDTH-1:0]            fp_recip_dout;
    
    wire                                    fp_add_sub_done;
    wire                                    fp_mul_done;
    wire                                    fp_div_done;
    wire                                    fp_max_done;
    wire                                    fp_avg_done;
    wire                                    fp_sqrt_done;
    wire                                    fp_exp_done;
    wire                                    fp_recip_done;
    
    always_comb begin
        if((op_func_i.fp_req.fp_add_r) || (op_func_i.fp_req.fp_sub_r)) begin
            dout                            = fp_add_sub_dout;
            done                            = fp_add_sub_done;
        end
        else if((op_func_i.fp_req.fp_mul_r)) begin
            dout                            = fp_mul_dout;
            done                            = fp_mul_done;
        end
        else if((op_func_i.fp_req.fp_div_r)) begin
            dout                            = fp_div_dout;
            done                            = fp_div_done;
        end
        else if((op_func_i.fp_req.fp_max_r)) begin
            dout                            = fp_max_dout;
            done                            = fp_max_done;
        end
        else if((op_func_i.fp_req.fp_avg_r)) begin
            dout                            = fp_avg_dout;
            done                            = fp_avg_done;
        end
        else if((op_func_i.fp_req.fp_sqrt_r)) begin
            dout                            = fp_sqrt_dout;
            done                            = fp_sqrt_done;
        end 
        else if((op_func_i.fp_req.fp_exp_r)) begin
            dout                            = fp_exp_dout;
            done                            = fp_exp_done;
        end
        else if((op_func_i.fp_req.fp_recip_r)) begin
            dout                            = fp_recip_dout;
            done                            = fp_recip_done;
        end
        else begin
            dout                            = {OPERAND_WIDTH{1'b0}};
            done                            = 1'b0;
        end
    end

    //----------------------------------------------
    // FP_ADD/SUB
    //----------------------------------------------
    VPU_FP_ADD_SUB # (
    ) fp_add_sub (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .start_i                            (start_i & (op_func_i.fp_req.fp_add_r | op_func_i.fp_req.fp_sub_r)),
        .op_valid                           (operand_valid_i),
        .sub_n                              (!op_func_i.fp_req.fp_sub_r),
        //.en                                 (op_func_i.fp_req.fp_add_r | op_func_i.fp_req.fp_sub_r),
        .result_o                           (fp_add_sub_dout),
        .done_o                             (fp_add_sub_done)
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
        .start_i                            (start_i & op_func_i.fp_req.fp_mul_r),
        //.en                                 (op_func_i.fp_req.fp_mul_r),
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
        .start_i                            (start_i & op_func_i.fp_req.fp_div_r),
        //.en                                 (op_func_i.fp_req.fp_div_r),
        .result_o                           (fp_div_dout),
        .done_o                             (fp_div_done)
    );

    //----------------------------------------------
    // FP_MAX
    //----------------------------------------------
    VPU_FP_MAX # (
    ) fp_max (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .start_i                            (start_i & op_func_i.fp_req.fp_max_r),
        .op_valid                           (operand_valid_i),

        //.en                                 (op_func_i.fp_req.fp_max_r),
        .result_o                           (fp_max_dout),
        .done_o                             (fp_max_done)
    );

    //----------------------------------------------
    // FP_AVG
    //----------------------------------------------
    VPU_FP_AVG # (
    ) fp_avg (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .start_i                            (start_i & op_func_i.fp_req.fp_avg_r),
        .op_valid                           (operand_valid_i),

        //.en                                 (op_func_i.fp_req.fp_max_r),
        .result_o                           (fp_avg_dout),
        .done_o                             (fp_avg_done)
    );

    //----------------------------------------------
    // FP_SQRT
    //----------------------------------------------
    VPU_FP_SQRT # (
    ) fp_sqrt (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .start_i                            (start_i & op_func_i.fp_req.fp_sqrt_r),
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
        .start_i                            (start_i & op_func_i.fp_req.fp_exp_r),
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
        .start_i                            (start_i & op_func_i.fp_req.fp_recip_r),
        .result_o                           (fp_recip_dout),
        .done_o                             (fp_recip_done)
    );
    
    assign  dout_o                          = dout;
    assign  done_o                          = done;
endmodule
