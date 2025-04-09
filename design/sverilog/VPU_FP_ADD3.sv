`include "VPU_PKG.svh"

module VPU_FP_ADD3
#(
    parameter   ACCEPTANCE_CAPABILITY       = 2 
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

    logic                                   flag, flag_n;
    logic                                   tvalid;
    logic   [OPERAND_WIDTH-1:0]             a_tdata, b_tdata;
    logic                                   done;
    logic                                   operand_queue_rden;
    logic                                   result_tvalid_delayed;

    wire    [OPERAND_WIDTH-1:0]             operand_queue_rdata;
    wire    [OPERAND_WIDTH-1:0]             result_tdata;
    wire                                    result_tvalid;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            flag                            <= 1'b0;
            result_tvalid_delayed           <= 1'b0;
        end else begin
            flag                            <= flag_n;
            result_tvalid_delayed           <= result_tvalid;
        end
    end

    always_comb begin
        flag_n                              = flag;

        tvalid                              = 1'b0;
        done                                = 1'b0;
        operand_queue_rden                  = 1'b0;

        if(start_i) begin
            tvalid                          = 1'b1;
        end else begin
            tvalid                          = result_tvalid & !flag;
        end

        if(flag) begin
            if(!result_tvalid & result_tvalid_delayed) begin
                flag_n                          = 1'b0;
            end
        end else begin
            if(result_tvalid & result_tvalid_delayed) begin
                flag_n                          = 1'b1;
            end
        end

        if(result_tvalid) begin // second_stage
            a_tdata                         = result_tdata;
            b_tdata                         = operand_queue_rdata;
            if(!flag) begin
                operand_queue_rden          = 1'b1;
            end
        end else begin // first_stage
            a_tdata                         = operand_0;
            b_tdata                         = operand_1;
        end
        // done signal is valid only for second_stage
        done                                = result_tvalid & flag;
    end

    SAL_FIFO
    #(
        .DEPTH_LG2                          ($clog2(ACCEPTANCE_CAPABILITY)),
        .DATA_WIDTH                         (OPERAND_WIDTH),
        .RDATA_FF_OUT                       (1)
    )
    operand_2_queue
    (
        .clk                                (clk)
      , .rst_n                              (rst_n)

      , .full_o                             ()
      , .afull_o                            ()
      , .wren_i                             (start_i)
      , .wdata_i                            (operand_2)

      , .empty_o                            ()
      , .aempty_o                           (/* NC */)
      , .rden_i                             (operand_queue_rden)
      , .rdata_o                            (operand_queue_rdata)

      , .debug_o                            ()
    );

    floating_point_add_sub fp_add_sub_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (tvalid),
        .s_axis_a_tdata                     (a_tdata),
        .s_axis_b_tvalid                    (tvalid),
        .s_axis_b_tdata                     (b_tdata),
        .s_axis_operation_tvalid            (tvalid),
        .s_axis_operation_tdata             (8'h00),
        .m_axis_result_tvalid               (result_tvalid),
        .m_axis_result_tdata                (result_tdata),
        .m_axis_result_tuser                ()
    );

    // Assignment
    assign  result_o                        = result_tdata;
    assign  done_o                          = done;
endmodule

