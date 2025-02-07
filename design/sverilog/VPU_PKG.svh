`ifndef __VPU_PKG_SVH__
`define __VPU_PKG_SVH__

package VPU_PKG;

    // VPU Constraints
    // used localparam so that they cannot modified

    /* Model Config */
    localparam  DIM_SIZE                    = 512; // N
    localparam  ELEM_WIDTH                  = 16; // BF16
    localparam  ELEM_PER_DIM_CNT            = (DIM_SIZE/ELEM_WIDTH);

    /* VPU Instruction Config */
    localparam  INSTR_WIDTH                 = 128;
    localparam  INSTR_NUM                   = 14;
    localparam  OPCODE_WIDTH                = 8;
    localparam  OPERAND_WIDTH               = ELEM_WIDTH;
    localparam  OPERAND_ADDR_WIDTH          = 24;
    localparam  SRC_OPERAND_CNT             = 3;
    localparam  SRC_OPERAND_CNT_LG2         = $clog2(SRC_OPERAND_CNT);
    localparam  DST_OPERAND_CNT             = 1;
    localparam  DST_OPERAND_CNT_LG2         = $clog2(SRC_OPERAND_CNT);
    localparam  TOTAL_OPERAND_CNT           = SRC_OPERAND_CNT + DST_OPERAND_CNT;
    localparam  MAX_DELAY                   = 8;
    localparam  MAX_DELAY_LG2               = $clog2(MAX_DELAY);

    /* SRAM Config */
    localparam  SRAM_BANK_CNT               = 4;
    localparam  SRAM_BANK_CNT_LG2           = $clog2(SRAM_BANK_CNT);
    localparam  SRAM_BANK_DEPTH             = 1024;
    localparam  SRAM_BANK_DEPTH_LG2         = $clog2(SRAM_BANK_DEPTH);
    localparam  SRAM_DATA_WIDTH             = 512;
    localparam  SRAM_DATA_WIDTH_LG2         = $clog2(SRAM_DATA_WIDTH);
    localparam  SRAM_BANK_SIZE              = SRAM_BANK_DEPTH * SRAM_DATA_WIDTH;
    localparam  SRAM_BANK_SIZE_LG2          = $clog2(SRAM_BANK_SIZE);
    localparam  SRAM_SIZE                   = SRAM_BANK_CNT * SRAM_BANK_SIZE;
    localparam  SRAM_SIZE_LG2               = $clog2(SRAM_SIZE);

    /* VPU Component Config */
    localparam  SRAM_R_PORT_CNT             = SRC_OPERAND_CNT;
    localparam  SRAM_W_PORT_CNT             = DST_OPERAND_CNT;
    localparam  REQ_FIFO_DEPTH              = 16;
    localparam  REQ_FIFO_DEPTH_LG2          = $clog2(REQ_FIFO_DEPTH);
    localparam  VLANE_CNT                   = 16;
    localparam  EXEC_CNT                    = ELEM_PER_DIM_CNT/VLANE_CNT;
    localparam  EXEC_CNT_LG2                = $clog2(EXEC_CNT);
    localparam  OPERAND_QUEUE_DEPTH         = 2;
    localparam  DECODE_CYCLE                = 2;
    localparam  DWIDTH_PER_EXEC             = VLANE_CNT * OPERAND_WIDTH;

    //-----------------------------------------------------
    // Cache Address Mapping
    //    -----------------------------------------
    //    |      TAG      | BANK_ID | DIM_OFFSET |
    //    -----------------------------------------
    //-----------------------------------------------------
    function automatic [SRAM_BANK_CNT_LG2-1:0]
                                        get_bank_id(input [OPERAND_ADDR_WIDTH-1:0] addr);
        //get_bank_id                        = {SRAM_BANK_CNT_LG2{1'b0}};  // 0 padding
        get_bank_id                         = addr[SRAM_BANK_CNT_LG2+SRAM_DATA_WIDTH_LG2-1:SRAM_DATA_WIDTH_LG2];
    endfunction

    function automatic [SRAM_BANK_DEPTH_LG2-1:0]
                                        get_raddr(input [OPERAND_ADDR_WIDTH-1:0] addr);
        //get_raddr                          = {SRAM_BANK_DEPTH_LG2{1'b0}};  // 0 padding
        get_raddr                           = addr[SRAM_SIZE_LG2-1:(SRAM_BANK_CNT_LG2+SRAM_DATA_WIDTH_LG2)];
    endfunction

    function automatic [SRAM_BANK_DEPTH_LG2-1:0]
                                        get_waddr(input [OPERAND_ADDR_WIDTH-1:0] addr);
        //get_raddr                          = {SRAM_BANK_DEPTH_LG2{1'b0}};  // 0 padding
        get_waddr                           = addr[SRAM_SIZE_LG2-1:(SRAM_BANK_CNT_LG2+SRAM_DATA_WIDTH_LG2)];
    endfunction

    // Opcode
    typedef enum logic [7:0] { 
        // BF16
        VPU_H2D_REQ_OPCODE_FADD             = 8'h01, 
        VPU_H2D_REQ_OPCODE_FSUB             = 8'h02, 
        VPU_H2D_REQ_OPCODE_FMUL             = 8'h03,
        VPU_H2D_REQ_OPCODE_FDIV             = 8'h04,
        VPU_H2D_REQ_OPCODE_FADD3            = 8'h05,
        VPU_H2D_REQ_OPCODE_FSUM             = 8'h06,
        VPU_H2D_REQ_OPCODE_FMAX             = 8'h07,
        VPU_H2D_REQ_OPCODE_FMAX2            = 8'h08,
        VPU_H2D_REQ_OPCODE_FMAX3            = 8'h09,
        VPU_H2D_REQ_OPCODE_FAVG2            = 8'h0A,
        VPU_H2D_REQ_OPCODE_FAVG3            = 8'h0B,
        VPU_H2D_REQ_OPCODE_FEXP             = 8'h0C,
        VPU_H2D_REQ_OPCODE_FSQRT            = 8'h0D,
        VPU_H2D_REQ_OPCODE_FRECIP           = 8'h0E

        //Convert
        /*...*/
    } vpu_h2d_req_opcode_t;


    typedef struct {
        logic   [MAX_DELAY_LG2-1:0]         delay;
        logic   [SRAM_R_PORT_CNT-1:0]       src_cnt;                          
    } delay_and_src_cnt_t;

    // VPU Instruction
    typedef struct packed {
        vpu_h2d_req_opcode_t                opcode;      // [127:120]
        logic   [23:0]                      dst0;        // [119:96]
        logic   [23:0]                      src0;        // [95:72]
        logic   [23:0]                      src1;        // [71:48]
        logic   [23:0]                      src2;        // [47:24]
        logic   [23:0]                      imm;         // [23:0]
    } vpu_h2d_req_instr_t; // 128-bit

    typedef struct packed {
        logic                               fp_add_r;
        logic                               fp_sub_r;
        logic                               fp_mul_r;
        logic                               fp_div_r;
        logic                               fp_sqrt_r;
        logic                               fp_exp_r;
        logic                               fp_recip_r;
        logic                               fp_max_r;
        logic                               fp_avg_r;
        logic                               fp_red_r;
    } vpu_exec_fp_op_req_t; // 10-bit

    typedef struct packed {
        logic                               fp_sum_r;
        logic                               fp_max_r;
    } vpu_exec_red_op_req_t;

    typedef enum logic {
        EXEC,
        RED
    } vpu_exec_op_type_t;

    typedef struct packed {
        vpu_exec_fp_op_req_t                fp_req;
        vpu_exec_red_op_req_t               red_req;
        vpu_exec_op_type_t                  op_type;
    } vpu_exec_req_t; // 16-bit

    // VPU Instruction
    typedef struct packed {
        logic   [SRAM_R_PORT_CNT-1:0]       rvalid;
        logic   [OPERAND_ADDR_WIDTH-1:0]    raddr0;
        logic   [OPERAND_ADDR_WIDTH-1:0]    raddr1;
        logic   [OPERAND_ADDR_WIDTH-1:0]    raddr2;
        logic   [OPERAND_ADDR_WIDTH-1:0]    waddr;
        vpu_exec_req_t                      op_func;
    } vpu_instr_decoded_t; // 128-bit

    function automatic [OPERAND_ADDR_WIDTH-1:0]
                                        get_src_operand(
                                        input vpu_h2d_req_instr_t instr,
                                        input int i
                                        );
        // synopsys translate_off
        assert(i < SRC_OPERAND_CNT); // i must be lower than src_operand_cnt
        // synopsys translate_on

        get_src_operand         = instr[(3-i)*(OPERAND_ADDR_WIDTH)+:OPERAND_ADDR_WIDTH];
    endfunction

    function automatic [OPERAND_ADDR_WIDTH-1:0]
                                        get_opcode(input vpu_h2d_req_instr_t instr);
        get_opcode              = instr[(INSTR_WIDTH-1)-:OPCODE_WIDTH];
    endfunction

endpackage /* VPU_PKG */

`endif /* __VPU_PKG_SVH__ */