////////////////////////////////////////////////////////////////////////////////
//  This is a zero skip controller for MAC256. We will have one controller for 
//  Each MAC, this one is for test
//  MAC1024,    M=N=32,     16:32,  GROUP_SIZE=32,  one cyle, two encoder
//                          8:32,   GROUP_SIZE=32,  two cycle, two encoder
////////////////////////////////////////////////////////////////////////////////
module zeroskip_row_MAC1024 #(
    parameter M         = 32,
    parameter N         = 32,
    parameter DATA_W    = 8,

    parameter DIN_W     = M*2   //  Both ZNZ and ACT are 64 Bytes for MAC1024
) (
    input logic                             clk,
    input logic                             rst_n,
    input logic                             group_nz_sel,   //  0--8:32, 1--8:16

    input logic [DIN_W-1:0]                 znz_din,
    input logic                             znz_din_vld_i,
    output logic                            znz_din_rdy_o,

    input logic [DIN_W-1:0][DATA_W-1:0]     act_din,
    input logic                             act_din_vld_i,
    output logic                            act_din_rdy_o,

    output logic [M-1:0][DATA_W-1:0]        act_enc_dout,
    output logic                            act_enc_vld_o,
    input logic                             act_enc_rdy_i
);

localparam GROUP_SIZE_HALF      = 32;           //  16:32
localparam NZ_HALF              = 16;
localparam TWO_NZ_HALF          = NZ_HALF * 2;  //  32

localparam GROUP_SIZE_QUAR      = 32;           //  8:32
localparam NZ_QUAR              = 8;
localparam TWO_NZ_QUAR          = NZ_QUAR * 2;  //  16

localparam GROUP_NZ_MAX         = (NZ_HALF > NZ_QUAR) ? NZ_HALF : NZ_QUAR;
localparam GROUP_SIZE_MAX       = (GROUP_SIZE_HALF > GROUP_SIZE_QUAR) ? GROUP_SIZE_HALF : GROUP_SIZE_QUAR;


////////////////////////////////////////////////////////////////////////////////
//  Read the act/znz fifo, run zero skipping algorithm, FIFO the results
////////////////////////////////////////////////////////////////////////////////
logic                                       enc_fifo_clear;
logic                                       enc_fifo_wen;
logic [1:0][GROUP_NZ_MAX-1:0][DATA_W-1:0]   enc_fifo_din;
logic                                       enc_fifo_rdy_o;
logic                                       enc_fifo_ren;
logic [1:0][GROUP_NZ_MAX-1:0][DATA_W-1:0]   enc_fifo_dout;
logic                                       enc_fifo_vld_o;

assign enc_fifo_clear = 1'b0;


zeroskip #(
    .GROUP_SIZE     ( GROUP_SIZE_MAX    ),
    .GROUP_NZ_MAX   ( GROUP_NZ_MAX      ),
    .DATA_W         ( DATA_W            )
) zeroskip_high (
    .znz_din        ( znz_din[DIN_W-1 : M]  ),
    .act_din        ( act_din[DIN_W-1 : M]  ),
    .act_enc_dout   ( enc_fifo_din[1]       )
);

zeroskip #(
    .GROUP_SIZE     ( GROUP_SIZE_MAX    ),
    .GROUP_NZ_MAX   ( GROUP_NZ_MAX      ),
    .DATA_W         ( DATA_W            )
) zeroskip_low (
    .znz_din        ( znz_din[M-1 : 0]  ),
    .act_din        ( act_din[M-1 : 0]  ),
    .act_enc_dout   ( enc_fifo_din[0]   )
);


always_comb begin
    znz_din_rdy_o   = 0;
    act_din_rdy_o   = 0;
    enc_fifo_wen    = 1'b0;    
    if( (znz_din_vld_i==1) && (act_din_vld_i==1) && (enc_fifo_rdy_o==1) ) begin
        znz_din_rdy_o   = 1;
        act_din_rdy_o   = 1;
        enc_fifo_wen    = 1'b1;
    end
end


fifo_slice #(
    .t  ( logic [1:0][GROUP_NZ_MAX-1:0][DATA_W-1:0] )
) act_dout_fifo_u(
    .clk_i      ( clk   ),
    .rst_ni     ( rst_n ),
    .clear_i    ( enc_fifo_clear    ),

    .vld_i      ( enc_fifo_wen      ),
    .din_i      ( enc_fifo_din      ),    
    .rdy_o      ( enc_fifo_rdy_o    ),
    
    .rdy_i      ( enc_fifo_ren      ),
    .dout_o     ( enc_fifo_dout     ),
    .vld_o      ( enc_fifo_vld_o    )
);


////////////////////////////////////////////////////////////////////////////////
//  Output stage:
//  16:32,  two encoder combined, Output to M=32 port directly
//  8:32,   two encoder combined, Output to a bridge to combine 16B to 32B
////////////////////////////////////////////////////////////////////////////////
logic                                   half_enc_fifo_clear; 
logic [TWO_NZ_HALF-1:0][DATA_W-1:0]     half_enc_fifo_din;
logic                                   half_enc_fifo_wen;
logic                                   half_enc_fifo_rdy_o;
logic [M-1:0][DATA_W-1:0]               half_enc_fifo_dout;
logic                                   half_enc_fifo_ren;
logic                                   half_enc_fifo_vld_o;

//  Two cycles, 16:32 bridge for QUAR
logic                                   quar_enc_fifo_clear; 
logic [TWO_NZ_QUAR-1:0][DATA_W-1:0]     quar_enc_fifo_din;
logic                                   quar_enc_fifo_wen;
logic                                   quar_enc_fifo_rdy_o;
logic [M-1:0][DATA_W-1:0]               quar_enc_fifo_dout;
logic                                   quar_enc_fifo_ren;
logic                                   quar_enc_fifo_vld_o;

always_comb begin
    half_enc_fifo_clear = 1'b0;
    quar_enc_fifo_clear = 1'b0;

    half_enc_fifo_din   = '0;
    half_enc_fifo_wen   = 1'b0;
    quar_enc_fifo_din   = '0;
    quar_enc_fifo_wen   = 1'b0;

    if(group_nz_sel == 0) begin //  0--8:32
        enc_fifo_ren        = quar_enc_fifo_rdy_o;
        quar_enc_fifo_din   = { enc_fifo_dout[1][NZ_QUAR-1:0], enc_fifo_dout[0][NZ_QUAR-1:0] };
        quar_enc_fifo_wen   = enc_fifo_vld_o;        
    end else begin              //  1--16:32
        enc_fifo_ren        = half_enc_fifo_rdy_o;
        half_enc_fifo_din   = { enc_fifo_dout[1][NZ_HALF-1:0], enc_fifo_dout[0][NZ_HALF-1:0] };
        half_enc_fifo_wen   = enc_fifo_vld_o;
    end
end

//  16:32,  direct out
always_comb begin
    half_enc_fifo_dout  = half_enc_fifo_din;
    half_enc_fifo_vld_o = half_enc_fifo_wen;
    half_enc_fifo_rdy_o = half_enc_fifo_ren;
end

//  8:32,   16-->16 bridge
bridge_combine #(
    .DIN_W  ( TWO_NZ_QUAR   ),
    .DOUT_W ( M             ),
    .DATA_W ( DATA_W        ),
    .BIG_EN ( 1 )
) bridge_combine_enc_quar (    
    .clk    ( clk   ),
    .rst_n  ( rst_n ),

    .vld_i  ( quar_enc_fifo_wen     ),
    .din    ( quar_enc_fifo_din     ),
    .last_i ( 1'b0                  ),
    .rdy_o  ( quar_enc_fifo_rdy_o   ),

    .vld_o  ( quar_enc_fifo_vld_o   ),
    .dout   ( quar_enc_fifo_dout    ),
    .last_o (                       ),
    .rdy_i  ( quar_enc_fifo_ren     ) 
);


always_comb begin
    quar_enc_fifo_ren   = 1'b0;
    half_enc_fifo_ren   = 1'b0;

    if(group_nz_sel == 0) begin //  0--8:32
        act_enc_dout        = quar_enc_fifo_dout[M-1 : 0];
        act_enc_vld_o       = quar_enc_fifo_vld_o;    
        quar_enc_fifo_ren   = act_enc_rdy_i;
    end else begin              //  1--16:32
        act_enc_dout        = half_enc_fifo_dout[M-1 : 0];
        act_enc_vld_o       = half_enc_fifo_vld_o;  
        half_enc_fifo_ren   = act_enc_rdy_i;
    end
end


endmodule