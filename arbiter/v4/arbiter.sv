module arbiter (
    clk, req, grant, base
);

parameter WIDTH = 16;
input clk;
input [WIDTH-1:0] req;
output [WIDTH-1:0] grant;
input [WIDTH-1:0] base;

wire [2*WIDTH-1:0] double_req = {req,req};
wire [2*WIDTH-1:0] double_grant = double_req & ~(double_req-base);
assign grant = double_grant[WIDTH-1:0] | double_grant[2*WIDTH-1:WIDTH];

endmodule