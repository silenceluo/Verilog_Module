module testbench; 

logic src_rst_ni;
logic src_clk_i;
logic [31:0]     src_data_i;
logic src_valid_i;
logic src_ready_o;

logic dst_rst_ni;
logic dst_clk_i;
logic [31:0]     dst_data_o;
logic dst_valid_o;
logic dst_ready_i;




    
    cdc_2phase U0( 
			.src_rst_ni,
			.src_clk_i,
			.src_data_i,
			.src_valid_i,
			.src_ready_o,

			.dst_rst_ni,
			.dst_clk_i,
			.dst_data_o,
			.dst_valid_o,
			.dst_ready_i
            );


  initial begin
    src_rst_ni 	= 0; 
    src_clk_i 	= 0;  
    src_data_i 	= 0; 
	src_valid_i	= 0;
	
    dst_rst_ni 	= 0; 
    dst_clk_i 	= 0;  
    dst_ready_i = 0; 
        
    #15 src_rst_ni = 32'habcdefef; dst_rst_ni = 1;
    #10 src_data_i = 1; src_valid_i = 1;
    #10 dst_ready_i = 1; 
	
    #100 src_data_i = 32'h12345678; src_valid_i = 1;
    #10 dst_ready_i = 1; 
	
	#100 src_data_i = 32'h123defef; src_valid_i = 1;
    #10 dst_ready_i = 1; 
  end 
    
    always  begin
        #5 src_clk_i = !src_clk_i; 
    end
    always  begin
        #27 dst_clk_i = !dst_clk_i; 
    end

    
  //Rest of testbench code after this line 
    
endmodule

