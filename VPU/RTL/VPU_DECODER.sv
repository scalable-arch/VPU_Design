`include "VPU_PKG.svh"

module VPU_DECODER
#(
    //...
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    VPU_REQ_IF.device                       vpu_req_if,
    
    REQ_IF.src                              req_if        
);
    import VPU_PKG::*;

    //REQ_IF
    logic   [SRAM_R_PORT_CNT]               rvalid; 
    logic   [MAX_DELAY_LG2-1:0]             delay;
    logic   [DECODE_CYCLE-1:0]              valid;
    vpu_exec_req_t                          op_func;


    // Operation Delay Table
    const logic [MAX_DELAY_LG2-1:0] opcode_delay [INSTR_NUM] = '{
        'd0, // None(opcode==0)

        // Unsigned Int
        'd1,    //ADD
        'd1,    //SUB
        'd3,    //MUL
        'd3,    //DIV
        'd1,    //ADD3
        'd5,    //SUM
        'd1,    //MAX
        'd2,    //MAX2
        'd2,    //MAX3
        'd3,    //AVG2
        'd3,    //AVG3

        // Signed Int
        'd1,    //ADD
        'd1,    //SUB
        'd3,    //MUL
        'd3,    //DIV
        'd1,    //ADD3
        'd5,    //SUM
        'd1,    //MAX
        'd2,    //MAX2
        'd2,    //MAX3
        'd3,    //AVG2
        'd3,    //AVG3  

        // FP
        'd3,    //ADD
        'd3,    //SUB
        'd3,    //MUL
        'd3,    //DIV
        'd4,    //ADD3
        'd5,    //SUM
        'd5,    //MAX
        'd5,    //MAX2
        'd5,    //MAX3
        'd5,    //AVG2
        'd6,    //AVG3
        'd6,    //EXP
    };

    
    //---------------------------------------
    // Decoding Delay
    //---------------------------------------
    always_comb begin
        rvalid                              = 3'b000;
        op_func                             = {$bits(vpu_exec_req_t){1'b0}};
        delay                               = {MAX_DELAY_LG2{1'b0}};
        if(vpu_req_if.valid && req_if.ready) begin
            // Decoding Delay
            delay                           = opcode_delay[vpu_req_if.h2d_req_instr.opcode];
            // Decoding Source Operand Count
            case(vpu_req_if.h2d_req_instr.opcode)
                VPU_H2D_REQ_OPCODE_UISUM,
                VPU_H2D_REQ_OPCODE_UIMAX,
                VPU_H2D_REQ_OPCODE_ISUM,
                VPU_H2D_REQ_OPCODE_IMAX,
                VPU_H2D_REQ_OPCODE_FSUM,
                VPU_H2D_REQ_OPCODE_FMAX, 
                VPU_H2D_REQ_OPCODE_FEXP: begin
                    rvalid                  = 3'b001; 
                end
                VPU_H2D_REQ_OPCODE_UIADD3,
                VPU_H2D_REQ_OPCODE_UIMAX3,
                VPU_H2D_REQ_OPCODE_UIAVG3,
                VPU_H2D_REQ_OPCODE_IADD3,
                VPU_H2D_REQ_OPCODE_IMAX3,
                VPU_H2D_REQ_OPCODE_IAVG3,
                VPU_H2D_REQ_OPCODE_FADD3,
                VPU_H2D_REQ_OPCODE_FMAX3,
                VPU_H2D_REQ_OPCODE_FAVG3: begin
                    rvalid                  = 3'b111;
                end
                default: begin
                    rvalid                  = 3'b011;
                end
            endcase

            // Decoding Operation
            case(vpu_req_if.h2d_req_instr.opcode)
                VPU_H2D_REQ_OPCODE_UIADD,
                VPU_H2D_REQ_OPCODE_UIADD3 : begin
                    op_func.ui_req.ui_add_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_UISUB : begin
                    op_func.ui_req.ui_sub_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_UIMUL : begin
                    op_func.ui_req.ui_mul_r   = 1'b1;    
                end
                VPU_H2D_REQ_OPCODE_UIDIV : begin
                    op_func.ui_req.ui_div_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_UISUM : begin
                    op_func.ui_req.ui_red_r   = 1'b1;
                    op_func.red_func          = 1'b0;
                end
                VPU_H2D_REQ_OPCODE_UIMAX : begin
                    op_func.ui_req.ui_red_r   = 1'b1;
                    op_func.red_func          = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_UIMAX2,
                VPU_H2D_REQ_OPCODE_UIMAX3 : begin
                    op_func.ui_req.ui_max_r   = 1'b1;
                end
                VPU_H2D_REQ_OPCODE_UIAVG2,
                VPU_H2D_REQ_OPCODE_UIAVG3 : begin
                    op_func.ui_req.ui_avg_r   = 1'b1;
                end
            endcase

        end
    end

    //---------------------------------------
    // Decode Cycle
    //---------------------------------------
    always_ff @(posedge clk) begin
        if(rst_n) begin
            valid                           <= {DECODE_CYCLE{1'b0}};
        end else if(vpu_req_if.valid && req_if.ready)begin
            valid[0]                        <= vpu_req_if.valid;
            for(int i = 1; i < DECODE_CYCLE; i++) begin
                valid[i]                        <= valid[i-1];
            end
        end
    end
    
    // REQ_IF
    assign  req_if.delay                    = delay;
    assign  req_if.rvalid                   = rvalid;
    genvar k;
    generate
        for (k=0; k < SRAM_R_PORT_CNT; k=k+1) begin : SLICING
            req_if.raddr[k]                 = get_src_operand(vpu_req_if.h2d_req_instr,k);
        end
    endgenerate
    assign  req_if.waddr                    = vpu_req_if.h2d_req_instr.dst0;
    assign  req_if.valid                    = valid[DECODE_CYCLE-1];
    assign  req_if.op_func                  = op_func;
endmodule