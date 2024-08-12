`ifndef __VPU_PKG_SVH__
`define __VPU_PKG_SVH__

package VPU_PKG;

    // VPU Constraints
    // used localparam so that they cannot modified

    /* Model Config */
    localparam  DIM_SIZE                    = 512; // N
    localparam  ELEM_WIDTH                  = 16; // BF16
    localparam  ELEM_PER_DIM_CNT            = (DIM_SIZE/ELEM_WIDTH);

    /* SRAM Config */
    localparam  SRAM_BANK_CNT               = 4;
    localparam  SRAM_BANK_CNT_LG2           = $clog2(SRAM_BANK_CNT);
    localparam  SRAM_BANK_DEPTH             = 1024;
    localparam  SRAM_BANK_DEPTH_LG2         = $clog2(SRAM_BANK_DEPTH);
    localparam  SRAM_BANK_SIZE              = SRAM_BANK_DEPTH * SRAM_DATA_WIDTH;
    localparam  SRAM_BANK_SIZE_LG2          = $clog2(SRAM_BANK_SIZE);
    localparam  SRAM_SIZE                   = SRAM_BANK_CNT * SRAM_BANK_SIZE;
    localparam  SRAM_SIZE_LG2               = $clog2(SRAM_SIZE);
    localparam  SRAM_DATA_WIDTH             = 512;
    localparam  SRAM_DATA_WIDTH_LG2         = $clog2(SRAM_DATA_WIDTH);

    /* VPU Component Config */
    localparam  SRAM_R_PORT_CNT             = SRC_OPERAND_CNT;
    localparam  SRAM_W_PORT_CNT             = DST_OPERAND_CNT;
    localparam  REQ_FIFO_DEPTH              = 16;
    localparam  REQ_FIFO_DEPTH_LG2          = $clog2(REQ_FIFO_DEPTH);
    localparam  VLANE_CNT                   = 16;
    localparam  EXEC_CNT                    = ELEM_PER_DIM_CNT/VLANE_CNT;
    localparam  EXEC_CNT_LG2                = $clog2(EXEC_CNT);
    localparam  OPERAND_QUEUE_DEPTH         = 2;

    /* VPU Instruction Config */
    localparam  INSTR_WIDTH                 = 136;
    localparam  INSTR_NUM                   = 34;
    localparam  OPCODE_WIDTH                = 8;
    localparam  OPERAND_WIDTH               = ELEM_WIDTH;
    localparam  OPERAND_ADDR_WIDTH          = 32;
    localparam  SRC_OPERAND_CNT             = 3;
    localparam  SRC_OPERAND_CNT_LG2         = $clog2(SRC_OPERAND_CNT);
    localparam  DST_OPERAND_CNT             = 1;
    localparam  DST_OPERAND_CNT_LG2         = $clog2(SRC_OPERAND_CNT);
    localparam  TOTAL_OPERAND_CNT           = SRC_OPERAND_CNT + DST_OPERAND_CNT;
    localparam  MAX_DELAY                   = 8;
    localparam  MAX_DELAY_LG2               = $clog2(MAX_DELAY);

    //-----------------------------------------------------
    // Cache Address Mapping
    //    -----------------------------------------
    //    |      TAG      | BANK_ID | DIM_OFFSET |
    //    -----------------------------------------
    //-----------------------------------------------------
    function automatic [SRAM_BANK_CNT_LG2-1:0]
                                        get_bank_id(input [OPERAND_ADDR_WIDTH-1:0] addr);
        //get_bank_id                        = {SRAM_BANK_CNT_LG2{1'b0}};  // 0 padding
        get_bank_id                         = raddr[SRAM_BANK_CNT_LG2+SRAM_DATA_WIDTH_LG2-1:SRAM_DATA_WIDTH_LG2];
    endfunction

    function automatic [SRAM_BANK_DEPTH_LG2-1:0]
                                        get_raddr(input [OPERAND_ADDR_WIDTH-1:0] addr);
        //get_raddr                          = {SRAM_BANK_DEPTH_LG2{1'b0}};  // 0 padding
        get_raddr                           = raddr[SRAM_SIZE_LG2-1:(SRAM_BANK_CNT_LG2+SRAM_DATA_WIDTH_LG2)];
    endfunction

    function automatic [SRAM_BANK_DEPTH_LG2-1:0]
                                        get_waddr(input [OPERAND_ADDR_WIDTH-1:0] addr);
        //get_raddr                          = {SRAM_BANK_DEPTH_LG2{1'b0}};  // 0 padding
        get_waddr                           = raddr[SRAM_SIZE_LG2-1:(SRAM_BANK_CNT_LG2+SRAM_DATA_WIDTH_LG2)];
    endfunction

    // Opcode
    typedef enum logic [7:0] { 
        // Unsigned Int
        VPU_H2D_REQ_OPCODE_UIADD            = 8'h01, 
        VPU_H2D_REQ_OPCODE_UISUB            = 8'h02, 
        VPU_H2D_REQ_OPCODE_UIMUL            = 8'h03,
        VPU_H2D_REQ_OPCODE_UIDIV            = 8'h04,
        VPU_H2D_REQ_OPCODE_UIADD3           = 8'h05,
        VPU_H2D_REQ_OPCODE_UISUM            = 8'h06,
        VPU_H2D_REQ_OPCODE_UIMAX            = 8'h07,
        VPU_H2D_REQ_OPCODE_UIMAX2           = 8'h08,
        VPU_H2D_REQ_OPCODE_UIMAX3           = 8'h09,
        VPU_H2D_REQ_OPCODE_UIAVG2           = 8'h0A,
        VPU_H2D_REQ_OPCODE_UIAVG3           = 8'h0B,

        // Signed Int
        VPU_H2D_REQ_OPCODE_IADD             = 8'h0C, 
        VPU_H2D_REQ_OPCODE_ISUB             = 8'h0D, 
        VPU_H2D_REQ_OPCODE_IMUL             = 8'h0E,
        VPU_H2D_REQ_OPCODE_IDIV             = 8'h0F,
        VPU_H2D_REQ_OPCODE_IADD3            = 8'h10,
        VPU_H2D_REQ_OPCODE_ISUM             = 8'h11,
        VPU_H2D_REQ_OPCODE_IMAX             = 8'h12,
        VPU_H2D_REQ_OPCODE_IMAX2            = 8'h13,
        VPU_H2D_REQ_OPCODE_IMAX3            = 8'h14,
        VPU_H2D_REQ_OPCODE_IAVG2            = 8'h15,
        VPU_H2D_REQ_OPCODE_IAVG3            = 8'h16,

        // BF16
        VPU_H2D_REQ_OPCODE_FADD             = 8'h17, 
        VPU_H2D_REQ_OPCODE_FSUB             = 8'h18, 
        VPU_H2D_REQ_OPCODE_FMUL             = 8'h19,
        VPU_H2D_REQ_OPCODE_FDIV             = 8'h1A,
        VPU_H2D_REQ_OPCODE_FADD3            = 8'h1B,
        VPU_H2D_REQ_OPCODE_FSUM             = 8'h1C,
        VPU_H2D_REQ_OPCODE_FMAX             = 8'h1D,
        VPU_H2D_REQ_OPCODE_FMAX2            = 8'h1E,
        VPU_H2D_REQ_OPCODE_FMAX3            = 8'h1F,
        VPU_H2D_REQ_OPCODE_FAVG2            = 8'h20,
        VPU_H2D_REQ_OPCODE_FAVG3            = 8'h21,
        VPU_H2D_REQ_OPCODE_FEXP             = 8'h22,

        //Convert
        /*...*/
    } vpu_h2d_req_opcode_t;


    typedef struct {
        logic   [MAX_DELAY_LG2-1:0]         delay;
        logic   [SRAM_R_PORT_CNT-1:0]       src_cnt;                          
    } delay_and_src_cnt_t;

    // VPU Instruction
    typedef struct packed {
        vpu_h2d_req_opcode_t                opcode;      // [135:128]
        logic   [31:0]                      src2;        // [127:96]
        logic   [31:0]                      src1;        // [95:64]
        logic   [31:0]                      src0;        // [63:32]
        logic   [31:0]                      dst0;        // [31:0]
    } vpu_h2d_req_instr_t; // 136-bit

    typedef struct packed {
        logic                               ui_add_r;
        logic                               ui_sub_r;
        logic                               ui_mul_r;
        logic                               ui_div_r;
        logic                               ui_max_r;
        logic                               ui_avg_r;
        logic                               ui_red_r;
    } vpu_exec_ui_op_req_t; // 7bit

    typedef struct packed {
        logic                               fp_add_r;
        logic                               fp_sub_r;
        logic                               fp_mul_r;
        logic                               fp_div_r;
        logic                               fp_max_r;
        logic                               fp_avg_r;
        logic                               fp_red_r;
    } vpu_exec_fp_op_req_t; // 7bit

    typedef struct packed {
        logic                               sum_r;
        logic                               max_r;
    } vpu_exec_red_func_t;  // 2bit

    typedef struct packed {
        vpu_exec_ui_op_req_t                ui_req;   
        vpu_exec_fp_op_req_t                fp_req;
        vpu_exec_red_func_t                 red_func;
    } vpu_exec_req_t; // 16-bit

    function automatic [OPERAND_ADDR_WIDTH-1:0]
                                        get_src_operand(
                                        input vpu_h2d_req_instr_t instr,
                                        input int i,
                                        );
        //get_src_operand                     = {SRAM_BANK_DEPTH_LG2{1'b0}};  // 0 padding
        get_src_operand                     = instr[(i+1)*(OPERAND_ADDR_WIDTH)+:OPERAND_ADDR_WIDTH];
    endfunction

    function automatic [OPERAND_ADDR_WIDTH-1:0]
                                        get_opcode(input vpu_h2d_req_instr_t instr);
        //get_src_operand                     = {SRAM_BANK_DEPTH_LG2{1'b0}};  // 0 padding
        get_opcode                          = instr[TOTAL_OPERAND_CNT*(OPERAND_ADDR_WIDTH)+:OPCODE_WIDTH];
    endfunction

endpackage /* VPU_PKG */

`endif /* __VPU_PKG_SVH__ */