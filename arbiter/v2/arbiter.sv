//Using Two Simple Priority Arbiters with a Mask
//author: dongjun_luo@hotmail.com
module arbiter (
    input logic         rst_n,
    input logic	        clk,
    input logic	[3:0]	req,
    output logic [3:0]	grant
);

logic [3:0]	    rotate_ptr;
logic [3:0]	    mask_req;
logic [3:0]	    mask_grant;
logic [3:0] 	grant_comb;
logic [3:0]	    grant;
logic	        no_mask_req;
logic [3:0] 	nomask_grant;

/*
always_ff @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		rotate_ptr[3:0] <= 4'b1111;
	end else begin
		case (1'b1) // synthesis parallel_case
			grant[0]: rotate_ptr[3:0] <= 4'b1110;
			grant[1]: rotate_ptr[3:0] <= 4'b1100;
			grant[2]: rotate_ptr[3:0] <= 4'b1000;
			grant[3]: rotate_ptr[3:0] <= 4'b1111;
		endcase
	end
end
*/

always_comb begin
    rotate_ptr[3:0] = 4'b1111;
	case (1'b1) // synthesis parallel_case
		grant[0]: rotate_ptr[3:0] = 4'b1110;
		grant[1]: rotate_ptr[3:0] = 4'b1100;
		grant[2]: rotate_ptr[3:0] = 4'b1000;
		grant[3]: rotate_ptr[3:0] = 4'b1111;
	endcase
end

assign mask_req[3:0] = req[3:0] & rotate_ptr[3:0];

// simple priority arbiter for mask req
always_comb begin 
	mask_grant[3:0] = 4'b0;
	if (mask_req[0])	
	    mask_grant[0] = 1'b1;
	else if (mask_req[1])	
	    mask_grant[1] = 1'b1;
	else if (mask_req[2])	
	    mask_grant[2] = 1'b1;
	else if (mask_req[3])	
	    mask_grant[3] = 1'b1;
end

// simple priority arbiter for no mask req
always_comb begin 
	nomask_grant[3:0] = 4'b0;
	if (req[0])		
	    nomask_grant[0] = 1'b1;
	else if (req[1])	
	    nomask_grant[1] = 1'b1;
	else if (req[2])	
	    nomask_grant[2] = 1'b1;
	else if (req[3])	
	    nomask_grant[3] = 1'b1;
end

assign no_mask_req = ~|mask_req[3:0];
//assign grant_comb[3:0] = no_mask_req ? nomask_grant[3:0] : mask_grant[3:0];
assign grant_comb[3:0] = (nomask_grant[3:0] & {4{no_mask_req}}) | mask_grant[3:0];

always_ff @ (posedge clk or negedge rst_n) begin
	if (!rst_n)	grant[3:0] <= 4'b0;
	else		grant[3:0] <= grant_comb[3:0] & ~grant[3:0];
end
endmodule
