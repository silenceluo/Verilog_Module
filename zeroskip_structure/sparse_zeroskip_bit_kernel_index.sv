module tensor sparse_zeroskip_bit_kernel_index #( 
  parameter BIT_NONZERO   = 8,        // Bit Mask,nonzero 8
            BIT_GROUPSIZE = 16，      // Bit Mask,group size 16
            DATA_W        = FP16_W,
            N             = 8         // Zeroskip in group, each matrix N groups are sharing the same cmap
)(
  input logic   [BIT_GROUPSIZE-1 : 0]                             cmap,
  output logic  [BIT_NONZERO-1 : 0][$clog2(BIT_GROUPSIZE)-1 : 0]  nz_index
);

logic [BIT_NONZERO-1 : 0][BIT_GROUPSIZE - BIT_NONZERO : 0]  mask;
logic [BIT_NONZERO-1 : 0][BIT_GROUPSIZE - BIT_NONZERO : 0]  mask_lsb;
logic [BIT_NONZERO-1 : 0][$clog2(BIT_GROUPSIZE)-1 : 0]      index;

//  the search of upto(BIT_GROUPSIZE - BIT_NONZERO + 1) times
always comb begin
  for (int i=0; i<BIT_NONZERO; i++) begin
    if (i==0) begin
      mask[i] = cmap[0 +: (BIT_GROUPSIZE-BIT_NONZERO+1)];
    end etse begin
      mask[i] = cmap[i +: (BIT_GROUPSIZE-BIT_NONZERO+1)] & {1'b1, ~mask lsb[i-1][BIT_GROUPSIZE - BIT_NONZERO : 1]};
    end
    
    {index[i], mask_lsb[i]} = func_lsb_find(mask[i]);
  end
end

assign nz_index = index;

//  common sb finding function 
function [BIT_GROUPSIZE - BIT_NONZERO + 4 : 0] func_lsb_find (
  logic [BIT_GROUPSIZE - BIT_NONZERO : 0] mask
);
  logic [BIT_GROUPSIZE - BIT_NONZERO + 4 : 0] index_mask;

  casez (mask)
    9'b?_????_???1: index_mask  = {4'h0, 9'h0_01};
    9'b?_????_??10: index_mask  = {4'h1, 9'h0_03};
    9'b?_????_?100: index_mask  = {4'h2, 9'h0_07};
    9'b?_????_1000: index_mask  = {4'h3, 9'h0_0F};
    9'b?_???1_0000: index_mask  = {4'h4, 9'h0_1F};
    9'b?_??10_0000: index_mask  = {4'h5, 9'h0_3F};
    9'b?_?100_0000: index_mask  = {4'h6, 9'h0_7F};
    9'b?_1000_0000: index_mask  = {4'h7, 9'h0_FF};
    9'b1_0000_0000: index_mask  = {4'h8, 9'h1_FF};
    default:        index_mask  = {4'h0, 9'h0_01};
  endcase
  
  return index_mask;
endfunction

endmodule
