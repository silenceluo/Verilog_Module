//////////////////////////////////////////////////////////////////////////////
//  This is a big endian version of bridge, newer data will be in higher bits
//////////////////////////////////////////////////////////////////////////////
module bridge_combine #(
    parameter DIN_W     = 8,
    parameter DOUT_W    = 32,
    parameter DATA_W    = 8,

    parameter COMBINE_N = DOUT_W/DIN_W,
    parameter BIG_EN    = 1,
    parameter CNT_WIDTH = $clog2(DIN_W+DOUT_W)
) (    
    input logic                     clk,
    input logic                     rst_n,
    
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
    Empty, 
    Fill,
    Full,
    Flush
} state_t;

state_t                         state_d,    state_q;

logic [$clog2(DOUT_W):0]        cnt_d,      cnt_q;
logic [DOUT_W-1:0][DATA_W-1:0]  reg_d,      reg_q,  temp;


always_ff @(posedge clk or negedge rst_n) begin
    if(rst_n == 0) begin
        state_q <= Empty;
        cnt_q   <= 0;
        reg_q   <= 0;
    end else begin  //if(rst_n == 1) begin
        state_q <= state_d;
        cnt_q   <= cnt_d;
        reg_q   <= reg_d;
    end    
end

always_comb begin
    state_d = state_q;
    cnt_d   = cnt_q;
    reg_d   = reg_q;
    
    vld_o   = 0;
    last_o  = 0;
    rdy_o   = 0;

    case(state_q) 
        Empty: begin
            rdy_o = 1;
            if(vld_i == 1) begin
                reg_d[DIN_W-1 : 0]  = din;
                cnt_d               = DIN_W;

                if( last_i==1 ) begin
                    state_d = Flush;
                end else begin
                    state_d = Fill;
                end
            end
        end

        Fill: begin
            rdy_o = 1;
            if(vld_i == 1) begin
                for( int i=0; i<(DOUT_W-DIN_W); i++ ) begin
                    reg_d[DIN_W+i] = reg_q[i];
                end
                for( int i=0; i<DIN_W; i++ ) begin
                    reg_d[i]    = din[i];
                end
                cnt_d   = cnt_q + DIN_W;

                if( last_i==1 ) begin
                    state_d = Flush;
                end else begin
                    if(cnt_d == DOUT_W) begin
                        state_d = Full;
                    end else begin
                        state_d = Fill;
                    end
                end
            end           
        end

        Full: begin
            vld_o = 1;
            if(rdy_i == 1) begin
                rdy_o = 1;
                if(vld_i == 1) begin
                    reg_d[DIN_W-1 : 0]  = din;
                    cnt_d               = DIN_W;

                    if( last_i==1 ) begin
                        state_d = Flush;
                    end else begin
                        if(cnt_d == DOUT_W) begin
                            state_d = Full;
                        end else begin
                            state_d = Fill;
                        end
                    end
                end else begin
                    reg_d = '0;
                    cnt_d = '0;

                    state_d = Empty;
                end
            end     
        end

        Flush: begin
            vld_o = 1;
            if(rdy_i == 1) begin
                reg_d   = 0;
                cnt_d   = 0;
                last_o  = 1;
                state_d = Empty;
            end
        end
    endcase
end

generate
    if(BIG_EN == 1) begin
        /*
        always_comb begin
            if(state_q == Flush) begin
                temp[DOUT_W-1:DOUT_W-cnt_q] = reg_q[cnt_q-1 : 0];
                for(int i=0; i<COMBINE_N; i++) begin
                    dout[(i+1)*DIN_W-1 : i*DIN_W] = temp[DOUT_W-i*DIN_W-1 : DOUT_W-(i+1)*DIN_W]; 
                end
            end else begin
                for(int i=0; i<COMBINE_N; i++) begin
                    dout[(i+1)*DIN_W-1 : i*DIN_W] = reg_q[DOUT_W-i*DIN_W-1 : DOUT_W-(i+1)*DIN_W]; 
                end
            end
        end
        */

        always_comb begin
            for(int i=0; i<COMBINE_N; i++) begin
                for(int j=0; j<DIN_W; j++) begin
                    dout[i*DIN_W + j] = reg_q[DOUT_W-(i+1)*DIN_W + j]; 
                end
            end
        end
    end else begin
        always_comb begin
            dout = reg_q;
        end
    end
endgenerate

endmodule