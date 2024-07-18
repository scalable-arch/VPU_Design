`ifndef __VPU_PKG_SVH__
`define __VPU_PKG_SVH__

package VPU_PKG;

    // VPU Constraints
    // used localparam so that they cannot modified
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
    localparam  SRAM_R_PORT_CNT             = 3;
    localparam  SRAM_W_PORT_CNT             = 1;

    localparam  VEC_LEN                     = 32;
    localparam  VEC_LEN_LG2                 = $clog2(VEC_LEN);
    
    localparam  OPCODE_WIDTH                = 8;
    localparam  OPERAND_WIDTH               = 16;
    localparam  OPERAND_ADDR_WIDTH          = 32;
    localparam  OPERAND_QUEUE_DEPTH         = 2;
    localparam  SRC_OPERAND_CNT             = 3;
    localparam  SRC_OPERAND_CNT_LG2         = $clog2(SRC_OPERAND_CNT);
    localparam  DST_OPERAND_CNT             = 1;
    localparam  DST_OPERAND_CNT_LG2         = $clog2(SRC_OPERAND_CNT);
    localparam  OPERAND_CNT                 = SRC_OPERAND_CNT + DST_OPERAND_CNT;
    //localparam  SRC_ADDR_WIDTH              = 32;
    //localparam  DST_ADDR_WIDTH              = 32;
    localparam  INSTR_WIDTH                 = 136;
    
    localparam  REQ_FIFO_DEPTH              = 16;
    localparam  REQ_FIFO_DEPTH_LG2          = $clog2(REQ_FIFO_DEPTH);

    localparam  VLANE_CNT                   = 16;

    localparam  DIM_SIZE                    = 512;
    localparam  DIM_ELEM_CNT                = (DIM_SIZE/OPERAND_WIDTH);

    localparam  EXEC_CNT                    = DIM_SIZE/OPERAND_WIDTH/VLANE_CNT;
    localparam  EXEC_CNT_LG2                = $clog2(EXEC_CNT);

    /*
    * Cache Address Mapping
        -----------------------------------------
        |      TAG      | BANK_ID | DIM_OFFSET |
        -----------------------------------------
    */
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
        VPU_H2D_REQ_OPCODE_IADD             = 8'h01,
        VPU_H2D_REQ_OPCODE_ISUB             = 8'h02,
        VPU_H2D_REQ_OPCODE_FADD             = 8'h03,
        //...
    } vpu_h2d_req_opcode_t;

    // VPU Instruction
    typedef struct packed {
        vpu_h2d_req_opcode_t                opcode;      // [135:128]
        logic   [31:0]                      src2;        // [127:96]
        logic   [31:0]                      src1;        // [95:64]
        logic   [31:0]                      src0;        // [63:32]
        logic   [31:0]                      dst0;        // [31:0]
    } vpu_h2d_req_instr_t; // 136-bit

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
        get_opcode                          = instr[OPERAND_CNT*(OPERAND_ADDR_WIDTH)+:OPCODE_WIDTH];
    endfunction

endpackage /* VPU_PKG */

`endif /* __VPU_PKG_SVH__ */