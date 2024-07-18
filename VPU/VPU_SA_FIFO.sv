// Copyright (c) 2024 Sungkyunkwan University
// All rights reserved
// Author: Jungrae Kim <dale40@gmail.com>
// Description:

module SAL_SA_FIFO
#(
    DEPTH_LG2                           = 4
  , DATA_WIDTH                          = 32
  , AFULL_THRES                         = (1 << DEPTH_LG2)
  , AEMPTY_THRES                        = 0
  , RDATA_FF_OUT                        = 0
  , RST_MEM                             = 0
)
(
    input   wire                        clk
  , input   wire                        rst_n

  , output  wire                        full_o
  , output  wire                        afull_o
  , input   wire                        wren_i
  , input   wire    [DATA_WIDTH-1:0]    wdata_i

  , output  wire                        empty_o
  , output  wire                        aempty_o
  , input   wire                        rden_i
  , output  wire    [DATA_WIDTH-1:0]    rdata_o

  , output  logic   [31:0]              debug_o
);
    localparam  DEPTH                   = (2**DEPTH_LG2);

    logic   [DATA_WIDTH-1:0]            mem[DEPTH];

    // read/write pointers have one extra bit for full/empty checking
    logic   [DEPTH_LG2:0]               wrptr,      wrptr_n;
    logic   [DEPTH_LG2:0]               rdptr,      rdptr_n;

    // needed for afull/aempty checking
    logic   [DEPTH_LG2:0]               cnt,        cnt_n;

    logic                               full,       full_n;
    logic                               afull,      afull_n;
    logic                               empty,      empty_n;
    logic                               aempty,     aempty_n;
    logic                               overflown,  overflown_n;
    logic                               undrflown,  undrflown_n;

    always_ff @(posedge clk)
        if (~rst_n & RST_MEM) begin
            for (int i=0; i < DEPTH; i++) begin
                mem[i]                      <= {DATA_WIDTH{1'b0}};
            end
        end
        else begin
            if (wren_i) begin
                mem[wrptr[DEPTH_LG2-1:0]]   <= wdata_i;
            end
        end

    always_ff @(posedge clk)
        if (~rst_n) begin
            wrptr                       <= {(DEPTH_LG2+1){1'b0}};
            rdptr                       <= {(DEPTH_LG2+1){1'b0}};

            cnt                         <= 'd0;

            full                        <= 1'b0;
            afull                       <= 1'b0;
            empty                       <= 1'b1;
            aempty                      <= 1'b1;
            overflown                   <= 1'b0;
            undrflown                   <= 1'b0;
        end
        else begin
            wrptr                       <= wrptr_n;
            rdptr                       <= rdptr_n;

            cnt                         <= cnt_n;

            full                        <= full_n;
            afull                       <= afull_n;
            empty                       <= empty_n;
            aempty                      <= aempty_n;
            overflown                   <= overflown_n;
            undrflown                   <= undrflown_n;
        end

    always_comb begin
        if (wren_i) begin
            wrptr_n                     = wrptr + 'd1;
        end
        else begin
            wrptr_n                     = wrptr;
        end

        if (rden_i) begin
            rdptr_n                     = rdptr + 'd1;
        end
        else begin
            rdptr_n                     = rdptr;
        end

        if (wren_i & ~rden_i) begin
            cnt_n                       = cnt + 'd1;
        end
        else if (~wren_i & rden_i) begin
            cnt_n                       = cnt - 'd1;
        end
        else begin
            cnt_n                       = cnt;
        end

        full_n                      =  (wrptr_n[DEPTH_LG2] != rdptr_n[DEPTH_LG2])
                                     & (wrptr_n[DEPTH_LG2-1:0] == rdptr_n[DEPTH_LG2-1:0]);
        afull_n                     = (cnt_n >= AFULL_THRES);
        empty_n                     = (wrptr_n == rdptr_n);
        aempty_n                    = (cnt_n <= AEMPTY_THRES);
        overflown_n                 = overflown | (full_o & wren_i);    // sticky
        undrflown_n                 = undrflown | (empty_o & rden_i);   // sticky
    end

    assign  full_o                  = full;
    assign  afull_o                 = afull;
    assign  empty_o                 = empty;
    assign  aempty_o                = aempty;
    assign  debug_o[31]             = overflown;
    assign  debug_o[30]             = full;
    assign  debug_o[15]             = undrflown;
    assign  debug_o[14]             = empty;

    generate
        if ($bits(wrptr) > 14) begin
            assign  debug_o[29:16]          = wrptr[13:0];
            assign  debug_o[13:0]           = rdptr[13:0];
        end
        else begin
            assign  debug_o[29:16]          = 14'd0 | wrptr;
            assign  debug_o[13:0]           = 14'd0 | rdptr;
        end

        if (RDATA_FF_OUT) begin: rdata_timing_optimize
            logic   [DATA_WIDTH-1:0]        rdata;
            always_ff @(posedge clk)
                if (~rst_n) begin
                    rdata                       <= {{DATA_WIDTH}{1'b0}};
                end
                else begin
                    if (wren_i & (wrptr[DEPTH_LG2-1:0] == rdptr_n[DEPTH_LG2-1:0]))
                    begin
                        rdata                       <= wdata_i;
                    end
                    else begin
                        rdata                       <= mem[rdptr_n[DEPTH_LG2-1:0]];
                    end
                end

            assign  rdata_o                 = rdata;
        end
        else begin: rdata_no_timing_optimize
            assign  rdata_o                 = mem[rdptr[DEPTH_LG2-1:0]];
        end
    endgenerate

    // synopsys translate_off
    // svlint off operator_case_equality
    overflow_check: assert property (
        @(posedge clk) disable iff (~rst_n)
        (overflown !== 1'b1)
    );
    undrflow_check: assert property (
        @(posedge clk) disable iff (~rst_n)
        (undrflown !== 1'b1)
    );
    // svlint on operator_case_equality
    // synopsys translate_on

endmodule