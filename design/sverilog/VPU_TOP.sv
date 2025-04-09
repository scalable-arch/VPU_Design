`include "VPU_PKG.svh"

module VPU_TOP
#(
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    // VPU REQUEST INTERFACE
    VPU_REQ_IF.device                       vpu_req_if,
    VPU_RESPONSE_IF.device                  vpu_response_if,

    // SRAM PORT INTERFACE
    VPU_SRC_PORT_IF.host                    vpu_src0_port_if,
    VPU_SRC_PORT_IF.host                    vpu_src1_port_if,
    VPU_SRC_PORT_IF.host                    vpu_src2_port_if,
    VPU_DST_PORT_IF.host                    vpu_dst0_port_if
);
    import VPU_PKG::*;

    vpu_h2d_req_instr_t                     instr_latch;
    wire                                    is_sum;
    wire                                    is_reduction;
    wire    [SRC_OPERAND_CNT-1:0]           operand_rvalid;
    wire    [OPERAND_ADDR_WIDTH-1:0]        src_addr[SRC_OPERAND_CNT];                                 
    wire    [STREAM_ID_WIDTH-1:0]           stream_id;
    wire                                    ctrl_ready;
    wire                                    ctrl_valid;
    wire                                    opget_start;
    wire                                    opget_done;
 
    wire    [EXEC_UNIT_DATA_WIDTH-1:0]      operand_fifo_rdata[SRAM_READ_PORT_CNT];
    wire    [SRC_OPERAND_CNT-1:0]           operand_fifo_rden;

    wire                                    exec_start;
    wire                                    exec_done;
    
    wire                                    is_reduction;
    wire                                    wb_start;
    wire                                    wb_done;
    
    wire                                    wb_data_valid;
    wire    [OPERAND_WIDTH*VLANE_CNT-1:0]   wb_data;

    VPU_DECODER #(
        //...
    ) vpu_decoder (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .vpu_req_if                         (vpu_req_if),
        .instr_latch_o                      (instr_latch),
        .is_sum_o                           (is_sum),
        .is_reduction_o                     (is_reduction),
        .operand_rvalid_o                   (operand_rvalid),
        .stream_id_o                        (stream_id),
        .ctrl_ready_i                       (ctrl_ready),
        .ctrl_valid_o                       (ctrl_valid)
    );

    VPU_CONTROLLER #(
        //...
    ) vpu_controller (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .ctrl_valid_i                       (ctrl_valid),
        .ctrl_ready_o                       (ctrl_ready),
        .instr_latch_i                      (instr_latch),
        .stream_id_i                        (stream_id),
        .is_sum_i                           (is_sum),
        .is_reduction_i                     (is_reduction),
        .operand_rvalid_i                   (operand_rvalid),
        .opget_start_o                      (opget_start),
        .opget_done_i                       (opget_done),
        .operand_queue_rden_o               (operand_fifo_rden),
        .exec_start_o                       (exec_start),
        .exec_done_i                        (exec_done),
        .wb_data_valid_o                    (wb_data_valid),
        .wb_start_o                         (wb_start),
        .wb_done_i                          (wb_done),

        .vpu_response_if                    (vpu_response_if)
    );

    VPU_EXEC_UNIT #(
        //...
    ) vpu_exec_unit (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .start_i                            (exec_start),
        .opcode_i                           (instr_latch.opcode),
        .is_reduction_i                     (is_reduction),
        .is_sum_i                           (is_sum),
        .operand_i                          (operand_fifo_rdata),
        .operand_valid_i                    (operand_rvalid),
        .dout_o                             (wb_data),
        .done_o                             (exec_done)
    );

    VPU_SRC_PORT #(
        //...
    ) vpu_src_port (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .operand_rvalid_i                   (operand_rvalid),
        .src_addr_i                         (src_addr),
        .start_i                            (opget_start),
        .done_o                             (opget_done),
        .operand_fifo_rden_i                (operand_fifo_rden),
        .operand_fifo_rdata_o               (operand_fifo_rdata),
        .vpu_src0_port_if                   (vpu_src0_port_if),
        .vpu_src1_port_if                   (vpu_src1_port_if),
        .vpu_src2_port_if                   (vpu_src2_port_if)
    );

    VPU_WB_UNIT #(
        //...
    ) vpu_wb_unit (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .start_i                            (wb_start),
        .done_o                             (wb_done),
        .is_reduction_i                     (is_reduction),
        .wb_data_valid_i                    (wb_data_valid),
        .wb_data_i                          (wb_data),
        .dst_addr_i                         (instr_latch.dst0),
        .vpu_dst0_port_if                   (vpu_dst0_port_if)
    );

    assign  src_addr[0]                     = instr_latch.src0;
    assign  src_addr[1]                     = instr_latch.src1;
    assign  src_addr[2]                     = instr_latch.src2;

endmodule