module afifo #( DATA_WIDTH  = 8,
                FIFO_DEPTH  = 32,
                ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     rclk,
    input logic                     rrst_n,
    input logic                     ren,
    output logic [DATA_WIDTH-1:0]   rdata, 
    output logic                    empty,

    input logic                     wclk,
    input logic                     wrst_n,
    input logic                     wen,
    input logic [DATA_WIDTH-1:0]    wdata,    
    output logic                    full
);

// Memory
logic [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];

// Pointer signals
logic [ADDR_WIDTH:0]    waddr;
logic [ADDR_WIDTH:0]    raddr;


//sync read to write
logic [ADDR_WIDTH:0]    raddr_w1;
logic [ADDR_WIDTH:0]    raddr_w2;
logic [ADDR_WIDTH:0]    waddr_r1;
logic [ADDR_WIDTH:0]    waddr_r2;

always_ff @(posedge rclk or rrst_n) begin
    if(~rrst_n) begin
        raddr <= 0;
    end else begin  
        if(!empty && ren) begin
            raddr <= raddr + 1;
        end
    end   
end

always_ff @(posedge wclk or wrst_n) begin
    if(~wrst_n) begin
        waddr <= 0;
    end else begin
        if(!full && wen) begin
            waddr <= waddr + 1;
            mem[waddr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end   
end

always_ff @(posedge rclk or rrst_n) begin
    if(~rrst_n) begin
        {waddr_r2, waddr_r1} <= 0;
    end else begin
        {waddr_r2, waddr_r1} <= {waddr_r1, waddr};
    end       
end

always_ff @(posedge wclk or wrst_n) begin
    if(~wrst_n) begin
        {raddr_w2, raddr_w1} <= 0;
    end else begin
        {raddr_w2, raddr_w1} <= {raddr_w1, raddr};
    end 
end

always_comb begin
    empty = 0;
    full = 0;
    if( (raddr[ADDR_WIDTH:0] == waddr_r2[ADDR_WIDTH:0])  ) begin
        empty = 1;
    end
    
    if( (waddr[ADDR_WIDTH-1:0] == raddr_w2[ADDR_WIDTH-1:0]) && (waddr[ADDR_WIDTH] != raddr_w2[ADDR_WIDTH]) ) begin
        full = 1;
    end
    
    rdata = mem[raddr[ADDR_WIDTH-1:0]];
 end

endmodule


