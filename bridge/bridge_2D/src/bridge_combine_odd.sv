//////////////////////////////////////////////////////////////////////////////
// This is a big endian version of bridge, newer data will be in higher bits
// This design is similar to bridge_combine except that DOUT_W cannot be 
// divided by DIN_W
//////////////////////////////////////////////////////////////////////////////
module bridge_combine_odd #(
   parameter DIN_W     = 3,
   parameter DOUT_W    = 32,
   parameter DATA_W    = 8,

   parameter REG_W      = DIN_W+DOUT_W,
   parameter BIG_EN     = 1,
   parameter CNT_WIDTH  = $clog2(REG_W)
) (    
   input logic                            clk,
   input logic                            a_rst_n,
   
   input logic                            vld_i,
   input logic [DIN_W-1:0][DATA_W-1:0]    din,
   input logic                            last_i,
   output logic                           rdy_o,

   output logic                           vld_o,
   output logic [DOUT_W-1:0][DATA_W-1:0]  dout,
   output logic                           last_o,
   input logic                            rdy_i 
);

typedef enum logic [1:0] {
   Empty, 
   Fill,
   Full,
   Flush
} state_t;

state_t                          state_d, state_q;
logic [CNT_WIDTH-1 : 0]          cnt_d,   cnt_q;
logic [REG_W-1 : 0][DATA_W-1:0]  reg_d,   reg_q,   temp;

logic [DIN_W-1 : 0]  din_transpose     [DATA_W-1 : 0];
logic [REG_W-1 : 0]  reg_d_transpose   [DATA_W-1 : 0];
logic [REG_W-1 : 0]  reg_q_transpose   [DATA_W-1 : 0];

genvar m, n; 
generate
   for (m=0; m<DATA_W; m++) begin
      for (n=0; n<DIN_W; n++) begin
         assign din_transpose[m][n] = din[n][m];
      end
   end

   for (m=0; m<DATA_W; m++) begin
      for (n=0; n<REG_W; n++) begin
         assign reg_q_transpose[m][n]  = reg_q[n][m];
      end
   end

   for (m=0; m<REG_W; m++) begin
      for (n=0; n<DATA_W; n++) begin
         assign reg_d[m][n]   = reg_d_transpose[n][m];
      end
   end
endgenerate


always_ff @(posedge clk or negedge a_rst_n) begin
   if(a_rst_n == 0) begin
      state_q  <= Empty;
      cnt_q    <= 0;
      reg_q    <= 0;
   end else begin  //if(a_rst_n == 1) begin
      state_q  <= state_d;
      cnt_q    <= cnt_d;
      reg_q    <= reg_d;
   end    
end

always_comb begin
   state_d  = state_q;
   cnt_d    = cnt_q;
   
   vld_o    = 0;
   last_o   = 0;
   rdy_o    = 0;

   case(state_q) 
      Empty: begin
         rdy_o = 1;
         if(vld_i == 1) begin
            for (int i=0; i<DATA_W; i++) begin
               reg_d_transpose[i]   = din_transpose[i];
            end
            cnt_d = DIN_W;

            if( last_i==1 ) begin
               state_d  = Flush;
            end else begin
               state_d  = Fill;
            end
         end
      end

      Fill: begin
         rdy_o = 1;
         if(vld_i == 1) begin
            for( int i=0; i<DATA_W; i++ ) begin
               reg_d_transpose[i] = reg_q_transpose[i] | (din_transpose[i] << cnt_q);
            end
            cnt_d = cnt_q + DIN_W;

            if( last_i==1 ) begin
               state_d = Flush;
            end else begin
               if(cnt_d > DOUT_W) begin
                  state_d  = Full;
               end else begin
                  state_d  = Fill;
               end
            end
         end
      end

      Full: begin
         vld_o = 1;
         if(rdy_i == 1) begin
            rdy_o = 1;
            if(vld_i == 1) begin
               for( int i=0; i<DATA_W; i++ ) begin
                  reg_d_transpose[i] = (reg_q_transpose[i] >> DOUT_W)| (din_transpose[i] << (cnt_q-DOUT_W));
               end
               cnt_d = cnt_q + DIN_W - DOUT_W;

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
               for( int i=0; i<DATA_W; i++ ) begin
                  reg_d_transpose[i] = reg_q_transpose[i] >> DOUT_W;
               end
               cnt_d = cnt_q - DOUT_W;

               state_d = Fill;
            end
         end     
      end

      Flush: begin
         vld_o = 1;
         if(rdy_i == 1) begin
            for( int i=0; i<DATA_W; i++ ) begin
               reg_d_transpose[i]   = 0;
            end
            cnt_d   = 0;
            last_o  = 1;
            state_d = Empty;
         end
      end
    endcase
end

generate
   always_comb begin
      for(int i=0; i<REG_W; i++) begin
         dout[i]  = reg_q[i]; 
      end
   end
endgenerate

endmodule
