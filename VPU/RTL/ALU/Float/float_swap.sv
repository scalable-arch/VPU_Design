// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

//`include "../inc/float_macros.vh"

`define FLOAT_PARAMS parameter EXP_WIDTH = 8, parameter MAN_WIDTH = 7
`define FLOAT_BIAS_PARAMS `FLOAT_PARAMS, parameter BIAS = -127
`define FLOAT_PRPG_PARAMS .EXP_WIDTH(EXP_WIDTH), .MAN_WIDTH(MAN_WIDTH)
`define FLOAT_PRPG_BIAS_PARAMS `FLOAT_PRPG_PARAMS, .BIAS(BIAS)
`define FLOAT_WIDTH (EXP_WIDTH + MAN_WIDTH + 1)

// `float_swap` ensures that the exponent of `lhs` is the same or greater than that of `rhs`.
module float_swap #(`FLOAT_PARAMS) (
    input       [(`FLOAT_WIDTH - 1) : 0]    lhs,
    input       [(`FLOAT_WIDTH - 1) : 0]    rhs,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    lhs_out,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    rhs_out
);
    wire [(EXP_WIDTH - 1) : 0] lhs_exp, rhs_exp;
    assign lhs_exp = lhs[(`FLOAT_WIDTH - 2) : MAN_WIDTH];
    assign rhs_exp = rhs[(`FLOAT_WIDTH - 2) : MAN_WIDTH];

    always @(*) begin
        if (lhs_exp < rhs_exp) begin
            lhs_out <= rhs;
            rhs_out <= lhs;
        end else begin
            lhs_out <= lhs;
            rhs_out <= rhs;
        end
    end
endmodule