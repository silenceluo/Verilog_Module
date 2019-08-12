module testbench; 
  logic clk, rst_n;
  logic [3:0] req;
  logic [3:0] grant; 
    
  arbiter U0 ( 
  .clk      (clk), 
  .rst_n    (rst_n), 
  .req      (req), 
  .grant    (grant) 
  ); 
    
  initial begin
    clk = 0; 
    rst_n = 0; 
    req = 'b0; 
    #15 rst_n = 1;
    #10 req = 4'b0001;
    #10 req = 4'b0010;
    #10 req = 4'b0100;
    #10 req = 4'b1000;
    #10 req = 4'b0001;
    #10 req = 4'b0011;
    #10 req = 4'b0111;
    #10 req = 4'b1111; 
    #10 req = 4'b0001;
    #10 req = 4'b1111;
    #10 req = 4'b1011;
    #10 req = 4'b1111;        
  end 
    
  always  
    #5 clk = !clk; 
    
   
  initial 
  #200 $finish; 
    
  //Rest of testbench code after this line 
    
endmodule
