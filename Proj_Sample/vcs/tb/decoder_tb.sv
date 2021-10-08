// `timescale 1ps/1fs

module decoder_tb;
//timeunit      1ns;
//timeprecision 1ps;

import hs_drv_pkg::*;


localparam int unsigned MIN_IN_WAIT_CYCLES = 0;
localparam int unsigned MAX_IN_WAIT_CYCLES = 0;
localparam int unsigned MIN_OUT_WAIT_CYCLES = 0;
localparam int unsigned MAX_OUT_WAIT_CYCLES = 0;

localparam time         CLK_PERIOD = 1.8ns;
localparam time         RST_TIME = 10*CLK_PERIOD;
localparam time         TA = 0.2*CLK_PERIOD;
localparam time         TT = 0.85*CLK_PERIOD;

logic                   clk;
logic                   rst_n;

parameter int   CFG_M       = 8;
parameter int   CFG_N       = 8;
parameter int   DATA_W      = 8;
parameter int   ZNZ_BITS    = 16;
parameter int   NUM_GROUP   = 4;    //4
parameter int   DIN_BYTES   = ZNZ_BITS * NUM_GROUP;// CFG_M * CFG_N;

parameter int   ENCODE_DATA_W   = DIN_BYTES * DATA_W;
parameter int   ZNZ_DATA_W      = NUM_GROUP * ZNZ_BITS;
parameter int   NZ_CNT_W        = NUM_GROUP * ($clog2(ZNZ_BITS) + 1);
parameter int   DECODE_DATA_W   = DIN_BYTES * DATA_W;

HandshakeIf_t #(
    .DATA_W ( ZNZ_DATA_W    )
) znz_if    ( .clk_i(clk)   );

HandshakeIf_t #(
    .DATA_W ( NZ_CNT_W      )
) nz_num_if ( .clk_i(clk)   );

HandshakeIf_t #(
    .DATA_W ( ENCODE_DATA_W )
) encode_if ( .clk_i(clk)   );

HandshakeIf_t #(
    .DATA_W ( DECODE_DATA_W )
) decode_if ( .clk_i(clk)   );


HandshakeDrv #(
    .DATA_W     ( DATA_W    ),
    .NUM_BYTE   ( DIN_BYTES ),

    .TA         ( TA            ),
    .TT         ( TT            ),
    .MIN_WAIT   ( MIN_IN_WAIT_CYCLES),
    .MAX_WAIT   ( MAX_IN_WAIT_CYCLES),
    .HAS_LAST   ( 1'b1              ),
    .NAME       ( "NZ Data Input"   )
) encode_drv;

HandshakeDrv #(
    .DATA_W     ( DATA_W            ),
    .NUM_BYTE   ( ZNZ_DATA_W/DATA_W ),

    .TA         ( TA        ),
    .TT         ( TT        ),
    .MIN_WAIT   ( MIN_OUT_WAIT_CYCLES),
    .MAX_WAIT   ( MAX_OUT_WAIT_CYCLES),
    .HAS_LAST   ( 1'b1          ),
    .NAME       ( "ZNZ Input"   )
) znz_drv;

HandshakeDrv #(
    .DATA_W     ( $clog2(ZNZ_BITS) + 1  ),
    .NUM_BYTE   ( NUM_GROUP             ),

    .TA         ( TA        ),
    .TT         ( TT        ),
    .MIN_WAIT   ( MIN_OUT_WAIT_CYCLES),
    .MAX_WAIT   ( MAX_OUT_WAIT_CYCLES),
    .HAS_LAST   ( 1'b1          ),
    .NAME       ( "NZ Cnt Input"   )
) nz_num_drv;

HandshakeDrv #(
    .DATA_W     ( DATA_W    ),
    .NUM_BYTE   ( DIN_BYTES ),

    .TA         ( TA        ),
    .TT         ( TT        ),
    .MIN_WAIT   ( MIN_OUT_WAIT_CYCLES),
    .MAX_WAIT   ( MAX_OUT_WAIT_CYCLES),
    .HAS_LAST   ( 1'b1                  ),
    .NAME       ( "Decode data Output"  )
) decode_drv;

localparam string   ENC_STIM_FILE       = "../../PyModel/data/nz_data.txt";
localparam string   ZNZ_STIM_FILE       = "../../PyModel/data/cmap_data.txt";
localparam string   NZ_NUM_STIM_FILE    = "../../PyModel/data/nz_cnt.txt";
localparam string   DEC_EXPVAL_FILE     = "../../PyModel/data/orig_data.txt";
 
initial begin
    znz_drv = new(znz_if);
    znz_drv.reset_in();
    znz_drv.reset_out();

    nz_num_drv = new(nz_num_if);
    nz_num_drv.reset_in();
    nz_num_drv.reset_out();

    encode_drv  = new(encode_if);
    encode_drv.reset_in();
    encode_drv.reset_out();

    decode_drv = new(decode_if);
    decode_drv.reset_in();
    decode_drv.reset_out();

    #(2*RST_TIME);
    fork
        encode_drv.feed_inputs  ( ENC_STIM_FILE     );
        znz_drv.feed_inputs     ( ZNZ_STIM_FILE     );
        nz_num_drv.feed_inputs  ( NZ_NUM_STIM_FILE  );
        decode_drv.read_outputs ( DEC_EXPVAL_FILE   );
    join
    $stop;
end

rst_clk_drv #(
    .CLK_PERIOD ( CLK_PERIOD    ),
    .RST_TIME   ( RST_TIME      )
) clk_drv (
    .clk_o      ( clk           ),
    .rst_no     ( rst_n         )
);

cmap_decoder #(
    .CFG_M      ( CFG_M     ),
    .CFG_N      ( CFG_N     ),
    .ZNZ_BITS   ( ZNZ_BITS  ),
    .DATA_W     ( DATA_W    ),
    .DIN_BYTES  ( DIN_BYTES ),
    .NUM_GROUP  ( NUM_GROUP )
) cmap_decoder_i (
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .enable     ( 1         ),

    .znz_din    ( znz_if.data       ),
    .znz_vld    ( znz_if.vld        ),
    .znz_rdy    ( znz_if.rdy        ),
    .nz_num     ( nz_num_if.data    ),  //  NZ data
    .nz_rdy     ( nz_num_if.rdy     ),

    .enc_din    ( encode_if.data    ),
    .enc_vld    ( encode_if.vld     ),
    .enc_rdy    ( encode_if.rdy     ),

    .dec_dout   ( decode_if.data    ),
    .dec_vld    ( decode_if.vld     ),
    .dec_rdy    ( decode_if.rdy     )
);


initial begin
    $fsdbDumpfile("znz_decode.fsdb");
    $fsdbDumpvars();
end

endmodule
