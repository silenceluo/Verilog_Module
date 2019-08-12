module testbench; 
    parameter   DATA_WIDTH  = 8,
                FIFO_DEPTH  = 32,
                DDR_WIDTH  = $clog2(FIFO_DEPTH);
                
    logic rclk, rrst_n, ren; 
    logic wclk, wrst_n, wen;
    logic empty, full;
    logic [DATA_WIDTH-1:0] rdata;
    logic [DATA_WIDTH-1:0] wdata;
    
    afifo U0( 
                .rclk,
                .rrst_n,
                .ren,
                .rdata, 
                .empty,
                
                .wclk,
                .wrst_n,
                .wen,
                .wdata,    
                .full
            );


  initial begin
    rclk = 0; 
    rrst_n = 0;  
    ren = 0; 
  
    wclk = 0; 
    wrst_n = 0;  
    wen = 0; 
    wdata = 0;
        
    #15 rrst_n = 1; wrst_n = 1;
    #10 wen = 1; wdata = 10;
    #10 wen = 1; wdata = 11;
    #10 wen = 1; wdata = 12;
    #10 wen = 1; wdata = 13; ren =1;      
    #10 wen = 1; wdata = 14; ren =1; 
    #10 wen = 1; wdata = 65; ren =1; 
    #10 wen = 1; wdata = 22; ren =1; 
    #10 wen = 1; wdata = 13; ren =1; 
  end 
    
    always  begin
        #5 rclk = !rclk; 
    end
    always  begin
        #5 wclk = !wclk; 
    end
   
  initial 
  #200 $finish; 
    
  //Rest of testbench code after this line 
    
endmodule


