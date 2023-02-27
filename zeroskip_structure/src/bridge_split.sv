//////////////////////////////////////////////////////////////////////////////
//  This is a big endian version of bridge, newer data will be in higher bits
//////////////////////////////////////////////////////////////////////////////
module bridge_split #(
    parameter DIN_W     = 16,
    parameter DOUT_W    = 8,
    parameter DATA_W    = 8,

    parameter SPLIT_CNT = DIN_W/DOUT_W
) (    
    input logic                             clk,
    input logic                             rst_n,
    
    input logic                             vld_i,
    input logic [DIN_W-1:0][DATA_W-1:0]     din,
    input logic                             last_i,
    output logic                            rdy_o,

    output logic                            vld_o,
    output logic [DOUT_W-1:0][DATA_W-1:0]   dout,
    output logic                            last_o,
    input logic                             rdy_i 
);

typedef enum logic [1:0] {
    FIRST,
    WAIT_RDY,
    DUMP
} state_t;

state_t                             state_d,    state_q;
logic [DIN_W-1:0][DATA_W-1:0]       reg_d,      reg_q;
logic [$clog2(SPLIT_CNT) : 0]       cnt_d,      cnt_q;
logic                               last_d,     last_q; //Flop the last signal

always_ff @( posedge clk or negedge rst_n ) begin
    if(rst_n == 1'b0) begin
        state_q <= FIRST;
        reg_q   <= '0;
        cnt_q   <= '0;
        last_q  <= '0;
    end else begin
        state_q <= state_d;
        reg_q   <= reg_d;
        cnt_q   <= cnt_d;
        last_q  <= last_d;
    end
end


always_comb begin
    state_d = state_q;
    reg_d   = reg_q;
    cnt_d   = cnt_q;
    last_d  = last_q;

    dout    = reg_q[DOUT_W-1 : 0];
    
    rdy_o   = 0;
    vld_o   = 0;
    last_o  = 0;
    case(state_q)
        FIRST: begin
            rdy_o = 1;
            if(vld_i == 1'b1) begin
                last_d  = last_i;

                vld_o = 1'b1;
                if(rdy_i == 1'b1) begin
                    dout    = din[DOUT_W-1 : 0];
                    reg_d   = din[DIN_W-1 : DOUT_W];
                    cnt_d   = 1;
                end else begin
                    reg_d   = din;
                    cnt_d   = 0;
                end
                state_d = DUMP;
            end
        end
        
        DUMP: begin
            vld_o = 1'b1;
            if(rdy_i == 1'b1) begin
                dout    = reg_q[DOUT_W-1 : 0];

                if(cnt_q+1 == SPLIT_CNT) begin
                    last_o  = last_q;
                    reg_d   = '0;
                    cnt_d   = '0;
                    state_d = FIRST;
                end else begin
                    reg_d   = { '0, reg_q[DIN_W-1 : DOUT_W] };
                    cnt_d   = cnt_q + 1;
                    state_d = DUMP;
                end
            end 
        end
    endcase
end

endmodule