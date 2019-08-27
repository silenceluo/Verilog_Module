module fifo #(  DATA_WIDTH  = 8,
                FIFO_DEPTH  = 32,
                ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     clk,
    input logic                     rst_n,
    
    input logic                     ren,
    output logic [DATA_WIDTH-1:0]   rdata, 
    output logic                    empty,

    input logic                     wen,
    input logic [DATA_WIDTH-1:0]    wdata,    
    output logic                    full,
    
    output logic [ADDR_WIDTH-1:0]   count 
);


