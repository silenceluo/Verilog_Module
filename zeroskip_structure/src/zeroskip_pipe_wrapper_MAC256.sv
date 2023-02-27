////////////////////////////////////////////////////////////////////////////////
// This is a zero skip controller for MAC1K
// 2021.09.24: version 3, split the size-32 group into 2 small groups, each 16
// The returning size of each group could be 0-16. Need to merge after 2 cycles.
////////////////////////////////////////////////////////////////////////////////
module zeroskip_pipe_wrapper_MAC256 #(
   parameter M             = 16,
   parameter N             = 16,
   parameter DATA_W        = 8,

   parameter GROUP_NUM     = M,     // GROUP_NUM should be simply M, parameterized for DV
   parameter GROUP_NZ_MAX  = 8,
   parameter GROUP_SIZE    = 16     // Group size
) (
   input logic                               clk,
   input logic                               a_rst_n,
   input logic                               enable,
   input logic                               group_nz_sel,   //  0--8:32, 1--8:16

   input logic [M*2-1:0][M-1:0]              znz_din,
   input logic                               znz_din_vld_i,
   output logic                              znz_din_rdy_o,

   input logic [M*2-1:0][DATA_W-1:0]         act_din,
   input logic                               act_din_vld_i,
   output logic                              act_din_rdy_o,

   output logic [M-1:0][M-1:0][DATA_W-1:0]   act_enc_dout,
   output logic                              act_enc_vld_o,
   input logic                               act_enc_rdy_i
);

logic group_quar_en;
assign group_quar_en = ~group_nz_sel;

////////////////////////////////////////////////////////////////////////////////
//  25% ratio part
//  Input stage, store the act/znz input data into unpack array
////////////////////////////////////////////////////////////////////////////////
typedef enum logic {
   ACT_EMPTY,
   ACT_HALF
} state_t;

state_t  state_d,    state_q;

logic [GROUP_SIZE-1:0]  znz_din_unpack [2*M-1:0] ;

always_comb begin
   for(int i=0; i<2*M; i++) begin
      znz_din_unpack[i] = znz_din[i];
   end
end

logic [GROUP_NZ_MAX-1 : 0][DATA_W-1 : 0]  zs_dout     [2*M-1 : 0];

logic [M-1 : 0][DATA_W-1 : 0]             zs_dout_comb_d [M-1 : 0],
                                          zs_dout_comb_q [M-1 : 0];

// Valid signal for 50% and 25% ZSd
logic                                     zs_valid_quar_d,  zs_valid_quar_q;
logic                                     zs_valid_half_d,  zs_valid_half_q;
logic [M-1 : 0][M-1 : 0][DATA_W-1 : 0]    zs_dout_quar_d,   zs_dout_quar_q;
logic [M-1 : 0][M-1 : 0][DATA_W-1 : 0]    zs_dout_half;

genvar i;
generate
   for(i=0; i<M; i++) begin
      zeroskip #(
         .GROUP_SIZE    ( 16     ),
         .GROUP_NZ_MAX  ( 8      ), // GROUP_NZ_MAX, the largest is 8 for 8:16 and 8:32
         .DATA_W        ( DATA_W )
      ) zeroskip_a_i (
         .znz_din       ( znz_din_unpack[i]  ),
         .act_din       ( act_din[M-1 : 0]   ),
         .act_enc_dout  ( zs_dout[i]         )
      );

      zeroskip #(
         .GROUP_SIZE    ( 16     ),
         .GROUP_NZ_MAX  ( 8      ), // GROUP_NZ_MAX, the largest is 8 for 8:16 and 8:32
         .DATA_W        ( DATA_W )
      ) zeroskip_b_i (
         .znz_din       ( znz_din_unpack[M+i]   ),
         .act_din       ( act_din[2*M-1 : M]    ),
         .act_enc_dout  ( zs_dout[M+i]          )
      );
   end
endgenerate

always_comb begin : block_zs_dout_combine
   if (group_quar_en == 0) begin // 50%, each output 8B
      for (int i=0; i<M; i++) begin
         zs_dout_comb_d[i] = { zs_dout[M+i][7:0], zs_dout[i][7:0] };
      end
   end else if (group_quar_en == 1) begin // 25%, each output 4B
      for (int i=0; i<M; i++) begin
         zs_dout_comb_d[i] = { '0, zs_dout[M+i][3:0], zs_dout[i][3:0] };
      end
   end
end

assign zs_valid_half_d = (act_din_vld_i && act_din_rdy_o) && (znz_din_vld_i && znz_din_rdy_o) && (group_quar_en == 0);

always_ff @( posedge clk or negedge a_rst_n ) begin : FF_block
   if( a_rst_n == 0 ) begin
      state_q  <= ACT_EMPTY;
      for (int n=0; n<M; n++) begin
         zs_dout_comb_q[n]   <= '0;
      end
      zs_dout_quar_q    <= '0;
      zs_valid_quar_q   <= '0;
      zs_valid_half_q   <= '0;
   end else begin
      if (enable == 1) begin
         state_q        <= state_d;
         zs_dout_comb_q <= zs_dout_comb_d;
         if(group_quar_en == 1) begin
            zs_dout_quar_q    <= zs_dout_quar_d;
            zs_valid_quar_q   <= zs_valid_quar_d;
         end else if(group_quar_en == 0) begin
            zs_valid_half_q   <= zs_valid_half_d;   
         end
      end
   end
end

always_comb begin :  Comb_block
   state_d  = state_q;
   zs_valid_quar_d   = 1'b0;
   case(state_q)
      ACT_EMPTY: begin
         if( (act_din_vld_i == 1'b1) && (znz_din_vld_i == 1'b1) && (group_quar_en == 1) ) begin
            state_d = ACT_HALF;
         end
      end

      //  Receive the second half of ACT, and the first ZNZ
      ACT_HALF: begin        
         if( (act_din_vld_i == 1'b1) && (znz_din_vld_i == 1'b1) && (group_quar_en == 1) ) begin           
            zs_valid_quar_d   = 1'b1;
            for (int i=0; i<M; i++) begin
               zs_dout_quar_d[i] = { zs_dout_comb_d[i][7:0], zs_dout_comb_q[i][7:0] };
            end

            state_d = ACT_EMPTY;
         end
      end

      default: begin
         state_d = state_q;
      end
   endcase
end

////////////////////////////////////////////////////////////////////////////////
//  50% ratio part
////////////////////////////////////////////////////////////////////////////////
generate
   for (i=0; i<M; i++) begin
      assign zs_dout_half[i]  = zs_dout_comb_q[i];
   end
endgenerate

always_comb begin
   znz_din_rdy_o  = 1;
   act_din_rdy_o  = 1;    

   if(group_quar_en == 1) begin
      act_enc_dout   = zs_dout_quar_q;
      act_enc_vld_o  = zs_valid_quar_q;
   end else begin
      act_enc_dout   = zs_dout_half;
      act_enc_vld_o  = zs_valid_half_q;
   end
end

endmodule

