module buble #( parameter  WIDTH = 32
)(
    input logic             clk,
    input logic             rst_n,

    input logic [WIDTH-1:0]     data_a,
    input logic                 vld_a,
    output logic                rdy_a,

    output logic [WIDTH-1:0]    data_b,
    output logic                vld_b,
    input logic                 rdy_b
);

logic [WIDTH-1:0]   data_r;
logic               vld_r;

always_ff @(posedge clk or negedge rst_n) begin
    if(rst_n == 0) begin
        data_r  <= '0;
        vld_r   <= 1'b0;
    end else begin
        if(rdy_a == 1) begin
            data_r  <= data_a;
            vld_r   <= vld_a;
        end
    end
end


always_comb begin
    data_b  = data_r;
    vld_b   = vld_r;

    rdy_a   = rdy_b | (~vld_b);
end
endmodule
