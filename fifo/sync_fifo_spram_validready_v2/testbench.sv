module testbench; 
    parameter   DATA_WIDTH  = 8,
                FIFO_DEPTH  = 32,
                ADDR_WIDTH  = $clog2(FIFO_DEPTH);
               
    logic                   clk;
    logic                   rst_n;

    logic [DATA_WIDTH-1:0]  in_data;
    logic                   in_valid;
    logic                   in_ready;

    logic [DATA_WIDTH-1:0]  out_data;
    logic                   out_valid;
    logic                   out_ready;
    
    logic [DATA_WIDTH-1:0]  in_data_r;
    logic                   in_valid_r;
    logic                   out_ready_r;
    
    spram_fifo U0( 
                    .clk    (clk),
                    .rst_n  (rst_n),

                    .in_data    (in_data_r  ), 
                    .in_valid   (in_valid_r ),
                    .in_ready  (in_ready),



                    .out_data   (out_data),    
                    .out_valid  (out_valid),
                    .out_ready  (out_ready_r)
                );
                
              
                
    always_ff @(posedge clk) begin
        in_data_r   <= in_data;
        in_valid_r  <= in_valid;
        out_ready_r <= out_ready;
    end


  initial begin
    clk = 0; 
    rst_n = 0;  
    in_valid = 0; 
    in_data = 0;
    out_ready = 0;
    
        
    #15 rst_n = 1; 
    #8;
    #10 in_valid = 1; 
        in_data = 10;
    #10 in_data = 11;
    #10 in_data = 12;
    #10 in_data = 13; 
        out_ready =1;      
    #10 in_data = 14; 
    #10 in_data = 65; 
    #10 in_data = 22;  
    #10 in_data = 13; 
    #10 in_valid = 0;
    #50 out_ready = 0;
  end 
    
    always  begin
        #5 clk = !clk; 
    end

   
  initial 
  #200 $finish; 
    
  //Rest of testbench code after this line 
    
endmodule



