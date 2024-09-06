`include "/home/sg05060/generic_npu/src/VPU/RTL/Header/VPU_PKG.svh"

module VPU_LANE
#(

)
(
    input   wire                                    clk,
    input   wire                                    rst_n,

    input   wire                                    start_i,
    input   VPU_PKG::vpu_exec_req_t                 op_func_i,
    input   wire    [VPU_PKG::MAX_DELAY_LG2-1:0]    delay_i,
    input   wire    [VPU_PKG::OPERAND_WIDTH-1:0]    operand_i[VPU_PKG::SRC_OPERAND_CNT],
    input   wire    [VPU_PKG::SRC_OPERAND_CNT-1:0]  operand_valid_i,

    output  wire    [VPU_PKG::OPERAND_WIDTH-1:0]    dout_o
);
    import VPU_PKG::*;

    // DOUT
    logic    [OPERAND_WIDTH-1:0]            dout;    
    
    logic    [OPERAND_WIDTH-1:0]            ui_add_sub_dout;
    logic    [OPERAND_WIDTH-1:0]            ui_mul_dout;
    logic    [OPERAND_WIDTH-1:0]            ui_div_dout;
    logic    [OPERAND_WIDTH-1:0]            ui_max_dout;
    logic    [OPERAND_WIDTH-1:0]            ui_avg_dout;

    logic    [OPERAND_WIDTH-1:0]            si_add_sub_dout;
    logic    [OPERAND_WIDTH-1:0]            si_mul_dout;
    logic    [OPERAND_WIDTH-1:0]            si_div_dout;
    logic    [OPERAND_WIDTH-1:0]            si_max_dout;
    logic    [OPERAND_WIDTH-1:0]            si_avg_dout;

    logic    [OPERAND_WIDTH-1:0]            fp_add_sub_dout;
    logic    [OPERAND_WIDTH-1:0]            fp_mul_dout;
    logic    [OPERAND_WIDTH-1:0]            fp_div_dout;
    logic    [OPERAND_WIDTH-1:0]            fp_max_dout;

    always_comb begin
        if((op_func_i.ui_req.ui_add_r) || (op_func_i.ui_req.ui_sub_r)) begin
            dout                            = ui_add_sub_dout;
        end
        else if((op_func_i.ui_req.ui_mul_r)) begin
            dout                            = ui_mul_dout;
        end
        else if((op_func_i.ui_req.ui_div_r)) begin
            dout                            = ui_div_dout;
        end
        else if((op_func_i.ui_req.ui_max_r)) begin
            dout                            = ui_max_dout;
        end
        else if((op_func_i.ui_req.ui_avg_r)) begin
            dout                            = ui_avg_dout;
        end

        else if((op_func_i.si_req.si_add_r) || (op_func_i.si_req.si_sub_r)) begin
            dout                            = si_add_sub_dout;
        end
        else if((op_func_i.si_req.si_mul_r)) begin
            dout                            = si_mul_dout;
        end
        else if((op_func_i.si_req.si_div_r)) begin
            dout                            = si_div_dout;
        end
        else if((op_func_i.si_req.si_max_r)) begin
            dout                            = si_max_dout;
        end
        else if((op_func_i.si_req.si_avg_r)) begin
            dout                            = si_avg_dout;
        end

        else if((op_func_i.fp_req.fp_add_r) || (op_func_i.fp_req.fp_sub_r)) begin
            dout                            = fp_add_sub_dout;
        end
        else if((op_func_i.fp_req.fp_mul_r)) begin
            dout                            = fp_mul_dout;
        end
        else if((op_func_i.fp_req.fp_div_r)) begin
            dout                            = fp_div_dout;
        end
        else if((op_func_i.fp_req.fp_max_r)) begin
            dout                            = fp_max_dout;
        end 
        else begin
            dout                            = {OPERAND_WIDTH{1'b0}};
        end
    end

    //----------------------------------------------
    // UI_ADD/SUB
    //----------------------------------------------
    VPU_ALU_UI_ADD_SUB # (
    ) ui_add_sub (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .op_valid                           (operand_valid_i),
        .sub_n                              (!op_func_i.ui_req.ui_sub_r),
        .en                                 (op_func_i.ui_req.ui_add_r | op_func_i.ui_req.ui_sub_r),
        .result_o                           (ui_add_sub_dout)
    );

    //----------------------------------------------
    // UI_MUL
    //----------------------------------------------
    VPU_ALU_UI_MUL # (
    ) ui_mul (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .en                                 (op_func_i.ui_req.ui_mul_r),
        .result_o                           (ui_mul_dout)
    );

    //----------------------------------------------
    // UI_DIV
    //----------------------------------------------
    VPU_ALU_UI_DIV # (
    ) ui_div (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .en                                 (op_func_i.ui_req.ui_div_r),
        .result_o                           (ui_div_dout)
    );

    //----------------------------------------------
    // UI_MAX
    //----------------------------------------------
    VPU_ALU_UI_MAX # (
    ) ui_max (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .op_valid                           (operand_valid_i),
        .en                                 (op_func_i.ui_req.ui_max_r),
        .result_o                           (ui_max_dout)
    );

    //----------------------------------------------
    // UI_AVG
    //----------------------------------------------
    VPU_ALU_UI_AVG # (
    ) ui_avg (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .op_valid                           (operand_valid_i),
        .en                                 (op_func_i.ui_req.ui_avg_r),
        .result_o                           (ui_avg_dout)
    );


    //----------------------------------------------
    // SI_ADD/SUB
    //----------------------------------------------
    VPU_ALU_SI_ADD_SUB # (
    ) si_add_sub (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .op_valid                           (operand_valid_i),
        .sub_n                              (!op_func_i.si_req.si_sub_r),
        .en                                 (op_func_i.si_req.si_add_r | op_func_i.si_req.si_sub_r),
        .result_o                           (si_add_sub_dout)
    );

    //----------------------------------------------
    // SI_MUL
    //----------------------------------------------
    VPU_ALU_SI_MUL # (
    ) si_mul (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .en                                 (op_func_i.si_req.si_mul_r),
        .result_o                           (si_mul_dout)
    );

    //----------------------------------------------
    // SI_DIV
    //----------------------------------------------
    VPU_ALU_SI_DIV # (
    ) si_div (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .en                                 (op_func_i.si_req.si_div_r),
        .result_o                           (si_div_dout)
    );

    //----------------------------------------------
    // SI_MAX
    //----------------------------------------------
    VPU_ALU_SI_MAX # (
    ) si_max (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .op_valid                           (operand_valid_i),
        .en                                 (op_func_i.si_req.si_max_r),
        .result_o                           (si_max_dout)
    );

    //----------------------------------------------
    // SI_AVG
    //----------------------------------------------
    VPU_ALU_SI_AVG # (
    ) si_avg (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .op_valid                           (operand_valid_i),
        .en                                 (op_func_i.si_req.si_avg_r),
        .result_o                           (si_avg_dout)
    );



    //----------------------------------------------
    // FP_ADD/SUB
    //----------------------------------------------
    VPU_FP_ADD_SUB # (
    ) fp_add_sub (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .op_valid                           (operand_valid_i),
        .sub_n                              (!op_func_i.fp_req.fp_sub_r),
        .en                                 (op_func_i.fp_req.fp_add_r | op_func_i.fp_req.fp_sub_r),
        .result_o                           (fp_add_sub_dout)
    );

    //----------------------------------------------
    // FP_MUL
    //----------------------------------------------
    VPU_FP_MUL # (
    ) fp_mul (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .en                                 (op_func_i.fp_req.fp_mul_r),
        .result_o                           (fp_mul_dout)
    );

    //----------------------------------------------
    // FP_DIV
    //----------------------------------------------
    //VPU_ALU_FP_DIV # (
    //) fp_div (
    //    .clk                                (clk),
    //    .rst_n                              (rst_n),
    //    .op_0                               (operand_i[0]),
    //    .op_1                               (operand_i[1]),
    //    .en                                 (op_func_i.fp_req.fp_div_r),
    //    .result_o                           (fp_div_dout)
    //);

    //----------------------------------------------
    // FP_MUL
    //----------------------------------------------
    VPU_FP_MAX # (
    ) fp_max (
        //.clk                                (clk),
        //.rst_n                              (rst_n),
        .op_0                               (operand_i[0]),
        .op_1                               (operand_i[1]),
        .op_2                               (operand_i[2]),
        .op_valid                           (operand_valid_i),
        .en                                 (op_func_i.fp_req.fp_max_r),
        .result_o                           (fp_max_dout)
    );


    assign  dout_o                          = dout;

endmodule
