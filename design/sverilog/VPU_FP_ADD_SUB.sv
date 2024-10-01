`include "VPU_PKG.svh"

module VPU_FP_ADD_SUB
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
    input                                   sub_n,
    
    //From VPU_CONTROLLER
    //input                                   en,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o,
    output                                  done_o
);
    import VPU_PKG::*;
    
   
    wire   [OPERAND_WIDTH-1:0]              result_0_data, result_1_data;

  
    wire                                    result_0_tvalid, result_1_tvalid;
    logic   [OPERAND_WIDTH-1:0]             result;
    logic                                   done;
    logic   [7:0]                           operation;
    
    
    
    floating_point_add_sub fp_add_sub_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (start_i),
        .s_axis_a_tdata                     (op_0),
        .s_axis_b_tvalid                    (start_i),
        .s_axis_b_tdata                     (op_1),
        .s_axis_operation_tvalid            (start_i),
        .s_axis_operation_tdata             (operation),
        .m_axis_result_tvalid               (result_0_tvalid),
        .m_axis_result_tdata                (result_0_data),
        .m_axis_result_tuser                ()
    );
    
    floating_point_add_sub fp_add_sub_1 (
        .aclk                               (clk),
       .s_axis_a_tvalid                     (result_0_tvalid & op_valid[SRAM_R_PORT_CNT-1]),
        .s_axis_a_tdata                     (result_0_data),
        .s_axis_b_tvalid                    (result_0_tvalid & op_valid[SRAM_R_PORT_CNT-1]),
        .s_axis_b_tdata                     (op_2),
        .s_axis_operation_tvalid            (result_0_tvalid & op_valid[SRAM_R_PORT_CNT-1]),
        .s_axis_operation_tdata             (operation),
        .m_axis_result_tvalid               (result_1_tvalid),
        .m_axis_result_tdata                (result_1_data),
        .m_axis_result_tuser                ()
    );
    
    always_comb begin
        if(!sub_n) begin
            operation                       = 8'b01;
        end else begin
            operation                       = 8'b00;
        end
    end
    
    always_comb begin
        result                              = {OPERAND_WIDTH{1'b0}};
        if(op_valid[SRAM_R_PORT_CNT-1]) begin
            result                          = result_1_data;
            done                            = result_1_tvalid;
        end else begin
            result                          = result_0_data;
            done                            = result_0_tvalid;
        end
    end

    // Assign
    assign result_o                         = result;
    assign  done_o                          = done;

endmodule

