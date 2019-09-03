module fifo_bank #( DATA_WIDTH  = 8,
                    FIFO_DEPTH  = 16,
                    ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     clk,
    input logic                     rst_n,

    input  logic [DATA_WIDTH-1:0]   in_data,
    input  logic                    in_valid,
    output logic                    in_ready,
    
    output logic [DATA_WIDTH-1:0]   out_data,
    output logic                    out_valid,
    input  logic                    out_ready
);

logic [ADDR_WIDTH-1:0]  count ;
    
logic [ADDR_WIDTH-1:0]  waddr;
logic [ADDR_WIDTH-1:0]  raddr;

logic [ADDR_WIDTH-1:0]  next_raddr;
logic [ADDR_WIDTH-1:0]  next_waddr;


logic                   reading;
logic                   writing;
logic                   writing_direct;
logic                   writing_buffered;

logic [DATA_WIDTH-1:0]  in_data_r1;
logic [ADDR_WIDTH-1:0]  waddr_r1;

logic                   full;
logic                   empty;

logic                   mem_wea;
logic [ADDR_WIDTH-1:0]  mem_addr;
logic [DATA_WIDTH-1:0]  mem_din;
logic [DATA_WIDTH-1:0]  mem_dout;

always_comb begin
    empty   = (count == 0);
    full    = (count == (FIFO_DEPTH-1));

    reading     = (~empty) & out_ready; 
    out_valid   = reading;
        
    in_ready    = ~full;
    
    writing         = (in_valid & (in_ready ||out_ready) );       
    writing_direct  =  writing & (~reading);
end

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin      
        count   <= 0;       
    end else begin
        if(reading & (~writing)) begin
            count   <= count - 1;
        end else if((~reading) & writing) begin
            count   <= count + 1;
        end
    end
end

always_comb begin  
    if(~rst_n) begin
        next_raddr = 0;
        next_waddr = 0;
    end else begin
        if(reading) begin
            next_raddr = raddr + 1;
        end else begin
            next_raddr = raddr;
        end
        
        if(writing_direct | writing_buffered) begin
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





// Handle the read and write conflict
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        writing_buffered    <= 0;
        in_data_r1          <= 0;
        waddr_r1            <= 0;
    end else begin
        if(reading & writing) begin
            writing_buffered    <= 1;           
            in_data_r1          <= in_data;
            waddr_r1            <= waddr;
        end else begin
            writing_buffered    <= 0;           
        end
    end
end

always_comb begin
    mem_wea = writing_buffered | writing_direct;
    mem_addr= writing_buffered ? waddr_r1 : (mem_wea ? waddr : raddr);
    mem_din = writing_buffered ? in_data_r1 : in_data;
end



spram RAM_U0( 
                .clk    ( clk       ),
                .rst_n  ( rst_n     ),
                
                .wea    ( mem_wea   ),
                .addr   ( mem_addr  ),
                .din    ( mem_din   ),    
                .dout   ( mem_dout  )
);

assign out_data = mem_dout;

endmodule
