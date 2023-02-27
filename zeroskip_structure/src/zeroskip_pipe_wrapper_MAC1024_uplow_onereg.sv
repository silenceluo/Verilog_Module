////////////////////////////////////////////////////////////////////////////////
// This is a zero skip controller for MAC1K
// 2021.09.24: version 3, split the size-32 group into 2 small groups, each 16
// The returning size of each group could be 0-16. Need to merge after 2 cycles.
////////////////////////////////////////////////////////////////////////////////
module zeroskip_pipe_wrapper_MAC1024 #(
   parameter M             = 32,
   parameter N             = 32,
   parameter DATA_W        = 8,

   parameter GROUP_NUM     = M,    //  GROUP_NUM should be simply M, parameterized for DV
   parameter GROUP_SIZE    = 32,   //  Group size
   parameter LOWER         = 20,
   parameter UPPER         = GROUP_SIZE - LOWER,
   parameter GROUP_NZ_MAX  = 16
) (
   input logic                               clk,
   input logic                               rst_n,
   input logic                               group_nz_sel,  // 0--8:32, 1--8:16

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

typedef enum logic {
   ACT_EMPTY,
   ACT_HALF
} state_t;

state_t  state_d, state_q;
logic    valid,   valid_q1,   valid_q2;
assign   valid = (act_din_vld_i && act_din_rdy_o) && (znz_din_vld_i && znz_din_rdy_o);

////////////////////////////////////////////////////////////////////////////////
// In:   act[63:0]B  znz[63:0][31:0]b
// G0:   act[31:0]B  znz[31:0][31:0]b
// G1:   act[63:32]B znz[63:32][31:0]b
////////////////////////////////////////////////////////////////////////////////
//    Cycle 0: low                  1: up 16bit               
// 0: act[15: 0]+znz[31:0][15:0]    act[31:16]+znz[31:0][31:16]
// 1: act[47:32]+znz[63:32][15:0]   act[63:48]+znz[63:32][31:16]
////////////////////////////////////////////////////////////////////////////////
logic [LOWER-1 : 0]   znz_din_low_0  [M-1 : 0];     // 32 Groups, 16 bit each
logic [LOWER-1 : 0]   znz_din_low_1  [M-1 : 0];
logic [UPPER-1 : 0]   znz_din_up_0   [M-1 : 0];
logic [UPPER-1 : 0]   znz_din_up_1   [M-1 : 0];
logic [UPPER-1 : 0]   znz_din_up_0_q [M-1 : 0];
logic [UPPER-1 : 0]   znz_din_up_1_q [M-1 : 0];

logic [LOWER-1 : 0][DATA_W-1 : 0] act_din_low_0;  // One group, each 16 bytes
logic [LOWER-1 : 0][DATA_W-1 : 0] act_din_low_1;
logic [UPPER-1 : 0][DATA_W-1 : 0] act_din_up_0;
logic [UPPER-1 : 0][DATA_W-1 : 0] act_din_up_1;
logic [UPPER-1 : 0][DATA_W-1 : 0] act_din_up_0_q;
logic [UPPER-1 : 0][DATA_W-1 : 0] act_din_up_1_q;

logic [$clog2(GROUP_NZ_MAX) : 0] num_nz_up_0_d     [M-1 : 0];
logic [$clog2(GROUP_NZ_MAX) : 0] num_nz_up_1_d     [M-1 : 0];
logic [$clog2(GROUP_NZ_MAX) : 0] num_nz_low_0_d    [M-1 : 0],
                                 num_nz_low_0_q    [M-1 : 0];
logic [$clog2(GROUP_NZ_MAX) : 0] num_nz_low_1_d    [M-1 : 0],
                                 num_nz_low_1_q    [M-1 : 0];

logic [GROUP_NZ_MAX-1 : 0][DATA_W-1 : 0]  zs_dout_up_0      [M-1 : 0];
logic [GROUP_NZ_MAX-1 : 0][DATA_W-1 : 0]  zs_dout_up_1      [M-1 : 0];
logic [GROUP_NZ_MAX-1 : 0][DATA_W-1 : 0]  zs_dout_low_0     [M-1 : 0];
logic [GROUP_NZ_MAX-1 : 0][DATA_W-1 : 0]  zs_dout_low_1     [M-1 : 0];
logic [GROUP_NZ_MAX-1 : 0][DATA_W-1 : 0]  zs_dout_low_0_q   [M-1 : 0];
logic [GROUP_NZ_MAX-1 : 0][DATA_W-1 : 0]  zs_dout_low_1_q   [M-1 : 0];

logic [15:0][DATA_W-1:0]   group_zs_out_0_d  [M-1 : 0];
logic [15:0][DATA_W-1:0]   group_zs_out_1_d  [M-1 : 0];
logic [15:0][DATA_W-1:0]   group_zs_out_0_q  [M-1 : 0];
logic [15:0][DATA_W-1:0]   group_zs_out_1_q  [M-1 : 0];

logic [M-1:0][M-1:0][DATA_W-1:0]    zs_dout_quar_d,   zs_dout_quar_q;
logic                               zs_vlaid_quar_d,  zs_vlaid_quar_q;

logic [8-1 : 0][DATA_W-1 : 0] zs_dout_quar_0 [M-1 : 0];
logic [8-1 : 0][DATA_W-1 : 0] zs_dout_quar_1 [M-1 : 0];

genvar i;
generate
   for(i=0; i<M; i++) begin
      assign znz_din_low_0[i] = znz_din[i][LOWER-1 : 0];
      assign znz_din_low_1[i] = znz_din[M+i][LOWER-1 : 0];
      assign znz_din_up_0[i]  = znz_din[i][M-1 : LOWER];
      assign znz_din_up_1[i]  = znz_din[M+i][M-1 : LOWER];
   end
endgenerate

always_comb begin 
   act_din_low_0  = act_din[LOWER-1 : 0];
   act_din_low_1  = act_din[M+LOWER-1 : M];
   act_din_up_0   = act_din[M-1 : LOWER];
   act_din_up_1   = act_din[2*M-1 : M+LOWER];
end

always_ff @( posedge clk or negedge rst_n ) begin : FF_block
   if( rst_n == 0 ) begin
      state_q  <= ACT_EMPTY;
 
      for (int n=0; n<M; n++) begin
         znz_din_up_0_q[n]    <= '0;
         znz_din_up_1_q[n]    <= '0;

         num_nz_low_0_q[n]    <= '0;
         num_nz_low_1_q[n]    <= '0;

         group_zs_out_0_q[n]  <= '0;
         group_zs_out_1_q[n]  <= '0;
      end
      act_din_up_0_q <= '0;
      act_din_up_1_q <= '0;

      for (int n=0; n<M; n++) begin
         zs_dout_low_0_q[n]   <= '0;
         zs_dout_low_1_q[n]   <= '0;
      end

      zs_dout_quar_q    <= '0;
      zs_vlaid_quar_q   <= '0;

      valid_q1 <= '0;
      valid_q2 <= '0;
   end else begin
      if (group_quar_en == 1) begin
         state_q           <= state_d;
         zs_dout_quar_q    <= zs_dout_quar_d;
         zs_vlaid_quar_q   <= zs_vlaid_quar_d;
      end
      
      znz_din_up_0_q    <= znz_din_up_0;
      znz_din_up_1_q    <= znz_din_up_1;
      act_din_up_0_q    <= act_din_up_0;
      act_din_up_1_q    <= act_din_up_1;

      num_nz_low_0_q    <= num_nz_low_0_d;
      num_nz_low_1_q    <= num_nz_low_1_d;
      zs_dout_low_0_q   <= zs_dout_low_0;
      zs_dout_low_1_q   <= zs_dout_low_1;
      group_zs_out_0_q  <= group_zs_out_0_d;
      group_zs_out_1_q  <= group_zs_out_1_d;      

      valid_q1 <= valid;
      valid_q2 <= valid_q1;
   end
end

generate
   for(i=0; i<M; i++) begin
      zeroskip #(
         .GROUP_SIZE    ( LOWER              ),
         .GROUP_NZ_MAX  ( GROUP_NZ_MAX       ),
         .DATA_W        ( DATA_W             )
      ) zeroskip_low_0_i (
         .znz_din       ( znz_din_low_0[i]   ),
         .act_din       ( act_din_low_0      ),
         .act_enc_dout  ( zs_dout_low_0[i]   ),
         .num_nz        ( num_nz_low_0_d[i]  )
      );
   end

   for(i=0; i<M; i++) begin
      zeroskip #(
         .GROUP_SIZE    ( LOWER              ),
         .GROUP_NZ_MAX  ( GROUP_NZ_MAX       ),
         .DATA_W        ( DATA_W             )
      ) zeroskip_low_1_i (
         .znz_din       ( znz_din_low_1[i]   ),
         .act_din       ( act_din_low_1      ),
         .act_enc_dout  ( zs_dout_low_1[i]   ),
         .num_nz        ( num_nz_low_1_d[i]  )
      );
   end

   for(i=0; i<M; i++) begin
      zeroskip #(
         .GROUP_SIZE    ( UPPER              ),
         .GROUP_NZ_MAX  ( GROUP_NZ_MAX       ),
         .DATA_W        ( DATA_W             )
      ) zeroskip_up_0_i (
         .znz_din       ( znz_din_up_0_q[i]  ),
         .act_din       ( act_din_up_0_q     ),
         .act_enc_dout  ( zs_dout_up_0[i]    ),
         .num_nz        ( num_nz_up_0_d[i]   )
      );
   end

   for(i=0; i<M; i++) begin
      zeroskip #(
         .GROUP_SIZE    ( UPPER              ),
         .GROUP_NZ_MAX  ( GROUP_NZ_MAX       ),
         .DATA_W        ( DATA_W             )
      ) zeroskip_up_0_i (
         .znz_din       ( znz_din_up_1_q[i]  ),
         .act_din       ( act_din_up_1_q     ),
         .act_enc_dout  ( zs_dout_up_1[i]    ),
         .num_nz        ( num_nz_up_1_d[i]   )
      );
   end   
endgenerate

always_comb begin 
   for(int n=0; n<M; n++) begin
      group_zs_out_0_d[n]  = '0;
      group_zs_out_1_d[n]  = '0;
   end

   if (valid_q1 == 1) begin
      if (group_quar_en == 0) begin
         for(int n=0; n<M; n++) begin
            case(num_nz_low_0_q[n])
               0:    begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][15:0]                            }; end
               1:    begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][14:0], zs_dout_low_0_q[n][   0] }; end
               2:    begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][13:0], zs_dout_low_0_q[n][ 1:0] }; end
               3:    begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][12:0], zs_dout_low_0_q[n][ 2:0] }; end
               4:    begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][11:0], zs_dout_low_0_q[n][ 3:0] }; end
               5:    begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][10:0], zs_dout_low_0_q[n][ 4:0] }; end
               6:    begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][ 9:0], zs_dout_low_0_q[n][ 5:0] }; end
               7:    begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][ 8:0], zs_dout_low_0_q[n][ 6:0] }; end
               8:    begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][ 7:0], zs_dout_low_0_q[n][ 7:0] }; end
               9:    begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][ 6:0], zs_dout_low_0_q[n][ 8:0] }; end
               10:   begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][ 5:0], zs_dout_low_0_q[n][ 9:0] }; end
               11:   begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][ 4:0], zs_dout_low_0_q[n][10:0] }; end
               12:   begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][ 3:0], zs_dout_low_0_q[n][11:0] }; end
               13:   begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][ 2:0], zs_dout_low_0_q[n][12:0] }; end
               14:   begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][ 1:0], zs_dout_low_0_q[n][13:0] }; end
               15:   begin group_zs_out_0_d[n]  = { zs_dout_up_0[n][   0], zs_dout_low_0_q[n][14:0] }; end
               16:   begin group_zs_out_0_d[n]  = {                        zs_dout_low_0_q[n][15:0] }; end
            endcase

            case(num_nz_low_1_q[n])
               0:    begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][15:0]                            }; end
               1:    begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][14:0], zs_dout_low_1_q[n][   0] }; end
               2:    begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][13:0], zs_dout_low_1_q[n][ 1:0] }; end
               3:    begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][12:0], zs_dout_low_1_q[n][ 2:0] }; end
               4:    begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][11:0], zs_dout_low_1_q[n][ 3:0] }; end
               5:    begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][10:0], zs_dout_low_1_q[n][ 4:0] }; end
               6:    begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][ 9:0], zs_dout_low_1_q[n][ 5:0] }; end
               7:    begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][ 8:0], zs_dout_low_1_q[n][ 6:0] }; end
               8:    begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][ 7:0], zs_dout_low_1_q[n][ 7:0] }; end
               9:    begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][ 6:0], zs_dout_low_1_q[n][ 8:0] }; end
               10:   begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][ 5:0], zs_dout_low_1_q[n][ 9:0] }; end
               11:   begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][ 4:0], zs_dout_low_1_q[n][10:0] }; end
               12:   begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][ 3:0], zs_dout_low_1_q[n][11:0] }; end
               13:   begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][ 2:0], zs_dout_low_1_q[n][12:0] }; end
               14:   begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][ 1:0], zs_dout_low_1_q[n][13:0] }; end
               15:   begin group_zs_out_1_d[n]   = { zs_dout_up_1[n][   0], zs_dout_low_1_q[n][14:0] }; end
               16:   begin group_zs_out_1_d[n]   = {                        zs_dout_low_1_q[n][15:0] }; end
            endcase
         end
      end else begin
         for(int n=0; n<M; n++) begin
            case(num_nz_low_0_q[n])
               0:    begin group_zs_out_0_d[n]  = { '0, zs_dout_up_0[n][15:0]                           }; end
               1:    begin group_zs_out_0_d[n]  = { '0, zs_dout_up_0[n][14:0], zs_dout_low_0_q[n][   0] }; end
               2:    begin group_zs_out_0_d[n]  = { '0, zs_dout_up_0[n][13:0], zs_dout_low_0_q[n][ 1:0] }; end
               3:    begin group_zs_out_0_d[n]  = { '0, zs_dout_up_0[n][12:0], zs_dout_low_0_q[n][ 2:0] }; end
               4:    begin group_zs_out_0_d[n]  = { '0, zs_dout_up_0[n][11:0], zs_dout_low_0_q[n][ 3:0] }; end
               5:    begin group_zs_out_0_d[n]  = { '0, zs_dout_up_0[n][10:0], zs_dout_low_0_q[n][ 4:0] }; end
               6:    begin group_zs_out_0_d[n]  = { '0, zs_dout_up_0[n][ 9:0], zs_dout_low_0_q[n][ 5:0] }; end
               7:    begin group_zs_out_0_d[n]  = { '0, zs_dout_up_0[n][ 8:0], zs_dout_low_0_q[n][ 6:0] }; end
               8:    begin group_zs_out_0_d[n]  = { '0, zs_dout_up_0[n][ 7:0], zs_dout_low_0_q[n][ 7:0] }; end
            endcase

            case(num_nz_low_1_q[n])
               0:    begin group_zs_out_1_d[n]  = { '0, zs_dout_up_1[n][15:0]                           }; end
               1:    begin group_zs_out_1_d[n]  = { '0, zs_dout_up_1[n][14:0], zs_dout_low_1_q[n][   0] }; end
               2:    begin group_zs_out_1_d[n]  = { '0, zs_dout_up_1[n][13:0], zs_dout_low_1_q[n][ 1:0] }; end
               3:    begin group_zs_out_1_d[n]  = { '0, zs_dout_up_1[n][12:0], zs_dout_low_1_q[n][ 2:0] }; end
               4:    begin group_zs_out_1_d[n]  = { '0, zs_dout_up_1[n][11:0], zs_dout_low_1_q[n][ 3:0] }; end
               5:    begin group_zs_out_1_d[n]  = { '0, zs_dout_up_1[n][10:0], zs_dout_low_1_q[n][ 4:0] }; end
               6:    begin group_zs_out_1_d[n]  = { '0, zs_dout_up_1[n][ 9:0], zs_dout_low_1_q[n][ 5:0] }; end
               7:    begin group_zs_out_1_d[n]  = { '0, zs_dout_up_1[n][ 8:0], zs_dout_low_1_q[n][ 6:0] }; end
               8:    begin group_zs_out_1_d[n]  = { '0, zs_dout_up_1[n][ 7:0], zs_dout_low_1_q[n][ 7:0] }; end
            endcase
         end
      end
   end
end


////////////////////////////////////////////////////////////////////////////////
// The FSM to control the 25% ZS
////////////////////////////////////////////////////////////////////////////////
always_comb begin :  Comb_block
   state_d           = state_q;
   zs_vlaid_quar_d   = 0;
   zs_dout_quar_d    = zs_dout_quar_q;

   case(state_q)
      ACT_EMPTY: begin
         if( valid_q1 ) begin
            state_d  = ACT_HALF;
         end
      end

      ACT_HALF: begin        
         if( valid_q2 ) begin
            for(int i=0; i<M; i++) begin
               zs_dout_quar_d[i]   = { group_zs_out_1_d[i][7:0], group_zs_out_0_d[i][7:0], 
                                       group_zs_out_1_q[i][7:0], group_zs_out_0_q[i][7:0] };
            end
            zs_vlaid_quar_d = 1;
            state_d  = ACT_EMPTY;
         end
      end

      default: begin
         state_d  = state_q;
      end
   endcase
end

logic [M-1:0][M-1:0][DATA_W-1:0] zs_dout_half;

generate
   for (i=0; i<M; i++) begin
      assign zs_dout_half[i]  = {group_zs_out_1_q[i], group_zs_out_0_q[i]};
   end
endgenerate

always_comb begin : OUT_MUX
   znz_din_rdy_o  = 1;
   act_din_rdy_o  = 1; 

   if (group_quar_en == 0) begin 
      act_enc_dout   = zs_dout_half;
      act_enc_vld_o  = valid_q2;
   end else begin
      act_enc_dout   = zs_dout_quar_q;
      act_enc_vld_o  = zs_vlaid_quar_q;
   end
end

endmodule

