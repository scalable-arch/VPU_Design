// Copyright (c) 2024 Sungkyunkwan University
// All rights reserved
// Author: Jungrae Kim <dale40@gmail.com>
// Description: Simple Dual-Port synchronous RAM

module SAL_SDP_RAM
#(
    parameter   DEPTH_LG2               = 12
  , parameter   DATA_WIDTH              = 32
  , parameter   RDATA_FF_OUT            = 1
  // synchronization between read/write ports
  // WR_FIRST: new content is immediately made available for reading
  // RD_FIRST: old content is read before new content is loaded
  , parameter   RW_SYNC                 = "WR_FIRST"
)
(
    input   wire                        clk

  , input   wire                        en_a
  , input   wire                        we_a
  , input   wire    [DEPTH_LG2-1:0]     addr_a
  , input   wire    [DATA_WIDTH-1:0]    di_a

  , input   wire                        en_b
  , input   wire    [DEPTH_LG2-1:0]     addr_b
  , output  logic   [DATA_WIDTH-1:0]    do_b
);

    localparam  DEPTH                   = (2**DEPTH_LG2);

    logic   [DATA_WIDTH-1:0]            mem[DEPTH];

    always_ff @(posedge clk)
        if (en_a & we_a) begin
            mem[addr_a]                     <= di_a;
        end

    generate
        if (RDATA_FF_OUT) begin: rdata_timing_optimize
            always_ff @(posedge clk)
                if (en_b) begin
                    if (we_a & (addr_a == addr_b)) begin
                        do_b                            <= di_a;
                    end
                    else begin
                        do_b                            <= mem[addr_b];
                    end
                end
            end
        else begin: rdata_timing_no_optimize
            assign    do_b                      = mem[addr_b];
        end
    endgenerate

endmodule
