// single-port synchronous RAM (Write first)

module spram #( DATA_WIDTH  = 8,
                FIFO_DEPTH  = 16,
                ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     clk,
    input logic                     ena,
    input logic                     wea,
    
    input logic [ADDR_WIDTH-1:0]    addra,
    input logic [DATA_WIDTH-1:0]    dina,    
    output logic [DATA_WIDTH-1:0]   douta
);


logic [DATA_WIDTH-1:0]      ram[FIFO_DEPTH-1:0] = '{default:0};
logic [DATA_WIDTH-1:0]      din_r;
logic [ADDR_WIDTH-1:0]      addr_r;
logic [DATA_WIDTH-1:0]      dout_r;
logic                       wr_en_r;

always_ff @(posedge clk) begin
    if(wea) begin
        ram[addra] <= dina;
    end
    addr_r <= addra;
end

assign douta = ram[addr_r];

endmodule

