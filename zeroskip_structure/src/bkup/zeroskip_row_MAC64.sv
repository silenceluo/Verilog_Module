////////////////////////////////////////////////////////////////////////////////
//  This is a zero skip controller for MAC64. We will have one controller for 
//  Each MAC, this one is for test
//  MAC64,  M=N=8,  8:16,   GROUP_SIZE=16
//                  8:32,   GROUP_SIZE=32
////////////////////////////////////////////////////////////////////////////////
module zeroskip_row_MAC64 #(
    parameter M             = 8,
    parameter N             = 8,
    parameter DATA_W        = 8,

    parameter DIN_W         = M*2   //  Both ZNZ and ACT are 16 Bytes for MAC64
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

localparam GROUP_SIZE_HALF      = 16;   //  8:16
localparam NZ_HALF              = 8;
localparam ACT_IN_CYCLE_HALF    = GROUP_SIZE_HALF/DIN_W;

localparam GROUP_SIZE_QUAR      = 32;   //  8:32
localparam NZ_QUAR              = 8;
localparam ACT_IN_CYCLE_QUAR    = GROUP_SIZE_QUAR/DIN_W;

localparam GROUP_NZ_MAX         = (NZ_HALF > NZ_QUAR) ? NZ_HALF : NZ_QUAR;
localparam GROUP_SIZE_MAX       = (GROUP_SIZE_HALF > GROUP_SIZE_QUAR) ? GROUP_SIZE_HALF : GROUP_SIZE_QUAR;



//  ZNZ and ENC fifo control signals
logic                                   half_znz_fifo_clear;
logic [GROUP_SIZE_HALF-1:0]             half_znz_fifo_dout;
logic                                   half_znz_fifo_ren;
logic                                   half_znz_fifo_vld_o;
logic                                   half_znz_fifo_rdy_o;

logic                                   half_act_fifo_clear; 
logic [GROUP_SIZE_HALF-1:0][DATA_W-1:0] half_act_fifo_dout;
logic                                   half_act_fifo_ren;
logic                                   half_act_fifo_vld_o;
logic                                   half_act_fifo_rdy_o;


logic                                   quar_znz_fifo_clear;
logic [GROUP_SIZE_QUAR-1:0]             quar_znz_fifo_dout;
logic                                   quar_znz_fifo_ren;
logic                                   quar_znz_fifo_vld_o;
logic                                   quar_znz_fifo_rdy_o;

logic                                   quar_act_fifo_clear; 
logic [GROUP_SIZE_QUAR-1:0][DATA_W-1:0] quar_act_fifo_dout;
logic                                   quar_act_fifo_ren;
logic                                   quar_act_fifo_vld_o;
logic                                   quar_act_fifo_rdy_o;


logic                                   enc_fifo_clear;
logic [GROUP_NZ_MAX-1:0][DATA_W-1:0]    enc_fifo_din;
logic                                   enc_fifo_wen;
logic                                   enc_fifo_rdy_o;

logic [GROUP_NZ_MAX-1:0][DATA_W-1:0]    enc_fifo_dout;
logic                                   enc_fifo_ren;
logic                                   enc_fifo_vld_o;


////////////////////////////////////////////////////////////////////////////////
//  The input stage, from M to group size
//  MAC64/256:  need a bridge to combine the 8B(16B) to 32B
//  MAC1024:    Pass the input directly to the zero skip keernel
////////////////////////////////////////////////////////////////////////////////
assign half_znz_fifo_clear  = 1'b0;
assign half_act_fifo_clear  = 1'b0;

assign quar_znz_fifo_clear  = 1'b0;
assign quar_act_fifo_clear  = 1'b0;

always_comb begin 
    //  For 8:16, no bridge needed
    half_act_fifo_dout  = act_din;
    half_act_fifo_vld_o = act_din_vld_i;
    half_act_fifo_rdy_o = half_act_fifo_ren;

    half_znz_fifo_dout  = znz_din;
    half_znz_fifo_vld_o = znz_din_vld_i;
    half_znz_fifo_rdy_o = half_znz_fifo_ren;
end

//  For 8:32, need 16:32 bridge for both znz and act input
bridge_combine #(
    .DIN_W  ( DIN_W             ),
    .DOUT_W ( GROUP_SIZE_QUAR   ),
    .DATA_W ( DATA_W            ),
    .BIG_EN ( 1                 )
) bridge_combine_act_din (    
    .clk    ( clk   ),
    .rst_n  ( rst_n ),

    .vld_i  ( act_din_vld_i ),
    .din    ( act_din       ),
    .last_i ( 1'b0          ),
    .rdy_o  ( quar_act_fifo_rdy_o   ),

    .vld_o  ( quar_act_fifo_vld_o   ),
    .dout   ( quar_act_fifo_dout    ),
    .last_o (                       ),
    .rdy_i  ( quar_act_fifo_ren     ) 
);

bridge_combine #(
    .DIN_W  ( DIN_W             ),
    .DOUT_W ( GROUP_SIZE_QUAR   ),
    .DATA_W ( 1 ),
    .BIG_EN ( 1 )
) bridge_combine_znz_din (    
    .clk    ( clk   ),
    .rst_n  ( rst_n ),

    .vld_i  ( znz_din_vld_i ),
    .din    ( znz_din       ),
    .last_i ( 1'b0          ),
    .rdy_o  ( quar_znz_fifo_rdy_o   ),

    .vld_o  ( quar_znz_fifo_vld_o   ),
    .dout   ( quar_znz_fifo_dout    ),
    .last_o (                       ),
    .rdy_i  ( quar_znz_fifo_ren     ) 
);


logic   znz_fifo_vld_o, act_fifo_vld_o;
logic   act_fifo_ren,   znz_fifo_ren;
//  Mux the signal
always_comb begin    
    quar_act_fifo_ren   = 1'b0;
    quar_znz_fifo_ren   = 1'b0;
    half_act_fifo_ren   = 1'b0;
    half_znz_fifo_ren   = 1'b0;

    if( group_nz_sel ==0 ) begin    //  8:32
        quar_act_fifo_ren   = act_fifo_ren;
        quar_znz_fifo_ren   = znz_fifo_ren;   

        znz_fifo_vld_o      = quar_znz_fifo_vld_o;
        act_fifo_vld_o      = quar_act_fifo_vld_o;

        znz_din_rdy_o       = quar_znz_fifo_rdy_o;
        act_din_rdy_o       = quar_act_fifo_rdy_o;
    end else begin                  //  16:32
        half_act_fifo_ren   = act_fifo_ren;
        half_znz_fifo_ren   = znz_fifo_ren;  

        znz_fifo_vld_o      = half_znz_fifo_vld_o;
        act_fifo_vld_o      = half_act_fifo_vld_o;

        znz_din_rdy_o       = half_znz_fifo_rdy_o;
        act_din_rdy_o       = half_act_fifo_rdy_o;
    end
end



////////////////////////////////////////////////////////////////////////////////
//  Computer stage
////////////////////////////////////////////////////////////////////////////////
logic [GROUP_SIZE_MAX-1:0]              skip_znz_din;
logic [GROUP_SIZE_MAX-1:0][DATA_W-1:0]  skip_act_din;

always_comb begin
    if( group_nz_sel ==0 ) begin    //  8:32
        skip_znz_din    = { {(GROUP_SIZE_MAX-GROUP_SIZE_QUAR){1'b0}}, quar_znz_fifo_dout };
        //  skip_act_din    = { { (GROUP_SIZE_MAX-GROUP_SIZE_QUAR) {DATA_W{1'b0}} }, quar_act_fifo_dout };
        skip_act_din    = { '0, quar_act_fifo_dout };
    end else begin                  //  16:32
        skip_znz_din    = { {(GROUP_SIZE_MAX-GROUP_SIZE_HALF){1'b0}}, half_znz_fifo_dout };
        //  skip_act_din    = { { (GROUP_SIZE_MAX-GROUP_SIZE_HALF) {DATA_W{1'b0}} }, half_act_fifo_dout };
        skip_act_din    = { '0, half_act_fifo_dout };
    end
end

zeroskip #(
    .GROUP_SIZE     ( GROUP_SIZE_MAX    ),
    .GROUP_NZ_MAX   ( GROUP_NZ_MAX      ),
    .DATA_W         ( DATA_W            )
) zeroskip_i (
    .znz_din        ( skip_znz_din  ),
    .act_din        ( skip_act_din  ),
    .act_enc_dout   ( enc_fifo_din  )
);

////////////////////////////////////////////////////////////////////////////////
//  Read the act/znz fifo, run zero skipping algorithm, FIFO the results
////////////////////////////////////////////////////////////////////////////////
always_comb begin
    act_fifo_ren    = 0;
    znz_fifo_ren    = 0;
    enc_fifo_wen    = 1'b0;    
    if( (znz_fifo_vld_o==1) && (act_fifo_vld_o==1) && (enc_fifo_rdy_o==1) ) begin
        act_fifo_ren    = 1;
        znz_fifo_ren    = 1;
        enc_fifo_wen    = 1'b1;
    end
end


fifo_slice #(
    .t  ( logic [GROUP_NZ_MAX-1:0][DATA_W-1:0] )
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

always_comb begin
    act_enc_dout    = enc_fifo_dout[M-1 : 0];
    act_enc_vld_o   = enc_fifo_vld_o;
    enc_fifo_ren    = act_enc_rdy_i;
end

endmodule