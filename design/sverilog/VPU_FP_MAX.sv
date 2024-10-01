`include "VPU_PKG.svh"

module VPU_FP_MAX
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
    
    logic                                   result_0_data_buff;
   
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            result_0_data_buff              <= 1'b0;
        end else begin
            if(result_0_valid)
            result_0_data_buff              <= result_0_data[0];
        end
    end
    
    
    logic  [3:0]                            result_0_data, result_1_data;
    wire                                    result_0_valid, result_1_valid;
    logic   [OPERAND_WIDTH-1:0]             result;
    logic                                   done;
    
    always_comb begin
       if(op_valid[SRAM_R_PORT_CNT-1]) begin
            result                          = result_1_data[0] ? (result_0_data[0] ? op_0 : op_1) : op_2;
            done                            = result_1_valid;
        end else begin
            result                          = result_0_data[0] ? op_0 : op_1;
            done                            = result_0_valid;
        end
    end
    

      
    
    floating_point_cmp fp_max_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (start_i),
        .s_axis_a_tdata                     (op_0),
        .s_axis_b_tvalid                    (start_i),
        .s_axis_b_tdata                     (op_1),
        .m_axis_result_tvalid               (result_0_valid),
        .m_axis_result_tdata                (result_0_data),
        .m_axis_result_tuser                ()
    );
    
    floating_point_cmp fp_max_1 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (result_0_valid & op_valid[SRAM_R_PORT_CNT-1]),
        .s_axis_a_tdata                     ((result_0_data == 1'b1) ? op_0 : op_1),
        .s_axis_b_tvalid                    (result_0_valid & op_valid[SRAM_R_PORT_CNT-1]),
        .s_axis_b_tdata                     (op_2),
        .m_axis_result_tvalid               (result_1_valid),
        .m_axis_result_tdata                (result_1_data),
        .m_axis_result_tuser                ()
    );
    
  

    // Assign
    assign result_o                         = result;
    assign  done_o                          = done;
endmodule