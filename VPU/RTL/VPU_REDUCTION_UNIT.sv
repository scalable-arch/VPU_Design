`include "/home/sg05060/generic_npu/src/VPU/RTL/Header/VPU_PKG.svh"

module VPU_REDUCTION_UNIT
#(

)
(
    input   wire                                    clk,
    input   wire                                    rst_n,

    input   wire                                    start_i,
    input   VPU_PKG::vpu_exec_req_t                 op_func_i,
    input   wire    [VPU_PKG::MAX_DELAY_LG2-1:0]    delay_i,                  

    input   wire    [VPU_PKG::DWIDTH_PER_EXEC-1:0]  operand_i,

    output  wire    [VPU_PKG::DWIDTH_PER_EXEC-1:0]  dout_o,
    output  wire                                    done_o
);
    import VPU_PKG::*;
    localparam  ELEM_CNT_PER_EXEC                   = ELEM_PER_DIM_CNT / EXEC_CNT;
    localparam  HEIGHT                              = $clog2(ELEM_CNT_PER_EXEC);
    
    wire    [OPERAND_WIDTH-1:0]                     ui_sum_itmd_res[ELEM_CNT_PER_EXEC-1];
    wire    [OPERAND_WIDTH-1:0]                     ui_max_itmd_res[ELEM_CNT_PER_EXEC-1];
    wire    [OPERAND_WIDTH-1:0]                     si_sum_itmd_res[ELEM_CNT_PER_EXEC-1];
    wire    [OPERAND_WIDTH-1:0]                     si_max_itmd_res[ELEM_CNT_PER_EXEC-1];
    wire    [OPERAND_WIDTH-1:0]                     fp_sum_itmd_res[ELEM_CNT_PER_EXEC-1];
    wire    [OPERAND_WIDTH-1:0]                     fp_max_itmd_res[ELEM_CNT_PER_EXEC-1];
    logic   [OPERAND_WIDTH-1:0]                     itmd_dout;

    wire    [OPERAND_WIDTH-1:0]                     ui_sum_res;
    wire    [OPERAND_WIDTH-1:0]                     ui_max_res;
    wire    [OPERAND_WIDTH-1:0]                     si_sum_res;
    wire    [OPERAND_WIDTH-1:0]                     si_max_res;
    wire    [OPERAND_WIDTH-1:0]                     fp_sum_res;
    wire    [OPERAND_WIDTH-1:0]                     fp_max_res;

    logic   [OPERAND_WIDTH-1:0]                     dout;
    wire                                            done;
    logic   [OPERAND_WIDTH-1:0]                     buff;
    logic   [EXEC_CNT_LG2-1:0]                      cnt, cnt_n;
    logic   [EXEC_CNT_LG2-1:0]                      stage, stage_n;
    logic   [MAX_DELAY_LG2-1:0]                     delay;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            stage                                   <= {EXEC_CNT_LG2{1'b0}};
            buff                                    <= {OPERAND_WIDTH{1'b0}};
        end else begin
            stage                                   <= stage_n;
            if(done && (stage == 'd0)) begin
                buff                                <= itmd_dout;
            end
        end
    end

    always_comb begin
        stage_n                                     = stage;
        if(done) begin
            if(stage == EXEC_CNT-1) begin
                stage_n                             = {EXEC_CNT_LG2{1'b0}};
            end else begin
                stage_n                             = stage + 'd1;
            end
        end
    end
    
    always_comb begin
        delay                                       = delay_i;
        if(stage_n == EXEC_CNT-1) begin
            delay                                   = delay_i + op_func_i.red_req.sub_delay;
        end
    end

    VPU_CNTR # (
        .MAX_DELAY_LG2                          (MAX_DELAY_LG2)
    ) VPU_CNTR (
        .clk                                    (clk),
        .rst_n                                  (rst_n),
        .count                                  (delay),
        .start_i                                (start_i),
        .done_o                                 (done)
    );

    genvar j,i;
    generate
        for(j=0; j < $clog2(ELEM_CNT_PER_EXEC); j=j+1) begin
            if(j==0) begin // First-Level Reduction
                for(i = 0; i < ELEM_CNT_PER_EXEC / 2; i = i + 1) begin
                    //----------------------------------------------
                    // UI_SUM
                    //----------------------------------------------
                    VPU_ALU_UI_ADD_SUB # (
                    ) ui_add_sub (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (operand_i[OPERAND_WIDTH*(i*2) +: OPERAND_WIDTH]),
                        .op_1                       (operand_i[OPERAND_WIDTH*((i*2)+1) +: OPERAND_WIDTH]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .sub_n                      (1'b1),
                        .en                         ((op_func_i.red_req.ui_sum_r)),
                        .result_o                   (ui_sum_itmd_res[i])
                    );

                    //----------------------------------------------
                    // UI_MAX
                    //----------------------------------------------
                    VPU_ALU_UI_MAX # (
                    ) ui_max (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (operand_i[OPERAND_WIDTH*(i*2) +: OPERAND_WIDTH]),
                        .op_1                       (operand_i[OPERAND_WIDTH*((i*2)+1) +: OPERAND_WIDTH]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .en                         ((op_func_i.red_req.ui_max_r)),
                        .result_o                   (ui_max_itmd_res[i])
                    );

                    //----------------------------------------------
                    // SI_SUM
                    //----------------------------------------------
                    VPU_ALU_SI_ADD_SUB # (
                    ) si_add_sub (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (operand_i[OPERAND_WIDTH*(i*2) +: OPERAND_WIDTH]),
                        .op_1                       (operand_i[OPERAND_WIDTH*((i*2)+1) +: OPERAND_WIDTH]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .sub_n                      (1'b1),
                        .en                         ((op_func_i.red_req.si_sum_r)),
                        .result_o                   (si_sum_itmd_res[i])
                    );

                    //----------------------------------------------
                    // SI_MAX
                    //----------------------------------------------
                    VPU_ALU_SI_MAX # (
                    ) si_max (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (operand_i[OPERAND_WIDTH*(i*2) +: OPERAND_WIDTH]),
                        .op_1                       (operand_i[OPERAND_WIDTH*((i*2)+1) +: OPERAND_WIDTH]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .en                         ((op_func_i.red_req.si_max_r)),
                        .result_o                   (si_max_itmd_res[i])
                    );

                    //----------------------------------------------
                    // FP_SUM
                    //----------------------------------------------
                    VPU_FP_ADD_SUB # (
                    ) fp_add_sub (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (operand_i[OPERAND_WIDTH*(i*2) +: OPERAND_WIDTH]),
                        .op_1                       (operand_i[OPERAND_WIDTH*((i*2)+1) +: OPERAND_WIDTH]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .sub_n                      (1'b1),
                        .en                         (op_func_i.red_req.fp_sum_r),
                        .result_o                   (fp_sum_itmd_res[i])
                    );    

                    //----------------------------------------------
                    // FP_MAX
                    //----------------------------------------------
                    VPU_FP_MAX # (
                    ) fp_max (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (operand_i[OPERAND_WIDTH*(i*2) +: OPERAND_WIDTH]),
                        .op_1                       (operand_i[OPERAND_WIDTH*((i*2)+1) +: OPERAND_WIDTH]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .en                         (op_func_i.red_req.fp_max_r),
                        .result_o                   (fp_max_itmd_res[i])
                    );
                end
            end
            else begin
                for(i = 0; i < ELEM_CNT_PER_EXEC / (1<<(j+1)); i = i + 1) begin
                    //----------------------------------------------
                    // UI_SUM
                    //----------------------------------------------
                    VPU_ALU_UI_ADD_SUB # (
                    ) ui_add_sub (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (ui_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+0]),
                        .op_1                       (ui_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+1]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .sub_n                      (1'b1),
                        .en                         (1'b1),
                        .result_o                   (ui_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j))+i])
                    );

                    //----------------------------------------------
                    // UI_MAX
                    //----------------------------------------------
                    VPU_ALU_UI_MAX # (
                    ) ui_max (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (ui_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+0]),
                        .op_1                       (ui_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+1]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .en                         (1'b1),
                        .result_o                   (ui_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j))+i])
                    );

                    //----------------------------------------------
                    // SI_SUM
                    //----------------------------------------------
                    VPU_ALU_SI_ADD_SUB # (
                    ) si_add_sub (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (si_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+0]),
                        .op_1                       (si_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+1]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .sub_n                      (1'b1),
                        .en                         (1'b1),
                        .result_o                   (si_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j))+i])
                    );

                    //----------------------------------------------
                    // SI_MAX
                    //----------------------------------------------
                    VPU_ALU_SI_MAX # (
                    ) si_max (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (si_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+0]),
                        .op_1                       (si_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+1]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .en                         (1'b1),
                        .result_o                   (si_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j))+i])
                    );

                    //----------------------------------------------
                    // FP_SUM
                    //----------------------------------------------
                    VPU_FP_ADD_SUB # (
                    ) fp_add_sub (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (fp_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+0]),
                        .op_1                       (fp_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+1]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .sub_n                      (1'b1),
                        .en                         (1'b1),
                        .result_o                   (fp_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j))+i])
                    );

                    //----------------------------------------------
                    // FP_MAX
                    //----------------------------------------------
                    VPU_FP_MAX # (
                    ) fp_max (
                        //.clk                        (clk),
                        //.rst_n                      (rst_n),
                        .op_0                       (fp_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+0]),
                        .op_1                       (fp_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+1]),
                        .op_2                       (),
                        .op_valid                   (3'b011),
                        .en                         (1'b1),
                        .result_o                   (fp_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j))+i])
                    );
                end
            end
        end
    endgenerate

    //----------------------------------------------
    // Leaf Level Reduction
    //----------------------------------------------
    VPU_ALU_UI_ADD_SUB # (
    ) ll_ui_add_sub (
        //.clk                                        (clk),
        //.rst_n                                      (rst_n),
        .op_0                                       (buff),
        .op_1                                       (itmd_dout),
        .op_2                                       (),
        .op_valid                                   (3'b011),
        .sub_n                                      (1'b1),
        .en                                         ((op_func_i.red_req.ui_sum_r)),
        .result_o                                   (ui_sum_res)
    );

    VPU_ALU_UI_MAX # (
    ) ll_ui_max (
        //.clk                                        (clk),
        //.rst_n                                      (rst_n),
        .op_0                                       (buff),
        .op_1                                       (itmd_dout),
        .op_2                                       (),
        .op_valid                                   (3'b011),
        .en                                         (op_func_i.red_req.ui_max_r),
        .result_o                                   (ui_max_res)
    );

    VPU_ALU_SI_ADD_SUB # (
    ) ll_si_add_sub (
        //.clk                                        (clk),
        //.rst_n                                      (rst_n),
        .op_0                                       (buff),
        .op_1                                       (itmd_dout),
        .op_2                                       (),
        .op_valid                                   (3'b011),
        .sub_n                                      (1'b1),
        .en                                         ((op_func_i.red_req.si_sum_r)),
        .result_o                                   (si_sum_res)
    );

    VPU_ALU_SI_MAX # (
    ) ll_si_max (
        //.clk                                        (clk),
        //.rst_n                                      (rst_n),
        .op_0                                       (buff),
        .op_1                                       (itmd_dout),
        .op_2                                       (),
        .op_valid                                   (3'b011),
        .en                                         (op_func_i.red_req.si_max_r),
        .result_o                                   (si_max_res)
    );

    VPU_FP_ADD_SUB # (
    ) ll_fp_add_sub (
        //.clk                                        (clk),
        //.rst_n                                      (rst_n),
        .op_0                                       (buff),
        .op_1                                       (itmd_dout),
        .op_2                                       (),
        .op_valid                                   (3'b011),
        .sub_n                                      (1'b1),
        .en                                         (op_func_i.red_req.fp_sum_r),
        .result_o                                   (fp_sum_res)
    );
    
    VPU_FP_MAX # (
    ) ll_fp_max (
        //.clk                                        (clk),
        //.rst_n                                      (rst_n),
        .op_0                                       (buff),
        .op_1                                       (itmd_dout),
        .op_2                                       (),
        .op_valid                                   (3'b011),
        .en                                         (op_func_i.red_req.fp_max_r),
        .result_o                                   (fp_max_res)
    );


    always_comb begin
        if(op_func_i.red_req.ui_sum_r) begin
            itmd_dout                               = ui_sum_itmd_res[ELEM_CNT_PER_EXEC-2];
            dout                                    = ui_sum_res;
        end
        else if(op_func_i.red_req.ui_max_r) begin
            itmd_dout                               = ui_max_itmd_res[ELEM_CNT_PER_EXEC-2];
            dout                                    = ui_max_res;
        end
        else if(op_func_i.red_req.si_sum_r) begin
            itmd_dout                               = si_sum_itmd_res[ELEM_CNT_PER_EXEC-2];
            dout                                    = si_sum_res;
        end
        else if(op_func_i.red_req.si_max_r) begin
            itmd_dout                               = si_max_itmd_res[ELEM_CNT_PER_EXEC-2];
            dout                                    = si_max_res;
        end
        else if(op_func_i.red_req.fp_sum_r) begin
            itmd_dout                               = fp_sum_itmd_res[ELEM_CNT_PER_EXEC-2];
            dout                                    = fp_sum_res;
        end
        else if(op_func_i.red_req.fp_max_r) begin
            itmd_dout                               = fp_max_itmd_res[ELEM_CNT_PER_EXEC-2];
            dout                                    = fp_max_res;
        end
        else begin
            itmd_dout                               = {OPERAND_WIDTH{1'b0}};
            dout                                    = {OPERAND_WIDTH{1'b0}};
        end
    end

    genvar l;
    generate;
        for(l = 0; l < ELEM_CNT_PER_EXEC; l++) begin
            assign dout_o[(l*OPERAND_WIDTH)+:OPERAND_WIDTH] = dout;
        end
    endgenerate
    assign  done_o                                  = done;
endmodule
