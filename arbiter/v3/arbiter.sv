//Using Two Simple Priority Arbiters with a Mask - scalable
//author: dongjun_luo@hotmail.com
module arbiter #(   parameter N = 4 ) (
	input logic         rst_n,
	input logic         lk,
	input logic [N-1:0]	req,
	input logic [N-1:0]	grant
);


logic	[N-1:0]	    rotate_ptr;
logic	[N-1:0]	    mask_req;
logic	[N-1:0]	    mask_grant;
logic	[N-1:0]	    grant_comb;
logic	[N-1:0]	    grant;
logic		        no_mask_req;
logic	[N-1:0]     nomask_grant;
logic		        update_ptr;

genvar i;

// rotate pointer update logic
assign update_ptr = |grant[N-1:0];
always @ (posedge clk or negedge rst_n)
begin
	if (!rst_n)
		rotate_ptr[N-1:0] <= {N{1'b1}};
	else if (update_ptr)
	begin
		// note: N must be at least 2
		rotate_ptr[0] <= grant[N-1];
		rotate_ptr[1] <= grant[N-1] | grant[0];
	end
end

generate
for (i=2;i<N;i=i+1)
always @ (posedge clk or negedge rst_n)
begin
	if (!rst_n)
		rotate_ptr[i] <= 1'b1;
	else if (update_ptr)
		rotate_ptr[i] <= grant[N-1] | (|grant[i-1:0]);
end
endgenerate

// mask grant generation logic
assign mask_req[N-1:0] = req[N-1:0] & rotate_ptr[N-1:0];

assign mask_grant[0] = mask_req[0];
generate
for (i=1;i<N;i=i+1)
	assign mask_grant[i] = (~|mask_req[i-1:0]) & mask_req[i];
endgenerate

// non-mask grant generation logic
assign nomask_grant[0] = req[0];
generate
for (i=1;i<N;i=i+1)
	assign nomask_grant[i] = (~|req[i-1:0]) & req[i];
endgenerate

// grant generation logic
assign no_mask_req = ~|mask_req[N-1:0];
assign grant_comb[N-1:0] = mask_grant[N-1:0] | (nomask_grant[N-1:0] & {N{no_mask_req}});

always @ (posedge clk or negedge rst_n)
begin
	if (!rst_n)	grant[N-1:0] <= {N{1'b0}};
	else		grant[N-1:0] <= grant_comb[N-1:0] & ~grant[N-1:0];
end
endmodule
