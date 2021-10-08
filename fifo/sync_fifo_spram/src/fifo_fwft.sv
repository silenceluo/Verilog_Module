module fifo_fwft #( 
    DATA_WIDTH  = 8,
    FIFO_DEPTH  = 32,
    ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(
    input logic                     clk,
    input logic                     rst_n,
    
    input logic                     ren,
    output logic [DATA_WIDTH-1:0]   rdata, 
    output logic                    empty,
    output logic                    rvalid,
    
    input logic                     wen,
    input logic [DATA_WIDTH-1:0]    wdata,
    output logic                    full,

    
    output logic [ADDR_WIDTH-1:0]   count 
);

logic   dout_valid;
logic   fifo_rd_en;
logic   fifo_empty;

spram_fifo spram_fifo_i( 
    .clk    ( clk   ),
    .rst_n  ( rst_n ),

    .ren    ( fifo_rd_en    ),
    .rdata  ( rdata         ), 
    .empty  ( fifo_empty    ),
    .rvalid ( rvalid),

    .wen    ( wen   ),
    .wdata  ( wdata ),    
    .full   ( full  ),

    .count  ( count )
);



assign fifo_rd_en = !fifo_empty && (!dout_valid || ren);
assign empty = !dout_valid;

always @(posedge clk or negedge rst_n ) begin
    if ( rst_n ==0 ) begin
        dout_valid  <= 0;
    end else begin
        if (fifo_rd_en) begin
            dout_valid  <= 1;
        end else if (ren) begin
            dout_valid  <= 0;
        end 
    end
end

endmodule