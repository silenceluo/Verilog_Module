module spram_fifo #(DATA_WIDTH  = 8,
                    FIFO_DEPTH  = 32,
                    ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     clk,
    input logic                     rst_n,
    
    input logic                     ren,
    output logic [DATA_WIDTH-1:0]   rdata, 
    output logic                    empty,
    output logic                    rvalid,
    
    input logic                     wen,
    input logic [DATA_WIDTH-1:0]    wdata,    
    output logic                    full,

    
    output logic [ADDR_WIDTH-1:0]   count 
);

// Pointer signals
logic [ADDR_WIDTH-1:0]    waddr_d,  waddr_q;
logic [ADDR_WIDTH-1:0]    raddr_d,  raddr_q,    raddr_q1;

logic writing, reading;

logic                   mem0_wen;
logic [DATA_WIDTH-1:0]  mem0_din;
logic [ADDR_WIDTH-2:0]  mem0_waddr_d,   mem0_waddr_q;

logic                   mem0_ren;
logic [DATA_WIDTH-1:0]  mem0_dout;
logic [ADDR_WIDTH-2:0]  mem0_raddr_d,   mem0_raddr_q;

logic                   mem1_wen;
logic [DATA_WIDTH-1:0]  mem1_din;
logic [ADDR_WIDTH-2:0]  mem1_waddr_d,   mem1_waddr_q;

logic                   mem1_ren;
logic [DATA_WIDTH-1:0]  mem1_dout;
logic [ADDR_WIDTH-2:0]  mem1_raddr_d,   mem1_raddr_q;


always_ff @(posedge clk or negedge rst_n) begin
    if( ~rst_n) begin
        raddr_q         <= 0;
        waddr_q         <= 0;     
        raddr_q1        <= 0;

        mem0_waddr_q    <= '0; 
        mem0_raddr_q    <= '0; 
        mem1_waddr_q    <= '0; 
        mem1_raddr_q    <= '0; 
    end else begin
        raddr_q         <= raddr_d;
        waddr_q         <= waddr_d;
        raddr_q1        <= raddr_q;

        mem0_waddr_q    <= mem0_waddr_d; 
        mem0_raddr_q    <= mem0_raddr_d; 
        mem1_waddr_q    <= mem1_waddr_d; 
        mem1_raddr_q    <= mem1_raddr_d; 
    end
end


always_comb begin 
    writing = wen && (ren || !full);
    reading = ren && !empty;  
end

always_comb begin 
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


always_comb begin
    if(waddr_q[0] == 0) begin
        mem0_wen        = writing;
        mem0_din        = wdata;
        mem0_waddr_d    = waddr_q[ADDR_WIDTH-1:1];
        
        mem1_wen        = 0;
        mem1_din        = 0;
        mem1_waddr_d    = mem1_waddr_q;
    end else if(waddr_q[0] == 1) begin
        mem0_wen        = 0;
        mem0_din        = 0;
        mem0_waddr_d    = mem0_waddr_q;
        
        mem1_wen        = writing;
        mem1_din        = wdata;
        mem1_waddr_d    = waddr_q[ADDR_WIDTH-1:1];
    end
    
    if(raddr_q[0] == 0) begin
        mem0_ren        = reading;
        mem0_raddr_d    = raddr_q[ADDR_WIDTH-1:1];
        
        mem1_ren        = 0;
        mem1_raddr_d    = mem1_raddr_q;  
    end else if(raddr_q[0] == 1) begin
        mem0_ren        = 0;
        mem0_raddr_d    = mem0_raddr_q;
        
        mem1_ren        = reading;
        mem1_raddr_d    = raddr_q[ADDR_WIDTH-1:1]; 
    end
    
    rdata = raddr_q1[0] ?  mem1_dout : mem0_dout;
end



always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        empty <= 1;
    end else if (reading && waddr_d == raddr_d && !full) begin
        empty <= 1;
    end else if (writing && !reading) begin
	    empty <= 0;
    end
end
  
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        full <= 0;
    end else if (writing && waddr_d == raddr_d) begin
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

//logic [ADDR_WIDTH-1:0]  raddr_r1;
assign rvalid   = ren & (~empty);

fifo_bank #(   
    .DATA_WIDTH ( DATA_WIDTH ),
    .FIFO_DEPTH ( FIFO_DEPTH/2 )
) even (                        
    .clk    ( clk   ),
    .rst_n  ( rst_n ),
    
    .wen    ( mem0_wen  ),
    .wdata  ( mem0_din  ),  
    .waddr  ( mem0_waddr_d),

    .ren    ( mem0_ren  ),
    .rdata  ( mem0_dout ), 
    .raddr  ( mem0_raddr_d)
);


fifo_bank #(    
    .DATA_WIDTH ( DATA_WIDTH ),
    .FIFO_DEPTH ( FIFO_DEPTH/2 )
) odd (                        
    .clk    ( clk   ),
    .rst_n  ( rst_n ),
    
    .wen    ( mem1_wen  ),
    .wdata  ( mem1_din  ),  
    .waddr  ( mem1_waddr_d),

    .ren    ( mem1_ren  ),
    .rdata  ( mem1_dout ), 
    .raddr  ( mem1_raddr_d)
);

endmodule

