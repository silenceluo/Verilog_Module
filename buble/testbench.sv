`timescale 1ns/1ps
module testbench; 
    parameter   WIDTH  	= 32;

	logic 			    clk;
	logic 			    rst_n;

    logic [WIDTH-1:0]   data_a;
    logic               vld_a;
    logic               rdy_a;

    logic [WIDTH-1:0]   data_b;
    logic               vld_b;
    logic               rdy_b;
 	
	buble buble_uut(
        .clk,
        .rst_n,

        .data_a,
        .vld_a,
        .rdy_a,

        .data_b,
        .vld_b,
        .rdy_b
    );

    model_src model_src_uut(
        .clk,
        .rst_n,

        .data_a,
        .vld_a,
        .rdy_a
    );
	
	initial begin
		clk     = 0;
		rst_n   = 0;
        rdy_b   = 0;
		
        #20 rst_n = 1;
        #30 rdy_b = 1;
        #27 rdy_b = 0;
        #10 rdy_b = 1;
        #26 rdy_b = 0;
        #13 rdy_b = 1;
        #45 rdy_b = 0;
        #30 rdy_b = 1;
        #27 rdy_b = 0;
        #10 rdy_b = 1;
        #26 rdy_b = 0;
        #13 rdy_b = 1;
        #45 rdy_b = 0;
	end 
	
	always  
		#5 clk = !clk; 
	

  initial 
  #1000 $finish; 
    
  //Rest of testbench code after this line 
    
endmodule


