// single-port synchronous RAM (Write first)
/*
   logic [NUM_ELEM-1:0][ELEM_WIDTH-1:0] rdata;
   logic [NUM_ELEM-1:0][ELEM_WIDTH-1:0] wdata;
   logic [(NUM_ELEM*ELEM_WIDTH/8)-1:0]  wmask;
   logic                                we;   
   logic                                cs;

   logic [$clog2(MEM_DEPTH*MEM_BANKS)-1:0] addr;
*/
module spram #( DATA_WIDTH  = 8,
                FIFO_DEPTH  = 16,
                ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     clk,
    input logic                     rst_n,

    input logic                     cs,
    input logic                     we,
    
    input logic [ADDR_WIDTH-1:0]    addr,
    input logic [DATA_WIDTH-1:0]    wdata,    
    output logic [DATA_WIDTH-1:0]   rdata
);


logic [DATA_WIDTH-1:0]      ram[FIFO_DEPTH-1:0] = '{default:0};

logic [ADDR_WIDTH-1:0]      addr_r;



always_ff @(posedge clk or negedge rst_n) begin
    if(rst_n == 1) begin
        if(cs == 1) begin
            if(we == 1) begin   //  Write into the mem
                ram[addr] <= wdata;
            end else begin      //  Read, flop the addr
                addr_r <= addr;
            end
        end
    end
end

assign rdata = ram[addr_r];

endmodule

