
module _VPU_INCR_CNTR
#(
    parameter   MAX_COUNT           = 4
)
(
    // clock & reset
    input                       clk,
    input                       rst_n,

    // request from the address decoder
    input                       start_i,
    input   [VPU_PKG::MAX_DELAY_LG2-1:0] delay,
    output                      done_o       
);
    localparam  S_IDLE              = 2'b00;
    localparam  S_RUN               = 2'b01;
    localparam  S_DONE              = 2'b10;


    localparam  MAX_COUNT_LG2       = $clog2(MAX_COUNT);

    logic   [MAX_COUNT_LG2-1:0]     cntr,       cntr_n;
    logic                           state,  state_n;

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
        case(state)
            S_IDLE: begin
                if(start_i) begin
                    state_n         = S_RUN;
                end
            end
            S_RUN: begin
                if(cntr == delay-1) begin
                    cntr_n          = {MAX_COUNT_LG2{1'b0}};
                    if(start_i)
                        state_n         = S_RUN;
                    else
                        state_n         = S_IDLE;
                end else begin
                    cntr_n          = cntr + 'd1;
                end
            end
        endcase
    end

    assign  done_o                  = (cntr == (delay-1));
endmodule