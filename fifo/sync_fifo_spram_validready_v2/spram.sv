// single-port synchronous RAM (Write first)

module spram #( DATA_WIDTH  = 8,
                FIFO_DEPTH  = 16,
                ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     clk,
    input logic                     rst_n,
    input logic                     wea,
    
    input logic [ADDR_WIDTH-1:0]    addr,
    input logic [DATA_WIDTH-1:0]    din,    
    output logic [DATA_WIDTH-1:0]   dout
);


logic [DATA_WIDTH-1:0]      ram[FIFO_DEPTH-1:0] = '{default:0};
logic [ADDR_WIDTH-1:0]      addr_r;



always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        addr_r <= 0;
    end else begin
        if(wea) begin
            ram[addr] <= din;
        end
        addr_r <= addr;
    end
end

assign dout = ram[addr_r];

endmodule

