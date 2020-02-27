module model_src #( parameter  WIDTH = 32
)(
    input logic             clk,
    input logic             rst_n,

    output logic [WIDTH-1:0]    data_a,
    output logic                vld_a,
    input logic                 rdy_a
);

assign vld_a = 1;


always_ff @(posedge clk or negedge rst_n) begin
    if(rst_n == 0) begin
        data_a  <= '0;
    end else begin
        if(rdy_a && vld_a) begin
            data_a  <= data_a + 1;
        end
    end
end


endmodule
