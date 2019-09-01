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
    input  logic                    out_ready,
    
    output logic [ADDR_WIDTH-1:0]   count 
);


logic                   mem_wea;
logic [ADDR_WIDTH-1:0]  mem_addr;
logic [DATA_WIDTH-1:0]  mem_din;
logic [DATA_WIDTH-1:0]  mem_dout;

logic [ADDR_WIDTH-1:0]  wr_addr;
logic [ADDR_WIDTH-1:0]  rd_addr;
logic                   reading;
logic                   writing;
logic                   full;
logic                   empty;


logic                   delay_wr;
logic                   delay_wr_r1;
logic                   in_valid_r1;
logic [DATA_WIDTH-1:0]  in_data_r1;



always_comb begin  
    full        = (count == FIFO_DEPTH);
    empty       = (count == 0);
     
    reading     = (~empty) && (out_ready);
    writing     = (in_valid & (!full ||out_ready);   

    in_ready    = (~full);
    out_valid   = (~empty);
    
    delay_wr    = reading & writing;
    direct_wr   = writing & (~reading);    
    
    if(~rst_n) begin
        next_raddr = 0;
        next_waddr = 0;
    end else begin
        if(reading) begin
            next_raddr = raddr + 1;
        end else begin
            next_raddr = raddr;
        end
        
        if(delay_wr_r1 | direct_wr) begin
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
        count <= 0;
    end else if (writing && !reading) begin
        count <= count+1;
    end else if (reading && !writing) begin
        count <= count-1;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        delay_wr_r1 <= 0;
        
        in_data_r1  <= 0;
        in_valid_r1 <= 0;
    end else begin
        delay_wr_r1 <= delay_wr;
        
        if(delay_wr) begin
            in_data_r1  <= in_data;
            in_valid_r1 <= in_valid;
        end
    end
end


always_comb begin
    mem_wea     = delay_wr_r1 | direct_wr;
    mem_addr    = delay_wr_r1 ? delayed_waddr : (mem_wea ? waddr : raddr);
    mem_din     = delay_wr_r1 ? in_data_r1 : in_data;
end


spram RAM_U0( 
                .clk    ( clk       ),
                .ena    ( ~rst_n    ),
                
                .wea    ( mem_wea   ),
                .addra  ( mem_addr  ),
                .dina   ( mem_din   ),    
                .douta  ( mem_dout  )
);

endmodule
