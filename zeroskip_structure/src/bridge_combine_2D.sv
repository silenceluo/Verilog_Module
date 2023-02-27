//////////////////////////////////////////////////////////////////////////////
//  This is a big endian version of bridge, newer data will be in higher bits
//  This version can deal with 2D input
//////////////////////////////////////////////////////////////////////////////
module bridge_combine_2D #(
    parameter   DIN_W       = 32,
    parameter   DOUT_W      = 128,
    parameter   DATA_W      = 8,
    parameter   CNT_WIDTH   = $clog2(DIN_W+DOUT_W)
) (    
    input logic                 clk,
    input logic                 rst_n,
    
    input logic                             vld_i,
    input logic [DIN_W-1:0][DATA_W-1:0]     din,
    input logic                             last_i,
    output logic                            rdy_o,

    output logic                            vld_o,
    output logic [DOUT_W-1:0][DATA_W-1:0]   dout,
    output logic                            last_o,
    input logic                             rdy_i 
);

//////////////////////////////////////////////////////////////////////////////
//  Input stage: re-org the input din to unpacked 2D array
//////////////////////////////////////////////////////////////////////////////
logic [DIN_W-1:0]   din_org [DATA_W-1:0];
always_comb begin : din_re_org
    for(int i=0; i<DATA_W; i++) begin
        for(int j=0; j<DIN_W; j++) begin
            din_org[i][j]   = din[j][i];
        end
    end
end


//////////////////////////////////////////////////////////////////////////////
//  Kernel algorithm for shift register control
//////////////////////////////////////////////////////////////////////////////
typedef enum logic [1:0] {
    Empty, 
    Fill,
    Full,
    Flush
} state_t;

state_t                     state_d,    state_q;

logic [CNT_WIDTH-1:0]       cnt_d,      cnt_q;
logic [DOUT_W+DIN_W-1:0]    reg_d [DATA_W-1:0];
logic [DOUT_W+DIN_W-1:0]    reg_q [DATA_W-1:0];


always_ff @(posedge clk or negedge rst_n) begin
    if(rst_n == 0) begin
        state_q <= Empty;
        cnt_q   <= 0;
        for(int i=0; i<DATA_W; i++) begin
            reg_q[i]    <= 0;
        end
    end else begin  //if(rst_n == 1) begin
        state_q <= state_d;
        cnt_q   <= cnt_d;
        for(int i=0; i<DATA_W; i++) begin
            reg_q[i]    <= reg_d[i];
        end
    end    
end

always_comb begin
    state_d = state_q;
    for(int i=0; i<DATA_W; i++) begin
        reg_d[i]    = reg_q[i];
    end
    cnt_d   = cnt_q;

    vld_o   = 0;
    last_o  = 0;
    rdy_o   = 0;

    case(state_q) 
        Empty: begin
            rdy_o = 1;
            if(vld_i == 1) begin
                for(int i=0; i<DATA_W; i++) begin
                    reg_d[i]    = { {DOUT_W{1'b0}}, din_org[i] };
                end
                cnt_d = DIN_W;

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
                for(int i=0; i<DATA_W; i++) begin
                    reg_d[i]    = ( { {DOUT_W{1'b0}}, din_org[i] } << cnt_q ) | reg_q[i];
                end
                cnt_d = cnt_q + DIN_W;

                if( last_i==1 ) begin
                    state_d = Flush;
                end else begin
                    if(cnt_d >= DOUT_W) begin
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
                for(int i=0; i<DATA_W; i++) begin
                    reg_d[i]    = reg_q[i] >> DOUT_W;
                end
                cnt_d = cnt_q - DOUT_W;

                rdy_o = 1;
                if(vld_i == 1) begin
                    for(int i=0; i<DATA_W; i++) begin
                        reg_d[i]    = ( { {DOUT_W{1'b0}}, din_org[i]} << cnt_d ) | reg_d[i];
                    end
                    cnt_d = cnt_d + DIN_W;

                    if( last_i==1 ) begin
                        state_d = Flush;
                    end else begin
                        if(cnt_d >= DOUT_W) begin
                            state_d = Full;
                        end else begin
                            state_d = Fill;
                        end
                    end
                end else begin
                    if(cnt_d >= DOUT_W) begin
                        state_d = Full;
                    end else begin
                        state_d = Fill;
                    end                    
                end
            end     
        end

        Flush: begin
            vld_o = 1;
            if(rdy_i == 1) begin
                if(cnt_q > DOUT_W) begin
                    for(int i=0; i<DATA_W; i++) begin
                        reg_d[i]    = reg_q[i] >> DOUT_W;
                    end
                    cnt_d   = cnt_q - DOUT_W;
                    state_d = Flush;
                end else begin
                    for(int i=0; i<DATA_W; i++) begin
                        reg_d[i]    = 0;
                    end
                    cnt_d   = 0;
                    last_o  = 1;
                    state_d = Empty;
                end
            end
        end
    endcase
end

//////////////////////////////////////////////////////////////////////////////
//  Output stage: re-org the output to packed array to dout
//////////////////////////////////////////////////////////////////////////////
always_comb begin : dout_re_org
    for(int i=0; i<DOUT_W; i++) begin
        for(int j=0; j<DATA_W; j++) begin
            dout[i][j]   = reg_q[j][i];
        end
    end
end

endmodule
