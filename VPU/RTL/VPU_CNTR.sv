
module VPU_CNTR
#(
    parameter   MAX_DELAY_LG2   = 4
)
(
    // clock & reset
    input                       clk,
    input                       rst_n,

    // request from the address decoder
    input   [MAX_DELAY_LG2-1:0] count,
    input                       start_i,
    output                      done_o       
);
    localparam  S_IDLE              = 2'b00;
    localparam  S_RUN               = 2'b01;
    localparam  S_DONE              = 2'b10;


    localparam  MAX_COUNT_LG2       = $clog2(MAX_DELAY_LG2);

    logic   [MAX_COUNT_LG2-1:0]     cntr,       cntr_n;
    logic                           done;
    logic   [1:0]                   state,  state_n;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            cntr                    <= {MAX_COUNT_LG2{1'b0}};
            state                   <= 1'b0;
        end else begin
            cntr                    <= cntr_n;
            state                   <= state_n;
        end
    end
    always_comb begin
        cntr_n                      = cntr;
        state_n                     = state;
        done                        = 1'b0;
        case(state)
            S_IDLE: begin
                if(start_i) begin
                    state_n         = S_RUN;
                end
            end
            S_RUN: begin
                if(cntr_n == count-'d1) begin
                    cntr_n          = {MAX_COUNT_LG2{1'b0}};
                    state_n         = S_DONE;
                end else begin
                    cntr_n          = cntr + 'd1;
                end
            end
            S_DONE: begin
                done                = 1'b1;
                state_n             = S_IDLE;
            end
        endcase
    end

    assign  done_o                  = done;
endmodule