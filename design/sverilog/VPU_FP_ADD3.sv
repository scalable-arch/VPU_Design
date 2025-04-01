`include "VPU_PKG.svh"

module VPU_FP_ADD3
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
    input   [VPU_PKG::SRAM_R_PORT_CNT-1:0]  operand_valid,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o,
    output                                  done_o
);
    import VPU_PKG::*;

    logic                                   cnt, cnt_n;
    logic                                   tvalid;
    logic   [OPERAND_WIDTH-1:0]             a_tdata, b_tdata;
    logic                                   done;

    wire    [OPERAND_WIDTH-1:0]             result_tdata;
    wire                                    result_tvalid;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            cnt                             <= 1'b0;
        end else begin
            cnt                             <= cnt_n;
        end
    end

    always_comb begin
        cnt_n                               = cnt;
        tvalid                              = 1'b0;
        a_tdata                             = {(OPERAND_WIDTH){1'b0}};
        b_tdata                             = {(OPERAND_WIDTH){1'b0}};
        done                                = 1'b0;

        // 1bit counter for two-stage operation
        if(result_tvalid) begin
            cnt_n                           = cnt + 1'd1;
        end

        // tvalid is start-bit of fp_add_sub_operator
        if(start_i) begin
            tvalid                          = 1'b1;
        end else begin
            tvalid                          = result_tvalid & cnt_n;
        end

        if(cnt_n) begin // second_stage
            a_tdata                         = result_tdata;
            b_tdata                         = operand_2;
        end else begin // first_stage
            a_tdata                         = operand_0;
            b_tdata                         = operand_1;
        end

        // done signal is valid only for second_stage
        done                                = result_tvalid & cnt;
    end

    floating_point_add_sub fp_add_sub_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (tvalid),
        .s_axis_a_tdata                     (a_tdata),
        .s_axis_b_tvalid                    (tvalid),
        .s_axis_b_tdata                     (b_tdata),
        .s_axis_operation_tvalid            (tvalid),
        .s_axis_operation_tdata             ('h0),
        .m_axis_result_tvalid               (result_tvalid),
        .m_axis_result_tdata                (result_tdata),
        .m_axis_result_tuser                ()
    );

    // Assignment
    assign  result_o                        = result_tdata;
    assign  done_o                          = done;
endmodule

