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
    if( ~rst_n) begin
        raddr   <= 0;
        waddr   <= 0;       
    end else begin
        raddr   <= next_raddr;
        waddr   <= next_waddr;
    end
end


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


logic [ADDR_WIDTH-1:0]  raddr_r1;
logic                   rvalid;




always_ff @(posedge clk or negedge rst_n) begin
    if( ~rst_n) begin
        rvalid              <= 0;       
        raddr_r1            <= 0;
    end else begin
        rvalid              <= ren & (~empty);
        raddr_r1            <= raddr;
    end
end


logic                   mem0_wen;
logic [DATA_WIDTH-1:0]  mem0_din;
logic [ADDR_WIDTH-2:0]  mem0_waddr;

logic                   mem0_ren;
logic [DATA_WIDTH-1:0]  mem0_dout;
logic [ADDR_WIDTH-2:0]  mem0_raddr;

logic                   mem1_wen;
logic [DATA_WIDTH-1:0]  mem1_din;
logic [ADDR_WIDTH-2:0]  mem1_waddr;

logic                   mem1_ren;
logic [DATA_WIDTH-1:0]  mem1_dout;
logic [ADDR_WIDTH-2:0]  mem1_raddr;


always_comb begin
    if(waddr[0] == 0) begin
        mem0_wen                    = writing;
        mem0_din                    = wdata;
        mem0_waddr[ADDR_WIDTH-2:0]  = waddr[ADDR_WIDTH-1:1];
        
        mem1_wen                    = 0;
        mem1_din                    = 0;
        mem1_waddr[ADDR_WIDTH-1:0]  = 0;
    end else if(waddr[0] == 1) begin
        mem0_wen                    = 0;
        mem0_din                    = 0;
        mem0_waddr[ADDR_WIDTH-1:0]  = 0;
        
        mem1_wen                    = writing;
        mem1_din                    = wdata;
        mem1_waddr[ADDR_WIDTH-2:0]  = waddr[ADDR_WIDTH-1:1];
    end
    
    if(raddr[0] == 0) begin
        mem0_ren                    = reading;
        mem0_raddr[ADDR_WIDTH-2:0]  = raddr[ADDR_WIDTH-1:1];
        
        mem1_ren                    = 0;
        mem1_raddr[ADDR_WIDTH-1:0]  = 0;  
        
       // rdata                       = mem0_dout;  
    end else if(raddr[0] == 1) begin
        mem0_ren                    = 0;
        mem0_raddr[ADDR_WIDTH-2:0]  = 0;
        
        mem1_ren                    = reading;
        mem1_raddr[ADDR_WIDTH-1:0]  = raddr[ADDR_WIDTH-1:1]; 
        
        //rdata                       = mem1_dout;  
    end
    
    rdata = rvalid ? (raddr[0] ? mem0_dout : mem1_dout) : 0;
end



fifo_bank #(    .DATA_WIDTH ( DATA_WIDTH ),
                .FIFO_DEPTH ( FIFO_DEPTH/2 )
    ) even (                        
            .clk    ( clk   ),
            .rst_n  ( rst_n ),
            
            .wen    ( mem0_wen  ),
            .wdata  ( mem0_din  ),  
            .waddr  ( mem0_waddr),

            .ren    ( mem0_ren  ),
            .rdata  ( mem0_dout ), 
            .raddr  ( mem0_raddr)
);


fifo_bank #(    .DATA_WIDTH ( DATA_WIDTH ),
                .FIFO_DEPTH ( FIFO_DEPTH )
    ) odd (                        
            .clk    ( clk   ),
            .rst_n  ( rst_n ),
            
            .wen    ( mem1_wen  ),
            .wdata  ( mem1_din  ),  
            .waddr  ( mem1_waddr),

            .ren    ( mem1_ren  ),
            .rdata  ( mem1_dout ), 
            .raddr  ( mem1_raddr)
);

endmodule

