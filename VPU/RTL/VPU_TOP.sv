`include "/home/sg05060/generic_npu/src/VPU/RTL/Header/VPU_PKG.svh"
module VPU_TOP
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,

    // VPU REQUEST INTERFACE
    VPU_REQ_IF.device                       vpu_req_if,

    // SRAM PORT INTERFACE
    VPU_SRC_PORT_IF.host                    vpu_src_port_if,
    VPU_DST_PORT_IF.host                    vpu_dst_port_if
);
    import VPU_PKG::*;

    REQ_IF                                  req_if(clk,rst_n); 

    wire                                    opget_start;
    wire                                    opget_done;
    wire    [DWIDTH_PER_EXEC-1:0]           operand_fifo_rdata[SRAM_R_PORT_CNT];
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
        .req_if                             (req_if)
    );

    VPU_CONTROLLER #(
        //...
    ) vpu_controller (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .req_if                             (req_if),

        .opget_start_o                      (opget_start),
        .opget_done_i                       (opget_done),
        .operand_queue_rden_o               (operand_fifo_rden),

        .exec_start_o                       (exec_start),
        .exec_done_i                        (exec_done),

        .wb_data_valid_o                    (wb_data_valid),
        .wb_start_o                         (wb_start),
        .wb_done_i                          (wb_done)
    );

    VPU_EXEC_UNIT #(
        //...
    ) vpu_exec_unit (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .start_i                            (exec_start),
        .op_func_i                          (req_if.op_func),
        .delay_i                            (req_if.delay),
        .operand_i                          (operand_fifo_rdata),
        .operand_valid_i                    (req_if.rvalid),
        .dout_o                             (wb_data),
        .done_o                             (exec_done)
    );

    VPU_SRC_PORT #(
        //...
    ) vpu_src_port (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .req_if                             (req_if),
        .start_i                            (opget_start),
        .done_o                             (opget_done),
        .operand_fifo_rden_i                (operand_fifo_rden),
        .operand_fifo_rdata_o               (operand_fifo_rdata),
        .vpu_src_port_if                    (vpu_src_port_if)
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
        .req_if                             (req_if),
        .vpu_dst_port_if                    (vpu_dst_port_if)
    );

endmodule