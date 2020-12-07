module testbench; 
    parameter   DATA_WIDTH  = 8,
                FIFO_DEPTH  = 32,
                ADDR_WIDTH  = $clog2(FIFO_DEPTH);
               
    logic                   clk;
    logic                   rst_n;

    logic                   ren;
    logic [DATA_WIDTH-1:0]  rdata; 
    logic                   empty;
    logic                   rvalid;

    logic                   wen;
    logic [DATA_WIDTH-1:0]  wdata;    
    logic                   full;

    logic [ADDR_WIDTH-1:0]  count; 
    
    logic                   ren_r, wen_r;
    logic [DATA_WIDTH-1:0]  wdata_r;
    
    spram_fifo U0( 
    //fifo_fwft U0(
                    .clk,
                    .rst_n,
                
                    .ren    (ren_r  ),
                    .rdata, 
                    .empty  ,
                    .rvalid ,
                
                    .wen    (wen_r  ),
                    .wdata  (wdata_r),    
                    .full,
                
                    .count 
                );
                
    always_ff @(posedge clk) begin
        ren_r   <= ren;
        wen_r   <= wen;
        wdata_r <= wdata;
    end


  initial begin
    clk = 0; 
    rst_n = 0;  
    ren = 0; 
    wen = 0; 
    wdata = 0;
        
    #15 rst_n = 1; 
    #8;
    #10 wen = 1; wdata = 1;
    #10 wen = 1; wdata = 2;
    #10 wen = 1; wdata = 3;
    #10 wen = 1; wdata = 4; ren =1;      
    #10 wen = 1; wdata = 5; ren =1; 
    #10 wen = 1; wdata = 6; ren =1; 
    #10 wen = 1; wdata = 7; ren =1; 
    #10 wen = 1; wdata = 8; ren =1; 
    #10 wen = 0;
    #50 ren = 0;
  end 
    
    always  begin
        #5 clk = !clk; 
    end

   
  initial 
  #200 $finish; 
    
  //Rest of testbench code after this line 
    
endmodule




