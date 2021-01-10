module generic_sync_fifo #(    
    parameter type  DTYPE       = logic[7:0],
    parameter       FIFO_DEPTH  = 32,
    parameter       ADDR_WIDTH  = $clog2(FIFO_DEPTH),
    parameter       THRESHOLD   = 5
)(  input logic                     clk,
    input logic                     rst_n,
    input logic                     clear,

    input logic                     ren,
    output DTYPE                    rdata, 
    output logic                    empty,

    input logic                     wen,
    input DTYPE                     wdata,    
    output logic                    full,
    output logic                    afull,
    
    output logic [ADDR_WIDTH:0]     count 
);

// Memory
DTYPE       mem [FIFO_DEPTH-1:0];

// Pointer signals
logic [ADDR_WIDTH-1:0]  waddr_q,    waddr_d;
logic [ADDR_WIDTH-1:0]  raddr_q,    raddr_d;
logic [ADDR_WIDTH:0]    count_q,    count_d;

logic                   writing,    reading;

always_comb begin 
    count   = count_q;

    if(~rst_n) begin
        raddr_d = 0;
        waddr_d = 0;
        writing = 0;
        reading = 0;
        count_d = 0;        
    end else begin
        if(clear == 1) begin
            raddr_d = 0;
            waddr_d = 0;
            writing = 0;
            reading = 0;
            count_d = 0;
        end else begin
            writing = wen && (ren || !full);
            reading = ren && !empty;  

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

            if (writing && !reading) begin
                count_d = count_q + 1;
            end else if (reading && !writing) begin
                count_d = count_q - 1;
            end else begin
                count_d = count_q;                
            end
        end
    end  
end


always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        raddr_q <= 'b0;
        waddr_q <= 'b0;
        count_q <= 'b0;
    end else begin
        raddr_q <= raddr_d;
        waddr_q <= waddr_d;
        count_q <= count_d;
    end
end

always_comb begin
    empty   = ( count == 0 );
    full    = ( count == FIFO_DEPTH );  //Almost full
    afull   = ( count > (FIFO_DEPTH-THRESHOLD) );
end


always_ff @(posedge clk ) begin
    if (writing) begin
	    mem[waddr_q]  <= wdata;
    end
end

assign rdata = mem[raddr_q];

endmodule
