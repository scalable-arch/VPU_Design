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

    vpu_instr_decoded_t                     instr_decoded;
    wire    [STREAM_ID_WIDTH-1:0]           stream_id;
    wire                                    ctrl_ready;
    wire                                    ctrl_valid;
    wire                                    opget_start;
    wire                                    opget_done;
    wire    [EXEC_UNIT_DATA_WIDTH-1:0]      operand_fifo_rdata[SRAM_READ_PORT_CNT];
    wire    [SRC_OPERAND_CNT-1:0]           operand_fifo_rden;

    wire                                    exec_start;
    wire                                    exec_done;
    
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
        .instr_decoded_o                    (instr_decoded),
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
        .instr_decoded_i                    (instr_decoded),
        .stream_id_i                        (stream_id),
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
        .op_func_i                          (instr_decoded.op_func),
        .operand_i                          (operand_fifo_rdata),
        .operand_valid_i                    (instr_decoded.rvalid),
        .dout_o                             (wb_data),
        .done_o                             (exec_done)
    );

    VPU_SRC_PORT #(
        //...
    ) vpu_src_port (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .instr_decoded_i                    (instr_decoded),
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
        .wb_data_valid_i                    (wb_data_valid),
        .wb_data_i                          (wb_data),
        .instr_decoded_i                    (instr_decoded),
        .vpu_dst0_port_if                   (vpu_dst0_port_if)
    );

endmodule