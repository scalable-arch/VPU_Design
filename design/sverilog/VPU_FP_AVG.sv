`include "VPU_PKG.svh"

module VPU_FP_AVG
#(
    
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From SRC_PORT
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_0,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_1,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_2,
    input                                   start_i,
    input   [VPU_PKG::SRAM_R_PORT_CNT-1:0]  op_valid,
    
    //From VPU_CONTROLLER
    //input                                   en,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o,
    output                                  done_o
);
    import VPU_PKG::*;
    
   
    wire    [OPERAND_WIDTH-1:0]             result_0_data, result_1_data;
    wire                                    result_0_tvalid, result_1_tvalid;
    logic   [OPERAND_WIDTH-1:0]             result_data;
    logic                                   result_tvalid;
    wire    [OPERAND_WIDTH-1:0]             result;
    wire                                    done;
    logic   [OPERAND_WIDTH-1:0]             quotient;


    logic   [OPERAND_WIDTH-1:0]             op_2_temp;
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            op_2_temp                       <= {OPERAND_WIDTH{1'b0}};
        end else if(start_i & op_valid[SRAM_R_PORT_CNT-1]) begin
            op_2_temp                       <= op_2;
        end
    end


    always_comb begin
        quotient                            = 'b0_10000000_0000000;
        result_data                         = result_0_data;
        result_tvalid                       = result_0_tvalid;
        if(op_valid[SRAM_R_PORT_CNT-1]) begin
            quotient                        = 'b0_10000000_1000000;
            result_data                     = result_1_data;
            result_tvalid                   = result_1_tvalid;
        end
    end
    
    
    
    floating_point_add_sub fp_add_sub_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (start_i),
        .s_axis_a_tdata                     (op_0),
        .s_axis_b_tvalid                    (start_i),
        .s_axis_b_tdata                     (op_1),
        .s_axis_operation_tvalid            (start_i),
        .s_axis_operation_tdata             (8'h00),
        .m_axis_result_tvalid               (result_0_tvalid),
        .m_axis_result_tdata                (result_0_data),
        .m_axis_result_tuser                ()
    );

    floating_point_add_sub fp_add_sub_1 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (result_0_tvalid & (op_valid[SRAM_R_PORT_CNT-1])),
        .s_axis_a_tdata                     (result_0_data),
        .s_axis_b_tvalid                    (result_0_tvalid & (op_valid[SRAM_R_PORT_CNT-1])),
        .s_axis_b_tdata                     (op_2_temp),
        .s_axis_operation_tvalid            (result_0_tvalid & (op_valid[SRAM_R_PORT_CNT-1])),
        .s_axis_operation_tdata             (8'h00),
        .m_axis_result_tvalid               (result_1_tvalid),
        .m_axis_result_tdata                (result_1_data),
        .m_axis_result_tuser                ()
    );
    
    floating_point_div fp_div_0 (
        .aclk                               (clk),
       .s_axis_a_tvalid                     (result_tvalid),
        .s_axis_a_tdata                     (result_data),
        .s_axis_b_tvalid                    (result_tvalid),
        .s_axis_b_tdata                     (quotient),
        .m_axis_result_tvalid               (done),
        .m_axis_result_tdata                (result),
        .m_axis_result_tuser                ()
    );

    // Assign
    assign result_o                         = result;
    assign  done_o                          = done;

endmodule