module testbench; 

    logic                   clk;
    logic                   rst_n;

    logic [31:0]    a;
    logic           a_valid;
    logic           a_ready;
    
    logic [31:0]    b;
    logic           b_valid;
    logic           b_ready;
    
    logic [31:0]    c;
    logic           c_valid;
    logic           c_ready;

    adder U0(
        .clk,
        .rst_n,
        
        .a,
        .a_valid,
        .a_ready,
        
        .b,
        .b_valid,
        .b_ready,
        
        .c,
        .c_valid,
        .c_ready 
    );
              
 

  initial begin
    clk = 0; 
    rst_n = 0;  
    
    a = 0; 
    a_valid = 0;
 
    b = 0; 
    b_valid = 0;
    
    c_ready = 0;
       
        
    #15 rst_n = 1; 
    #10 a_valid = 1; 
        a       = 32'h12345678;
        b_valid = 1;
        b       = 32'h12345678;
    #10 a_valid = 1; 
        a       = 32'h22345678;
        b_valid = 1;
        b       = 32'h22345678;
    #10 a_valid = 1; 
        a       = 32'h32345678;
        b_valid = 1;
        b       = 32'h42345678;
    #10 a_valid = 1; 
        a       = 32'h12345678;
        b_valid = 1;
        b       = 32'h52345678;
    #10 a_valid = 1; 
        a       = 32'h12345678;
        b_valid = 1;
        b       = 32'h62345678;                        
  end 
    
    always  begin
        #5 clk = !clk; 
    end

   
  initial 
  #200 $finish; 
    
  //Rest of testbench code after this line 
    
endmodule


