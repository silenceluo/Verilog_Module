module znz_decoder_wrapper #(
    parameter ZNZ_BITS  = 128,
    parameter DATA_W    = 8,
    parameter DIN_BYTES = ZNZ_BITS
) (
    input logic                             clk,
    input logic                             rst_n,

    input logic [ZNZ_BITS-1:0]              znz_din,
    input logic                             znz_vld,
    output logic                            znz_rdy,

    input logic [DIN_BYTES*DATA_W-1:0]      encode_din,
    input logic                             encode_vld,
    output logic                            encode_rdy,

    output logic [ZNZ_BITS*DATA_W-1:0]      decode_dout,
    output logic                            decode_vld,
    input logic                             decode_rdy
);


localparam ZNZ_FIFO_DEPTH = 2;
localparam ENC_FIFO_DEPTH = 2;
logic [$clog2(ZNZ_FIFO_DEPTH):0]    znz_fifo_count;
logic [$clog2(ENC_FIFO_DEPTH):0]    enc_fifo_count;

logic [ZNZ_BITS-1:0]            znz_fifo_din;
logic                           znz_fifo_wen;
logic                           znz_fifo_full;
logic                           znz_fifo_afull;

logic [ZNZ_BITS-1:0]            znz_fifo_dout;
logic                           znz_fifo_ren;
logic                           znz_fifo_empty;

logic [DIN_BYTES*DATA_W-1:0]    encode_fifo_din;
logic                           encode_fifo_wen;
logic                           encode_fifo_full;
logic                           encode_fifo_afull;

logic [DIN_BYTES*DATA_W-1:0]    encode_fifo_dout;
logic                           encode_fifo_ren;
logic                           encode_fifo_empty;

always_comb begin
    znz_fifo_din    = znz_din;
    znz_fifo_wen    = znz_vld;
    znz_rdy         = ~znz_fifo_full;

    encode_fifo_din = encode_din;
    encode_fifo_wen = encode_vld;
    encode_rdy      = ~encode_fifo_full;
end

generic_sync_fifo #(    
    .DTYPE      ( logic[ZNZ_BITS-1 : 0] ),
    .FIFO_DEPTH ( ZNZ_FIFO_DEPTH        ),
    .THRESHOLD  ( 2     )
) znz_fifo_u (  
    .clk        ( clk   ),
    .rst_n      ( rst_n ),
    .clear      ( 1'b0  ),
    
    .wen        ( znz_fifo_wen      ),
    .wdata      ( znz_fifo_din      ),    
    .full       ( znz_fifo_full     ),
    .afull      ( znz_fifo_afull    ),

    .ren        ( znz_fifo_ren      ),
    .rdata      ( znz_fifo_dout     ),
    .empty      ( znz_fifo_empty    ),

    .count      ( znz_fifo_count    )
);

generic_sync_fifo #(    
    .DTYPE      ( logic[DIN_BYTES*DATA_W-1 : 0] ),
    .FIFO_DEPTH ( ENC_FIFO_DEPTH                ),
    .THRESHOLD  ( 2     )
) encode_fifo_u (  
    .clk        ( clk   ),
    .rst_n      ( rst_n ),
    .clear      ( 1'b0  ),

    .wen        ( encode_fifo_wen   ),
    .wdata      ( encode_fifo_din   ),    
    .full       ( encode_fifo_full  ),
    .afull      ( encode_fifo_afull ),

    .ren        ( encode_fifo_ren   ),
    .rdata      ( encode_fifo_dout  ),
    .empty      ( encode_fifo_empty ),

    .count      ( enc_fifo_count    )
);

logic [DIN_BYTES-1:0][DATA_W-1:0]   nzd_din;
logic [ZNZ_BITS-1:0][DATA_W-1:0]    dec_data;

genvar  i;
generate
    for (i = 0; i < DIN_BYTES; i = i + 1) begin
        assign nzd_din[i]  = encode_fifo_dout[ (i+1)*DATA_W-1 : i*DATA_W ];
    end

    for (i = 0; i < ZNZ_BITS; i = i + 1) begin
        assign decode_dout[ (i+1)*DATA_W-1 : i*DATA_W ] = dec_data[i];
    end    
endgenerate

znz_decoder #(
    .ZNZ_BITS   ( ZNZ_BITS  ),
    .DATA_W     ( DATA_W    )
) znz_decoder_i (
    .clk        ( clk   ),
    .rst_n      ( rst_n ),

    .znz_din    ( znz_fifo_dout     ),
    .znz_vld    ( ~znz_fifo_empty   ),
    .znz_rdy    ( znz_fifo_ren      ),

    .enc_din    ( nzd_din               ),
    .enc_vld    ( ~encode_fifo_empty    ),
    .enc_rdy    ( encode_fifo_ren       ),

    .dec_dout   ( dec_data      ),
    .dec_vld    ( decode_vld    ),
    .dec_rdy    ( decode_rdy    )
);

endmodule