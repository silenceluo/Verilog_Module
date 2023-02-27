////////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Amazon.com, Inc. or its affiliates.
//
// Use and distribution of this code is restricted.
//
// All Rights Reserved Worldwide.
//
////////////////////////////////////////////////////////////////////////////////
// author: Pei LUO, luopl@amazon.com
// date created: Aug. 2020
// description:
////////////////////////////////////////////////////////////////////////////////

module fifo_slice #(
    parameter type t = logic
)(
    input  logic    clk_i,
    input  logic    rst_ni,
    input  logic    clear_i,

    input      t    din_i,
    input  logic    vld_i,
    output logic    rdy_o,

    output     t    dout_o,
    output logic    vld_o,
    input  logic    rdy_i
);

typedef enum logic {
    empty, 
    full
} state_t;

state_t         state_d, state_q;
t               data_d, data_q;

assign dout_o   = data_q;
  
always_comb begin : fsm
    vld_o   = 1'b0;
    rdy_o   = 1'b0;
    data_d  = data_q;
    state_d = state_q;

    case (state_q)
        empty: begin
            rdy_o   = 1'b1;
            if (vld_i) begin
                state_d = full;
                data_d  = din_i;
            end
        end

        full: begin
            vld_o   = 1'b1;
            if (rdy_i) begin
                rdy_o   = 1'b1;
                if (vld_i) begin
                    data_d  = din_i;
                end else begin
                    state_d = empty;
                end
            end
        end
    endcase // case (state_q)
end // block: fsm

always @(posedge clk_i or negedge rst_ni) begin : sequential
    if (~rst_ni) begin
        state_q <= empty;
        data_q  <= '0;
    end else begin
        if(clear_i == 1'b1) begin
            state_q <= empty;
            data_q  <= '0;
        end else begin
            state_q <= state_d;
            data_q  <= data_d;
        end
    end
end

endmodule // fifo_slice
