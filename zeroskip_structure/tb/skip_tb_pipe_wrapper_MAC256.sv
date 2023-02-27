// `timescale 1ps/1fs

module decoder_tb;
//timeunit      1ns;
//timeprecision 1ps;

import hs_drv_pkg::*;


localparam int unsigned MIN_IN_WAIT_CYCLES  = 0;
localparam int unsigned MAX_IN_WAIT_CYCLES  = 0;
localparam int unsigned MIN_OUT_WAIT_CYCLES = 0;
localparam int unsigned MAX_OUT_WAIT_CYCLES = 0;

localparam time         CLK_PERIOD = 1.8ns;
localparam time         RST_TIME = 10*CLK_PERIOD;
localparam time         TA = 0.2*CLK_PERIOD;
localparam time         TT = 0.85*CLK_PERIOD;

logic                   clk;
logic                   rst_n;
logic                   sel_8to32_16to32;

/*
////////////////////////////////////////////////////////////////////////////////
//  MAC64
////////////////////////////////////////////////////////////////////////////////
parameter int   M       = 8;
parameter int   N       = 8;
parameter int   DATA_W  = 8;

parameter int   GROUP_SIZE      = 16;   // 8:32, 8:16
parameter int   GROUP_NZ_BITS   = 8;
parameter int   ZNZ_BITS        = GROUP_SIZE;
parameter int   ROWS            = 8;    // ROWS = M for matrix

assign  sel_8to32_16to32        = (GROUP_SIZE==16);


parameter string ZNZ_STIM_FILE  = (GROUP_SIZE == 32) ?  "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/4-16/znz_data/0.txt.znz" : 
                                                        "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/2-4/zeroskip_MAC64/znz.txt";

parameter string ACT_STIM_FILE  = (GROUP_SIZE == 32) ?  "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/4-16/act/act.txt" : 
                                                        "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/2-4/zeroskip_MAC64/act.txt";        

parameter string ENC_EXPVAL_FILE = (GROUP_SIZE == 32) ? "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/4-16/zeroskip/skip.txt" : 
                                                        "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/2-4/zeroskip_MAC64/skip.txt";     
*/


////////////////////////////////////////////////////////////////////////////////
//  MAC256
////////////////////////////////////////////////////////////////////////////////
parameter int   M       = 16;
parameter int   N       = 16;
parameter int   DATA_W  = 8;

parameter int   GROUP_SIZE      = 16;
parameter int   GROUP_NZ_BITS   = 4;    // 8:16, 4:16
parameter int   ZNZ_BITS        = GROUP_SIZE;
parameter int   ROWS            = M;    // ROWS = M for matrix

assign  sel_8to32_16to32        = (GROUP_NZ_BITS==8);

parameter string ZNZ_STIM_FILE  = (GROUP_NZ_BITS == 4) ? 
    "../../PyModel/0.25/nna256/znz.txt" : 
    "../../PyModel/0.50/nna256/znz.txt" ;

parameter string ACT_STIM_FILE  = (GROUP_NZ_BITS == 4) ? 
    "../../PyModel/0.25/nna256/act.txt" : 
    "../../PyModel/0.50/nna256/act.txt";

parameter string ENC_EXPVAL_FILE  = (GROUP_NZ_BITS == 4) ? 
    "../../PyModel/0.25/nna256/act_skip.txt" : 
    "../../PyModel/0.50/nna256/act_skip.txt";

/*
////////////////////////////////////////////////////////////////////////////////
//  MAC1024
////////////////////////////////////////////////////////////////////////////////
parameter int   M       = 32;
parameter int   N       = 32;
parameter int   DATA_W  = 8;

parameter int   GROUP_SIZE      = 32;
parameter int   GROUP_NZ_BITS   = 16;    // 8:32, 16:32
parameter int   ZNZ_BITS        = GROUP_SIZE;
parameter int   ROWS            = 2;    // ROWS = M for matrix

assign  sel_8to32_16to32        = (GROUP_NZ_BITS==16);


parameter string ZNZ_STIM_FILE  = (GROUP_NZ_BITS == 8) ?    "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/4-16/znz_data/0.txt.znz" : 
                                                            "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/2-4/zeroskip_MAC1024/znz.txt";

parameter string ACT_STIM_FILE  = (GROUP_NZ_BITS == 8) ?    "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/4-16/act/act.txt" : 
                                                            "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/2-4/zeroskip_MAC1024/act.txt";        

parameter string ENC_EXPVAL_FILE = (GROUP_NZ_BITS == 8) ?   "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/4-16/zeroskip/skip.txt" : 
                                                            "/data/home/luopl/Proj/cmap/skip_20210225/PyModel/2-4/zeroskip_MAC1024/skip.txt";     
*/




parameter int   ZNZ_DATA_W  = 2*M*ROWS;
parameter int   ACT_DATA_W  = 2*M*DATA_W;
parameter int   ENC_DATA_W  = M*DATA_W*ROWS;


HandshakeIf_t #(
    .DATA_W     ( ACT_DATA_W    )
) act_if(   .clk_i(clk) );

HandshakeIf_t #(
    .DATA_W     ( ZNZ_DATA_W    )
) znz_if(   .clk_i(clk) );

HandshakeIf_t #(
    .DATA_W     ( ENC_DATA_W    )
) enc_if(   .clk_i(clk) );


HandshakeDrv #(
    .DATA_W     ( ACT_DATA_W    ),

    .TA         ( TA            ),
    .TT         ( TT            ),
    .MIN_WAIT   ( MIN_IN_WAIT_CYCLES),
    .MAX_WAIT   ( MAX_IN_WAIT_CYCLES),
    .HAS_LAST   ( 1'b1              ),
    .NAME       ( "ACT Data Input"  )
) act_drv;

HandshakeDrv #(
    .DATA_W     ( ZNZ_DATA_W    ),

    .TA         ( TA            ),
    .TT         ( TT            ),
    .MIN_WAIT   ( MIN_OUT_WAIT_CYCLES),
    .MAX_WAIT   ( MAX_OUT_WAIT_CYCLES),
    .HAS_LAST   ( 1'b1          ),
    .NAME       ( "ZNZ Input"   )
) znz_drv;

HandshakeDrv #(
    .DATA_W     ( ENC_DATA_W    ),

    .TA         ( TA            ),
    .TT         ( TT            ),
    .MIN_WAIT   ( MIN_OUT_WAIT_CYCLES),
    .MAX_WAIT   ( MAX_OUT_WAIT_CYCLES),
    .HAS_LAST   ( 1'b1                  ),
    .NAME       ( "Enc data Output"     )
) enc_drv;


initial begin
    act_drv  = new(act_if);
    act_drv.reset_out();

    znz_drv = new(znz_if);
    znz_drv.reset_out();

    enc_drv = new(enc_if);
    enc_drv.reset_in();

    #(2*RST_TIME);
    fork
        act_drv.feed_inputs(    ACT_STIM_FILE   );
        znz_drv.feed_inputs(    ZNZ_STIM_FILE   );
        enc_drv.read_outputs(   ENC_EXPVAL_FILE );
    join
end

initial begin
    #100us $finish;
end

rst_clk_drv #(
    .CLK_PERIOD ( CLK_PERIOD    ),
    .RST_TIME   ( RST_TIME      )
) clk_drv (
    .clk_o      ( clk           ),
    .rst_no     ( rst_n         )
);


zeroskip_pipe_wrapper_MAC256 #(
    .M      ( M ),
    .N      ( N ),
    .DATA_W ( DATA_W    ),
    .ROWS   ( ROWS      )
) zeroskip_MAC_wrapper_i (
    .clk            ( clk   ),
    .a_rst_n        ( rst_n ),
    .enable         ( 1'b1  ),
    .group_nz_sel   ( sel_8to32_16to32  ),

    .znz_din        ( znz_if.data   ),
    .znz_din_vld_i  ( znz_if.vld    ),
    .znz_din_rdy_o  ( znz_if.rdy    ),

    .act_din        ( act_if.data   ),
    .act_din_vld_i  ( act_if.vld    ),
    .act_din_rdy_o  ( act_if.rdy    ),

    .act_enc_dout   ( enc_if.data   ),
    .act_enc_vld_o  ( enc_if.vld    ),
    .act_enc_rdy_i  ( enc_if.rdy    )
);


initial begin
    $fsdbDumpfile("tb.fsdb");
    $fsdbDumpvars("+all");
end

endmodule
