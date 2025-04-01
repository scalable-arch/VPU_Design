`include "VPU_PKG.svh"

module VPU_REDUCTION_UNIT
#(

)
(
    input   wire                                    clk,
    input   wire                                    rst_n,

    input   wire                                    start_i,
    input   VPU_PKG::vpu_exec_req_t                 op_func_i,
    //input   wire    [VPU_PKG::MAX_DELAY_LG2-1:0]    delay_i,                  

    input   wire    [VPU_PKG::DWIDTH_PER_EXEC-1:0]  operand_i,

    output  wire    [VPU_PKG::DWIDTH_PER_EXEC-1:0]  dout_o,
    output  wire                                    done_o
);
    import VPU_PKG::*;
    localparam  ELEM_CNT_PER_EXEC                   = ELEM_PER_DIM_CNT / EXEC_CNT;
    localparam  HEIGHT                              = $clog2(ELEM_CNT_PER_EXEC);
    
    wire    [OPERAND_WIDTH-1:0]                     fp_sum_itmd_res[ELEM_CNT_PER_EXEC-1];
    wire    [OPERAND_WIDTH-1:0]                     fp_max_itmd_res[ELEM_CNT_PER_EXEC-1];
    logic   [OPERAND_WIDTH-1:0]                     itmd_dout;

    wire    [OPERAND_WIDTH-1:0]                     fp_sum_res;
    wire    [OPERAND_WIDTH-1:0]                     fp_max_res;

    logic   [OPERAND_WIDTH-1:0]                     dout;
    logic                                           done;

    wire    [ELEM_CNT_PER_EXEC-1:0]                 fp_sum_itmd_done;
    wire    [ELEM_CNT_PER_EXEC-1:0]                 fp_max_itmd_done;
    wire                                            fp_sum_done;
    wire                                            fp_max_done;

    logic   [OPERAND_WIDTH-1:0]                     buff;
    logic   [EXEC_CNT_LG2-1:0]                      cnt, cnt_n;
    logic   [EXEC_CNT_LG2-1:0]                      stage, stage_n;
    logic   [MAX_DELAY_LG2-1:0]                     delay;

    always_comb begin
        if(op_func_i.fp_req.fp_sum_r) begin
            if(stage == 'd0)
                done                                = fp_sum_itmd_done[ELEM_CNT_PER_EXEC-2];
            else    
                done                                = fp_sum_done;
        end else begin
            if(stage == 'd0)
                done                                = fp_max_itmd_done[ELEM_CNT_PER_EXEC-2];
            else 
                done                                = fp_max_done;
        end
    end

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

    genvar j,i;
    generate
        for(j=0; j < $clog2(ELEM_CNT_PER_EXEC); j=j+1) begin
            if(j==0) begin // First-Level Reduction
                for(i = 0; i < ELEM_CNT_PER_EXEC / 2; i = i + 1) begin
                    //----------------------------------------------
                    // FP_SUM
                    //----------------------------------------------
                    VPU_FP_ADD2 # (
                    ) fp_add2 (
                        .clk                        (clk),
                        .rst_n                      (rst_n),
                        .operand_0                  (operand_i[OPERAND_WIDTH*(i*2) +: OPERAND_WIDTH]),
                        .operand_1                  (operand_i[OPERAND_WIDTH*((i*2)+1) +: OPERAND_WIDTH]),
                        .start_i                    (start_i & op_func_i.fp_req.fp_sum_r),
                        .sub                        (1'b0),
                        .result_o                   (fp_sum_itmd_res[i]),
                        .done_o                     (fp_sum_itmd_done[i])
                    );    

                    //----------------------------------------------
                    // FP_MAX
                    //----------------------------------------------
                    VPU_FP_MAX2 # (
                    ) fp_max2 (
                        .clk                        (clk),
                        .rst_n                      (rst_n),
                        .operand_0                  (operand_i[OPERAND_WIDTH*(i*2) +: OPERAND_WIDTH]),
                        .operand_1                  (operand_i[OPERAND_WIDTH*((i*2)+1) +: OPERAND_WIDTH]),
                        .start_i                    (start_i & op_func_i.fp_req.fp_max_r),
                        .result_o                   (fp_max_itmd_res[i]),
                        .done_o                     (fp_max_itmd_done[i])
                    );
                end
            end
            else begin
                for(i = 0; i < ELEM_CNT_PER_EXEC / (1<<(j+1)); i = i + 1) begin
                    //----------------------------------------------
                    // FP_SUM
                    //----------------------------------------------
                    VPU_FP_ADD2 # (
                    ) fp_add2 (
                        .clk                        (clk),
                        .rst_n                      (rst_n),
                        .operand_0                  (fp_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+0]),
                        .operand_1                  (fp_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+1]),
                        .start_i                    (fp_sum_itmd_done[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2]),
                        .sub                        (1'b0),
                        .result_o                   (fp_sum_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j))+i]),
                        .done_o                     (fp_sum_itmd_done[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j))+i])
                    );

                    //----------------------------------------------
                    // FP_MAX
                    //----------------------------------------------
                    VPU_FP_MAX2 # (
                    ) fp_max2 (
                        .clk                        (clk),
                        .rst_n                      (rst_n),
                        .operand_0                  (fp_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+0]),
                        .operand_1                  (fp_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2+1]),
                        .start_i                    (fp_max_itmd_done[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j+1))+i*2]),
                        .result_o                   (fp_max_itmd_res[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j))+i]),
                        .done_o                     (fp_max_itmd_done[ELEM_CNT_PER_EXEC-(1<<(HEIGHT-j))+i])
                    );
                end
            end
        end
    endgenerate

    //----------------------------------------------
    // Leaf Level Reduction
    //----------------------------------------------
    VPU_FP_ADD2 # (
    ) ll_fp_add2 (
        .clk                                        (clk),
        .rst_n                                      (rst_n),
        .operand_0                                  (buff),
        .operand_1                                  (itmd_dout),
        .start_i                                    ((stage == EXEC_CNT-1) && fp_sum_itmd_done[ELEM_CNT_PER_EXEC-2]),
        .sub                                        (1'b0),
        .result_o                                   (fp_sum_res),
        .done_o                                     (fp_sum_done)
    );
    
    VPU_FP_MAX2 # (
    ) ll_fp_max2 (
        .clk                                        (clk),
        .rst_n                                      (rst_n),
        .operand_0                                  (buff),
        .operand_1                                  (itmd_dout),
        .start_i                                    ((stage == EXEC_CNT-1) && fp_max_itmd_done[ELEM_CNT_PER_EXEC-2]),
        .result_o                                   (fp_max_res),
        .done_o                                     (fp_max_done)
    );

    always_comb begin
        if(op_func_i.fp_req.fp_sum_r) begin
            itmd_dout                               = fp_sum_itmd_res[ELEM_CNT_PER_EXEC-2];
            dout                                    = fp_sum_res;
           
        end
        else if(op_func_i.fp_req.fp_max_r) begin
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
