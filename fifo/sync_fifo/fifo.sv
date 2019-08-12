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

// Memory
logic [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];

// Pointer signals
logic [ADDR_WIDTH-1:0]    waddr;
logic [ADDR_WIDTH-1:0]    raddr;

logic [ADDR_WIDTH-1:0]    next_waddr;
logic [ADDR_WIDTH-1:0]    next_raddr;

logic writing, reading;

always_comb begin 
    writing = wen && (ren || !full);
    reading = ren && !empty;  

    if(~rst_n) begin
        next_raddr = 0;
        next_waddr = 0;
    end else begin
        if(reading) begin
            next_raddr = raddr + 1;
        end else begin
            next_raddr = raddr;
        end
        
        if(writing) begin
            next_waddr = waddr + 1;
        end else begin
            next_waddr = waddr;
        end
    end  
end


always_ff @(posedge clk or negedge rst_n) begin
    if (writing) begin
	    mem[waddr]  <= wdata;
    end
    
    raddr   <= next_raddr;
    waddr   <= next_waddr;
end

assign rdata = mem[raddr];


always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        empty <= 1;
    end else if (reading && next_waddr == next_raddr && !full) begin
        empty <= 1;
    end else if (writing && !reading) begin
	    empty <= 0;
    end
end
  
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        full <= 0;
    end else if (writing && next_waddr == next_raddr) begin
        full <= 1;
    end else if (reading && !writing) begin
        full <= 0;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        count <= 0;
    end else if (writing && !reading) begin
        count <= count+1;
    end else if (reading && !writing) begin
        count <= count-1;
    end
end

endmodule
