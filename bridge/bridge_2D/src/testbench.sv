`timescale 1ns/1ps
module testbench; 
   parameter   IN_WIDTH    = 3,
               OUT_DEPTH   = 32,
               DATA_W      = 8;

logic                   clk;
logic                   rst_n;

logic                               B_vld_i;
logic [IN_WIDTH-1:0][DATA_W-1:0]    B_din;
logic                               B_last_i;
logic                               B_rdy_o;

logic                               B_vld_o;
logic [OUT_DEPTH-1:0][DATA_W-1:0]   B_dout;
logic                               B_vld_o;
logic                               B_last_o;
logic                               B_rdy_i;


bridge_combine_odd #(  
   .DIN_W   ( IN_WIDTH  ),
   .DOUT_W  ( OUT_DEPTH ),
   .DATA_W  ( DATA_W    )
) uut(       
   .clk     ( clk       ),
   .a_rst_n ( rst_n     ),

   .vld_i   ( B_vld_i   ),
   .last_i  ( B_last_i  ),
   .din     ( B_din     ),
   .rdy_o   ( B_rdy_o   ),

   .vld_o   ( B_vld_o   ),
   .dout    ( B_dout    ),
   .last_o  ( B_last_o  ),
   .rdy_i   ( B_rdy_i   ) 
);

initial begin
   clk      = 0;
   rst_n    = 0;
   B_last_i = 0;
   
   #20   rst_n    = 1;
   #200  B_last_i = 1;
   #10   B_last_i = 0;
   #150  B_last_i = 1;
   #10   B_last_i = 0;
   #100  B_last_i = 1;
   #10   B_last_i = 0;
   end 

always  
   #5 clk = !clk; 
  
logic                            A_vld_o;
logic [IN_WIDTH-1:0][DATA_W-1:0] A_dout;

logic [7:0] cnt_q;
always_ff @(posedge clk or negedge rst_n) begin
   if(rst_n == 0) begin
      A_vld_o  <= 0;
      A_dout   <= 0;
      cnt_q    <= 0;
   end else begin
      if(B_rdy_o == 1) begin
         A_vld_o  <= 1;
         cnt_q    <= cnt_q + 1;
         for (int i=0; i<IN_WIDTH; i++) begin
            A_dout[i]   <= cnt_q*3 + i;
         end
      end 
   end
end


logic [IN_WIDTH-1:0] C_rdy_o;
logic [3:0]          c_delay;
always_ff @(posedge clk or negedge rst_n) begin
   if(rst_n == 0) begin
      C_rdy_o  <= 0;
      c_delay  <= 0;
   end else begin
      c_delay  <= c_delay + 1;
      if(c_delay < 4) begin
         C_rdy_o  <= 1;
      end else begin
         C_rdy_o  <= 0;
      end
   end
end

always_comb begin
   B_rdy_i  = C_rdy_o;
   B_vld_i  = A_vld_o;
   B_din    = A_dout;
end

initial begin
   $fsdbDumpfile("znz_decode.fsdb");
   $fsdbDumpvars();
end

// initial 
// #1000 $finish; 
   
//Rest of testbench code after this line 
   
endmodule


