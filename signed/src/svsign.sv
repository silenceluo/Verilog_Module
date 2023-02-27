module svsign #(
    parameter   IW  = 8
) (
    input logic             clk,
    input logic             rst_n,
    input logic [IW-1:0]    din,
    output logic            dout_1,
    output logic [1:0]      dout_2,
    output logic [3:0]      dout_4,
    output logic [3:0]      dout_4u
);

always_ff @( posedge clk or negedge rst_n ) begin : blockFF
    if(rst_n ==0) begin
        dout_1  <= '0;
        dout_2  <= '0;
        dout_4  <= '0;
        dout_4u <= '0;
    end else begin
        dout_1  <= $signed(din[0]);
        dout_2  <= $signed(din[1:0]);
        dout_4  <= $signed(din[3:0]);
        dout_4u <= $unsigned(din[3:0]);
    end
end
    
endmodule