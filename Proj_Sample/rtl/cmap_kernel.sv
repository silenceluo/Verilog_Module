module cmap_kernel #(
    parameter ZNZ_BITS  = 8,
    parameter DATA_W    = 8
) (
    input logic [ZNZ_BITS-1:0]              znz_din,
    input logic [ZNZ_BITS-1:0][DATA_W-1:0]  enc_din,
    output logic [ZNZ_BITS-1:0][DATA_W-1:0] dec_dout
);

logic [$clog2(ZNZ_BITS)-1 : 0]  din_idx;


always_comb begin
    din_idx = '0;

    for(int i=0; i<ZNZ_BITS; i++) begin
        if(znz_din[i] == 1'b0) begin
            dec_dout[i] = {'0};
        end else begin
            dec_dout[i] = enc_din[din_idx];
            din_idx     = din_idx + 1;
        end
    end
end

endmodule