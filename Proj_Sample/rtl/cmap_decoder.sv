////////////////////////////////////////////////////////////////////////////////
// Copyright 2019  Amazon.com, Inc. or its affiliates.  All Rights Reserved.
// 2021.10.06, V1.0, Pei LUO
////////////////////////////////////////////////////////////////////////////////
// At most the number of compressed data to consume: ZNZ_BITS*NUM_GROUP
// 1. znz_din: the cmap data, it is organized in 16-bit group
// 2. nz_num: how many non zero bits in znz_din
// 3. enc_din: compressed weight data, would be decompressed in this module
// 4. dec_dout: decompressed weight data
////////////////////////////////////////////////////////////////////////////////
module cmap_decoder #(
   parameter CFG_M      = 8,
   parameter CFG_N      = 8,
   parameter ZNZ_BITS   = 16,
   parameter DATA_W     = 8,
   parameter NUM_GROUP  = 4,
   parameter DIN_BYTES  = NUM_GROUP * ZNZ_BITS  // CFG_M * CFG_N, // Make the input compressed data smaller
) (
   input logic                                     clk,
   input logic                                     rst_n,
   input logic                                     enable,

   input logic [NUM_GROUP-1:0][ZNZ_BITS-1:0]       znz_din,
   input logic                                     znz_vld,
   output logic                                    znz_rdy,
   input logic [NUM_GROUP-1:0][$clog2(ZNZ_BITS):0] nz_num,
   output logic                                    nz_rdy,
  

   input logic [DIN_BYTES-1:0][DATA_W-1:0]         enc_din, 
   input logic                                     enc_vld,
   output logic                                    enc_rdy,

   output logic [DIN_BYTES-1:0][DATA_W-1:0]        dec_dout,
   output logic                                    dec_vld,
   input logic                                     dec_rdy
);

typedef enum logic [2:0] {  
   IDLE,
   FILL, 
   FULL,
   WAIT_ENCODE_DATA,
   DECODE
} state_t;

state_t state_d, state_q;
genvar n, m, k;


////////////////////////////////////////////////////////////////////////////////
// Cycle0         1                    2
// enc_data_d     kernel_enc_din_d     kernel_dec_dout
////////////////////////////////////////////////////////////////////////////////
// Re-org the enc_din data
logic [DIN_BYTES-1:0]   enc_din_reorg     [DATA_W-1:0];

logic [NUM_GROUP-1:0][ZNZ_BITS-1:0] znz_data_d, znz_data_q1,   znz_data_q2;

// The end index of n-th group of NZ data
logic [NUM_GROUP-1:0][$clog2(ZNZ_BITS*NUM_GROUP):0]   nz_cnt;
logic [NUM_GROUP-1:0][$clog2(ZNZ_BITS*NUM_GROUP):0]   nz_cnt_d,   nz_cnt_q;

 // if less than NUM_GROUP*ZNZ_BITS NZ data in shift reg, must read new data
localparam  SREG_SIZE = DIN_BYTES*2;   // + NUM_GROUP*ZNZ_BITS;    
logic [SREG_SIZE-1:0][DATA_W-1:0]   sreg_data_d,   sreg_data_q;
logic [$clog2(SREG_SIZE) : 0]       sreg_cnt_d,    sreg_cnt_q;
logic [SREG_SIZE-1:0]               sreg_data_d_reorg [DATA_W-1:0];
logic [SREG_SIZE-1:0]               sreg_data_q_reorg [DATA_W-1:0];


logic dec_vld_d,  dec_vld_q1, dec_vld_q2;

// The signals to the kernel
// Re-orged data before sent to kernel_enc_din
logic [DIN_BYTES-1:0]   enc_data_reorg_d  [DATA_W-1:0];
logic [DIN_BYTES-1:0]   enc_data_reorg_q  [DATA_W-1:0];

logic [ZNZ_BITS-1:0][DATA_W-1:0] kernel_enc_din_d  [NUM_GROUP-1:0],
                                 kernel_enc_din_q  [NUM_GROUP-1:0];
logic [ZNZ_BITS-1:0][DATA_W-1:0] kernel_dec_dout   [NUM_GROUP-1:0];
logic [ZNZ_BITS-1:0]             kernel_enc_din_d_reorg  [NUM_GROUP-1:0][DATA_W-1:0];

 // The total number of nonzero data in first n groups, used for index
assign nz_cnt[0] = nz_num[0];
generate
   for (n=1; n<NUM_GROUP; n++) begin
      assign nz_cnt[n] = nz_cnt[n-1] + nz_num[n];
   end
endgenerate

generate
   for (n=0; n<DATA_W; n++) begin
      for (m=0; m<DIN_BYTES; m++) begin
         assign enc_din_reorg[n][m]  = enc_din[m][n];
      end
   end

   for (n=0; n<DATA_W; n++) begin
      for (m=0; m<SREG_SIZE; m++) begin
         assign sreg_data_q_reorg[n][m]  = sreg_data_q[m][n];
      end
   end

   for (n=0; n<DATA_W; n++) begin
      for (m=0; m<SREG_SIZE; m++) begin
         assign sreg_data_d[m][n]   = sreg_data_d_reorg[n][m];
      end
   end

   for (k=0; k<NUM_GROUP; k++) begin
      for (n=0; n<DATA_W; n++) begin
         for (m=0; m<ZNZ_BITS; m++) begin
            assign kernel_enc_din_d[k][m][n] = kernel_enc_din_d_reorg[k][n][m];
         end
      end
   end   
endgenerate

always_ff @( posedge clk or negedge rst_n ) begin : block_ff
   if (rst_n == 0) begin
      state_q     <= FILL;
      sreg_data_q <= '0;
      sreg_cnt_q  <= '0;

      znz_data_q1 <= '0;
      znz_data_q2 <= '0;
      nz_cnt_q    <= '0;

      dec_vld_q1  <= 0;
      dec_vld_q2  <= 0;

      for (int i=0; i<DATA_W; i++) begin
         enc_data_reorg_q[i]  <= '0;
      end

      for (int i=0; i<NUM_GROUP; i++) begin
         kernel_enc_din_q[i]  <= 0;
      end
   end else begin
      state_q     <= state_d;
      sreg_data_q <= sreg_data_d;
      sreg_cnt_q  <= sreg_cnt_d;

      znz_data_q1 <= znz_data_d;
      znz_data_q2 <= znz_data_q1;
      nz_cnt_q    <= nz_cnt_d;

      dec_vld_q1  <= dec_vld_d;
      dec_vld_q2  <= dec_vld_q1;

      for (int i=0; i<DATA_W; i++) begin
         enc_data_reorg_q[i]  <= enc_data_reorg_d[i];
      end

      for (int i=0; i<NUM_GROUP; i++) begin
         kernel_enc_din_q[i]  <= kernel_enc_din_d[i];
      end
   end
end

assign nz_rdy  = znz_rdy;

always_comb begin : block_comb
   state_d  = state_q;
   znz_rdy  = 0;
   enc_rdy  = 0;

   sreg_cnt_d  = sreg_cnt_q;
   for (int i=0; i<DATA_W; i++) begin
      sreg_data_d_reorg[i] = '0;
      enc_data_reorg_d[i]  = '0;
   end

   znz_data_d  = znz_din;
   nz_cnt_d    = nz_cnt;

   dec_vld_d   = 0;

   case (state_q)
      FILL: begin
         znz_rdy  = 1;
         enc_rdy  = 1;

         if(znz_vld && enc_vld) begin 
            if ( sreg_cnt_q < nz_cnt[NUM_GROUP-1] ) begin
               /*
               for (int i=0; i<SREG_SIZE-(nz_cnt[NUM_GROUP-1]-sreg_cnt_q); i++) begin
                  sreg_data_d[i] = enc_din[i + nz_cnt[NUM_GROUP-1]-sreg_cnt_q];
               end

               for (int i=0; i<sreg_cnt_q; i++) begin
                  enc_data_d[i]  = sreg_data_q[i];
               end
               for (int i=0; i<DIN_BYTES-sreg_cnt_q; i++) begin
                  enc_data_d[i+sreg_cnt_q]  = enc_din[i];
               end
               */

               for (int i=0; i<DATA_W; i++) begin
                  sreg_data_d_reorg[i] = enc_din_reorg[i] >> (nz_cnt[NUM_GROUP-1]-sreg_cnt_q);
                  enc_data_reorg_d[i]  = sreg_data_q_reorg[i] | (enc_din_reorg[i] << sreg_cnt_q);
               end

               sreg_cnt_d  = sreg_cnt_q + DIN_BYTES - nz_cnt[NUM_GROUP-1];
            end else if ( sreg_cnt_q == nz_cnt[NUM_GROUP-1] ) begin
               // sreg_data_d = enc_din;
               // enc_data_d  = sreg_data_q;

               for (int i=0; i<DATA_W; i++) begin
                  sreg_data_d_reorg[i] = enc_din_reorg[i];
                  enc_data_reorg_d[i]  = sreg_data_q_reorg[i];
               end

               sreg_cnt_d  = DIN_BYTES;
            end else begin
               /*
               for (int i=0; i<DIN_BYTES; i++) begin
                  enc_data_d[i]  = sreg_data_q[i];
               end

               for (int i=0; i<(sreg_cnt_q-nz_cnt[NUM_GROUP-1]); i++) begin
                  sreg_data_d[i] = sreg_data_q[nz_cnt[NUM_GROUP-1]+i];
               end
               for (int i=0; i<DIN_BYTES; i++) begin
                  sreg_data_d[sreg_cnt_q - nz_cnt[NUM_GROUP-1] + i] = enc_din[i];
               end
               */

               for (int i=0; i<DATA_W; i++) begin
                  sreg_data_d_reorg[i] = (sreg_data_q_reorg[i] >> nz_cnt[NUM_GROUP-1]) | (enc_din_reorg[i] << (sreg_cnt_q - nz_cnt[NUM_GROUP-1]) );
                  enc_data_reorg_d[i]  = sreg_data_q_reorg[i];
               end

               sreg_cnt_d  = sreg_cnt_q + DIN_BYTES - nz_cnt[NUM_GROUP-1];
            end

            dec_vld_d   = 1;
            if(sreg_cnt_d < NUM_GROUP*ZNZ_BITS) begin
               state_d  = FILL;
            end else begin
               state_d  = FULL;
            end
         end
      end

      FULL: begin
         znz_rdy  = 1;
         enc_rdy  = 0;

         if(znz_vld) begin
            /*
            for (int i=0; i<sreg_cnt_q - nz_cnt[NUM_GROUP-1]; i++) begin
               sreg_data_d[i]  = sreg_data_q[i+nz_cnt[NUM_GROUP-1]];
            end
            for (int i=0; i<DIN_BYTES; i++) begin
               enc_data_d[i]  = sreg_data_q[i];
            end
            */

            for (int i=0; i<DATA_W; i++) begin
               sreg_data_d_reorg[i] = (sreg_data_q_reorg[i] >> nz_cnt[NUM_GROUP-1]);
               enc_data_reorg_d[i]  = sreg_data_q_reorg[i];
            end

            sreg_cnt_d = sreg_cnt_q - nz_cnt[NUM_GROUP-1];

            dec_vld_d   = 1;
            if(sreg_cnt_d < NUM_GROUP*ZNZ_BITS) begin
               state_d  = FILL;
            end else begin
               state_d  = FULL;
            end
         end
      end
   endcase
end

/*
always_comb begin
   kernel_enc_din_d[0] = enc_data_q[ZNZ_BITS-1:0];

   for (int i=1; i<NUM_GROUP; i++) begin
      kernel_enc_din_d[i] = enc_data_q >> (nz_cnt_q[i-1] * DATA_W);
   end
end
*/
always_comb begin
   for (int j=0; j<DATA_W; j++) begin
      kernel_enc_din_d_reorg[0][j] = enc_data_reorg_q[j];
   end

   for (int i=1; i<NUM_GROUP; i++) begin
      for (int j=0; j<DATA_W; j++) begin
         kernel_enc_din_d_reorg[i][j] = enc_data_reorg_q[j] >> nz_cnt_q[i-1];
      end
   end
end

generate
   for (n=0; n<NUM_GROUP; n++) begin
      cmap_kernel #(
         .ZNZ_BITS   ( ZNZ_BITS  ),
         .DATA_W     ( DATA_W    )
      ) cmap_kernel_i (
         .znz_din    ( znz_data_q2[n]        ),
         .enc_din    ( kernel_enc_din_q[n]   ),
         .dec_dout   ( kernel_dec_dout[n]    )
      );
   end
endgenerate

generate
   for (n=0; n<NUM_GROUP; n++) begin
      assign dec_dout[n*ZNZ_BITS +: ZNZ_BITS] = kernel_dec_dout[n];
   end
endgenerate
assign dec_vld = dec_vld_q2;

endmodule