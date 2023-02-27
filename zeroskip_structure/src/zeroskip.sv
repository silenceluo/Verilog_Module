module zeroskip #(
   parameter GROUP_SIZE    = 32,
   parameter GROUP_NZ_MAX  = 16,   //  8:32 and 16:32 must share this
   parameter DATA_W        = 8
) (
   input logic [GROUP_SIZE-1:0]                 znz_din,
   input logic [GROUP_SIZE-1:0][DATA_W-1:0]     act_din,
   output logic [GROUP_NZ_MAX-1:0][DATA_W-1:0]  act_enc_dout
);

logic [$clog2(GROUP_NZ_MAX) : 0] index;

always_comb begin
   index          = '0;
   act_enc_dout   = '0;

   for(int i=0; i<GROUP_SIZE; i++) begin
      if(znz_din[i] == 1'b1) begin
         act_enc_dout[index]  = act_din[i];
         index                = index + 1;
      end
   end
end

endmodule
