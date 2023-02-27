`timescale 1ns/1ps
module testbench; 
    parameter   IN_WIDTH  	= 4,
                OUT_DEPTH  	= 11;

	logic 			clk;
	logic 			rst_n;

	logic 					B_vld_i;
	logic [IN_WIDTH-1:0] 	B_din;
	logic 					B_rdy_o;

	logic 					B_vld_o;
	logic [OUT_DEPTH-1:0] 	B_dout;
	logic 					B_rdy_i;
 	
	
	brdige #(	.N ( IN_WIDTH 	),
				.M ( OUT_DEPTH	)
	) uut(	  	
			.clk	(clk 	),
			.rst_n	(rst_n	),

			.vld_i	(B_vld_i),
			.din	(B_din	),
			.rdy_o	(B_rdy_o),

			.vld_o	(B_vld_o),
			.dout	(B_dout	),
			.rdy_i	(B_rdy_i) 
	);
	
	initial begin
		clk = 0;
		rst_n = 0;
		
		#20 rst_n = 1;
	end 
	
	always  
		#5 clk = !clk; 
	
    
	logic 					A_vld_o;
	logic [IN_WIDTH-1:0] 	A_dout;
	
	always_ff @(posedge clk or negedge rst_n) begin
		if(rst_n == 0) begin
			A_vld_o <= 0;
			A_dout	<= 0;
		end else begin
			if(B_rdy_o == 1) begin
				A_vld_o <= 1;
				A_dout	<= A_dout + 1;
			end 
		end
	end
	
	
	logic [IN_WIDTH-1:0] 	C_rdy_o;
	logic [3:0]	c_delay;
	always_ff @(posedge clk or negedge rst_n) begin
		if(rst_n == 0) begin
			C_rdy_o <= 0;
			c_delay <= 0;
		end else begin
			c_delay <= c_delay + 1;
			if(c_delay < 4) begin
				C_rdy_o <= 1;
			end else begin
				C_rdy_o <= 0;
			end
		end
	end

	always_comb begin
		B_rdy_i	= C_rdy_o;
		B_vld_i = A_vld_o;
		B_din 	= A_dout;
	end
	
  initial 
  #1000 $finish; 
    
  //Rest of testbench code after this line 
    
endmodule


