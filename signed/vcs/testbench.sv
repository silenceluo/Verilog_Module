`timescale 1ns/1ps
module testbench; 
    parameter   IW  = 8;

    logic           clk;
    logic           rst_n;

    logic [IW-1:0]  din;
    logic           dout_1;
    logic [1:0]     dout_2;
    logic [3:0]     dout_4;
    logic [3:0]     dout_4u;

    svsign #(
        .IW ( 8 )
    ) svsign (
        .clk        ( clk       ),
        .rst_n      ( rst_n     ),
        .din        ( din       ),
        .dout_1     ( dout_1    ),
        .dout_2     ( dout_2    ),
        .dout_4     ( dout_4    ),
        .dout_4u    ( dout_4u   )
    );
    
    initial begin
        clk = 0;
        rst_n = 0;
        
        #20 rst_n = 1;
    end 
    
    always  
        #5 clk = !clk; 
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(rst_n == 0) begin
            din <= $signed(-127);
        end else begin
            din <= din + 1;
        end
    end
        
    initial 
        #5000 $finish; 
    
  //Rest of testbench code after this line 
    
endmodule


