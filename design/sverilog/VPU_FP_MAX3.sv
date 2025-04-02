`include "VPU_PKG.svh"

module VPU_FP_MAX3
#(
    
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From SRC_PORT
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    operand_0,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    operand_1,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    operand_2,
    input                                   start_i,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o,
    output                                  done_o
);
    import VPU_PKG::*;

    logic   [OPERAND_WIDTH-1:0]             operand_latch, operand_latch_n;

    logic  [OPERAND_WIDTH-1:0]              a_tdata, b_tdata;
    logic                                   tvalid;
    logic   [1:0]                           cnt, cnt_n;
    logic                                   done;
    wire    [3:0]                           result_tdata;
    wire                                    result_tvalid;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            operand_latch                   <= {OPERAND_WIDTH{1'b0}};
            cnt                             <= 2'b0;
        end else begin
            cnt                             <= cnt_n;
            operand_latch                   <= operand_latch_n;
        end
    end

    always_comb begin
        cnt_n                               = cnt;
        operand_latch_n                     = operand_latch;
        tvalid                              = 1'b0;
        a_tdata                             = {(OPERAND_WIDTH){1'b0}};
        b_tdata                             = {(OPERAND_WIDTH){1'b0}};
        done                                = 1'b0;

        // 1bit counter for two-stage operation
        if(result_tvalid) begin
            //cnt_n                           = cnt + 1'd1;
            operand_latch_n                 = (result_tdata == 4'b0001) ? operand_0 : operand_1;
        end

        // tvalid is start-bit of fp_max_operator
        if(start_i) begin
            tvalid                          = 1'b1;
            //cnt_n                           = cnt + 1'd1;
        end else if(cnt == 'd1)begin
            tvalid                          = result_tvalid;
        end

        if(cnt == 'd2) begin
            if(result_tvalid) begin
                cnt_n                       = 'd0;
            end
        end else begin
            if(tvalid) begin
                cnt_n                       = cnt + 1'd1;
            end
        end

        if(cnt) begin // second_stage
            a_tdata                         = operand_latch_n;
            b_tdata                         = operand_2;
        end else begin // first_stage
            a_tdata                         = operand_0;
            b_tdata                         = operand_1;
        end

        done                                = result_tvalid & (cnt == 'd2);
    end

    floating_point_cmp fp_max (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (tvalid),
        .s_axis_a_tdata                     (a_tdata),
        .s_axis_b_tvalid                    (tvalid),
        .s_axis_b_tdata                     (b_tdata),
        .m_axis_result_tvalid               (result_tvalid),
        .m_axis_result_tdata                (result_tdata),
        .m_axis_result_tuser                ()
    );

    // Assign
    assign  result_o                        = (result_tdata == 4'b0001) ? operand_latch : operand_2;
    assign  done_o                          = done;
endmodule