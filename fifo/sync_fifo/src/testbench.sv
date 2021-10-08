module testbench; 
    parameter   DATA_WIDTH  = 8,
                FIFO_DEPTH  = 32,
                ADDR_WIDTH  = $clog2(FIFO_DEPTH);
               
    logic                   clk;
    logic                   rst_n;
    logic                   clear;

    logic                   ren;
    logic [DATA_WIDTH-1:0]  rdata; 
    logic                   empty;

    logic                   wen;
    logic [DATA_WIDTH-1:0]  wdata;    
    logic                   full;

    logic [ADDR_WIDTH-1:0]  count; 
    
    generic_sync_fifo U0( 
            .clk    (clk),
            .rst_n  (rst_n),
            .clear  (clear),

            .ren    (ren),
            .rdata  (rdata), 
            .empty  (empty),

            .wen    (wen),
            .wdata  (wdata),    
            .full   (full),

            .count  (count)
        );


  initial begin
    clk = 0; 
    rst_n = 0;  
    ren = 0; 
    wen = 0; 
    wdata = 0;
    clear = 0; 
        
    #15 rst_n = 1; 
    #8 wen = 1; wdata = 10;
    #10 wen = 1; wdata = 11;
    #10 wen = 1; wdata = 12;
    #10 wen = 1; wdata = 13; ren =1;      
    #10 wen = 1; wdata = 14; ren =1; 
    #10 wen = 1; wdata = 65; ren =1; 
    #10 wen = 1; wdata = 22; ren =1; 
    #10 wen = 1; wdata = 13; ren =1; 

    #10 wen = 1; ren = 1; clear=1;
    #10 clear =0 ;
    #10 ren =1;
    #10 ren =0;
    #10 wen = 1; wdata = 13;
  end 
    
    always  begin
        #5 clk = !clk; 
    end

   
  initial 
  #200 $finish; 
    
  //Rest of testbench code after this line 
    
endmodule




