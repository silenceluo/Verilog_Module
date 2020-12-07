module generic_sync_fifo #(    
    parameter type  DTYPE       = logic[7:0],
    parameter       FIFO_DEPTH  = 32,
    parameter       ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     clk,
    input logic                     rst_n,
    
    input logic                     ren,
    output DTYPE                    rdata, 
    output logic                    empty,

    input logic                     wen,
    input DTYPE                     wdata,    
    output logic                    full,
    
    output logic [ADDR_WIDTH:0]     count 
);

// Memory
DTYPE       mem [FIFO_DEPTH-1:0];

// Pointer signals
logic [ADDR_WIDTH-1:0]  waddr_q;
logic [ADDR_WIDTH-1:0]  raddr_q;

logic [ADDR_WIDTH-1:0]  waddr_d;
logic [ADDR_WIDTH-1:0]  raddr_d;

logic writing, reading;

always_comb begin 
    writing = wen && (ren || !full);
    reading = ren && !empty;  

    if(~rst_n) begin
        raddr_d = 0;
        waddr_d = 0;
    end else begin
        if(reading) begin
            raddr_d = raddr_q + 1;
        end else begin
            raddr_d = raddr_q;
        end
        
        if(writing) begin
            waddr_d = waddr_q + 1;
        end else begin
            waddr_d = waddr_q;
        end
    end  
end


always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        raddr_q <= 'b0;
        waddr_q <= 'b0;
        count   <= 0;
    end else begin
        raddr_q <= raddr_d;
        waddr_q <= waddr_d;

        if (writing && !reading) begin
            count   <= count+1;
        end else if (reading && !writing) begin
            count   <= count-1;
        end
    end
end

always_comb begin
    empty   = (count == 0);
    full    = (count == FIFO_DEPTH);  //Almost full
end


always_ff @(posedge clk ) begin
    if (writing) begin
	    mem[waddr_q]  <= wdata;
    end
end

assign rdata = mem[raddr_q];

endmodule