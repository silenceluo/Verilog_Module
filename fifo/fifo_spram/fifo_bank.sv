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
logic [DATA_WIDTH-1:0]  mem_din_reg;
logic [DATA_WIDTH-1:0]  mem_dout_reg;

logic                   delayed_wr;
logic [DATA_WIDTH-1:0]  mux_dout;

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        delayed_wr  <= 0;
        mem_din_reg <= 0;
    end else begin
        if( (ren & wen)==1 ) begin
            delayed_wr  <= 1;
            mem_din_reg <= wdata;
        end else begin
            delayed_wr  <= 0;
        end
    end
end

always_comb begin
    mem_wea     = delayed_wr | (wen & (~ren));
    mem_addr    = mem_wea ? waddr : raddr;
    mem_din     = delayed_wr ? mem_din_reg : wdata;
end

blk_mem_gen_0 U0 (
    .clka     ( clk     ),
    .ena      ( rst_n  ),
    .wea      ( mem_wea ),
    .addra    ( mem_addr),
    .dina     ( mem_din ),
    .douta    ( mem_dout)
);

endmodule

