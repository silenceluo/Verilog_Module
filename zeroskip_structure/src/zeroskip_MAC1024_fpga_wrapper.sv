
module zeroskip_MAC1024_fpga_wrapper #(
   parameter M             = 32,
   parameter N             = 32,
   parameter DATA_W        = 8,

   parameter GROUP_NUM     = M,    //  GROUP_NUM should be simply M, parameterized for DV
   parameter GROUP_SIZE    = 32,   //  Group size
   parameter LOWER         = 20,
   parameter UPPER         = GROUP_SIZE - LOWER,
   parameter GROUP_NZ_MAX  = 16,

   parameter ROWS          = M
) (
   input logic                      clk,
   input logic                      a_rst_n,
   input logic                      enable,
   input logic                      group_nz_sel,  // 0--8:32, 1--8:16

   input logic [M-1:0]              fpga_znz_din,        // [M*2-1:0][M-1:0] 
   input logic                      fpga_znz_din_vld_i,
   output logic                     fpga_znz_din_rdy_o,

   input logic [DATA_W-1:0]         fpga_act_din,        // [M*2-1:0][DATA_W-1:0] 
   input logic                      fpga_act_din_vld_i,
   output logic                     fpga_act_din_rdy_o,

   output logic [M-1:0][DATA_W-1:0] fpga_act_enc_dout,   // [M-1:0][M-1:0][DATA_W-1:0]
   output logic                     fpga_act_enc_vld_o,
   input logic                      fpga_act_enc_rdy_i
);

logic [M*2-1:0][M-1:0]           znz_din;
logic                            znz_din_vld_i;
logic                            znz_din_rdy_o;

logic [M*2-1:0][DATA_W-1:0]      act_din;
logic                            act_din_vld_i;
logic                            act_din_rdy_o;

logic [M-1:0][M-1:0][DATA_W-1:0] act_enc_dout;
logic                            act_enc_vld_o;
logic                            act_enc_rdy_i;

bridge_combine #(
   .DIN_W   ( 1   ),
   .DOUT_W  ( M*2 ),
   .DATA_W  ( M   ),
   .BIG_EN  ( 1   )
) bridge_combine_znz_i (    
   .clk     ( clk       ),
   .rst_n   ( a_rst_n   ),

   .vld_i   ( fpga_znz_din_vld_i ),
   .din     ( fpga_znz_din       ),
   .last_i  ( 1'b0               ),
   .rdy_o   ( fpga_znz_din_rdy_o ),

   .vld_o   ( znz_din_vld_i   ),
   .dout    ( znz_din         ),
   .last_o  (                 ),
   .rdy_i   ( znz_din_rdy_o   )
);

bridge_combine #(
   .DIN_W   ( 1      ),
   .DOUT_W  ( M*2    ),
   .DATA_W  ( DATA_W ),
   .BIG_EN  ( 1      )
) bridge_combine_act_i (    
   .clk     ( clk       ),
   .rst_n   ( a_rst_n   ),

   .vld_i   ( fpga_act_din_vld_i ),
   .din     ( fpga_act_din       ),
   .last_i  ( 1'b0               ),
   .rdy_o   ( fpga_act_din_rdy_o ),

   .vld_o   ( act_din_vld_i   ),
   .dout    ( act_din         ),
   .last_o  (                 ),
   .rdy_i   ( act_din_rdy_o   )
);


zeroskip_pipe_wrapper_MAC1024 #(
   .M             ( M      ),
   .N             ( N      ),
   .DATA_W        ( DATA_W )
) zeroskip_MAC_wrapper_i (
   .clk           ( clk       ),
   .a_rst_n       ( a_rst_n   ),
   .enable        ( enable    ),
   .group_nz_sel  ( group_nz_sel    ),

   .znz_din       ( znz_din         ),
   .znz_din_vld_i ( znz_din_vld_i   ),
   .znz_din_rdy_o ( znz_din_rdy_o   ),

   .act_din       ( act_din         ),
   .act_din_vld_i ( act_din_vld_i   ),
   .act_din_rdy_o ( act_din_rdy_o   ),

   .act_enc_dout  ( act_enc_dout    ),
   .act_enc_vld_o ( act_enc_vld_o   ),
   .act_enc_rdy_i ( act_enc_rdy_i   )
);


bridge_split #(
   .DIN_W   ( M*M    ),
   .DOUT_W  ( M      ),
   .DATA_W  ( DATA_W )
) bridge_split_out_i (    
   .clk     ( clk       ),
   .rst_n   ( a_rst_n   ),

   .vld_i   ( act_enc_vld_o   ),
   .din     ( act_enc_dout    ),
   .last_i  ( 0               ),
   .rdy_o   ( act_enc_rdy_i   ),

   .vld_o   ( fpga_act_enc_vld_o ),
   .dout    ( fpga_act_enc_dout  ),
   .last_o  (                    ),
   .rdy_i   ( fpga_act_enc_rdy_i )
);

endmodule
