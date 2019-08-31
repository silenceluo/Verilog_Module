module fifo_bank #( DATA_WIDTH  = 8,
                    FIFO_DEPTH  = 16,
                    ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     clk,
    input logic                     rst_n,

    input logic                     wen,
    input logic [DATA_WIDTH-1:0]    wdata,  
    input logic [ADDR_WIDTH-1:0]    waddr,

        
    input logic                     ren,
    output logic [DATA_WIDTH-1:0]   rdata, 
    input logic [ADDR_WIDTH-1:0]    raddr
);


logic                   mem_wea;
logic [DATA_WIDTH-1:0]  mem_din;
logic [DATA_WIDTH-1:0]  mem_dout;
logic [ADDR_WIDTH-1:0]  mem_addr;
logic [DATA_WIDTH-1:0]  delayed_wdata;
logic [ADDR_WIDTH-1:0]  delayed_waddr;


logic                   delayed_wen;
logic [DATA_WIDTH-1:0]  mux_dout;

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        delayed_wen     <= 0;
        delayed_wdata   <= 0;
        delayed_waddr   <= 0;
    end else begin
        if( (ren & wen)==1 ) begin
            delayed_wen     <= 1;
            delayed_wdata   <= wdata;
            delayed_waddr   <= waddr;
        end else begin
            delayed_wen     <= 0;
        end
    end
end

always_comb begin
    mem_wea     = delayed_wen | (wen & (~ren));
    mem_addr    = delayed_wen ? delayed_waddr : (mem_wea ? waddr : raddr);
    mem_din     = delayed_wen ? delayed_wdata : wdata;
end

/*
blk_mem_gen_0 U0 (
    .clka     ( clk     ),
    .ena      ( rst_n   ),
    .wea      ( mem_wea ),
    .addra    ( mem_addr),
    .dina     ( mem_din ),
    .douta    ( mem_dout)
);
*/
spram U0(
    .clk      ( clk     ),
    .ena      ( rst_n   ),
    .wea      ( mem_wea ),
    .addra    ( mem_addr),
    .dina     ( mem_din ),
    .douta    ( mem_dout)
);


always_comb begin
    mux_dout = mem_dout;
end

/*
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        rdata <= 0;
    end else begin
        rdata <= mux_dout;
    end
end
*/

assign rdata = mux_dout;

endmodule

