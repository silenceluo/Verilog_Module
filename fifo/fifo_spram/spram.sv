// single-port synchronous RAM (Write first)

module spram #( DATA_WIDTH  = 8,
                FIFO_DEPTH  = 16,
                ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     clk,
    input logic                     rst_n,
    input logic                     wea,
    
    input logic [ADDR_WIDTH-1:0]    addra,
    input logic [DATA_WIDTH-1:0]    dina,    
    output logic [DATA_WIDTH-1:0]   douta
);


logic [DATA_WIDTH-1:0]      ram[FIFO_DEPTH-1:0] = '{default:0};

logic [ADDR_WIDTH-1:0]      addr_r;



always_ff @(posedge clk or negedge rst_n) begin
    if(rst_n) begin
        if(wea) begin
            ram[addra] <= dina;
        end
        addr_r <= addra;
    end
end

assign douta = ram[addr_r];

endmodule

