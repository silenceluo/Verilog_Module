////////////////////////////////////////////////////////////////////////
// Arbiter, referred to https://github.com/freecores/round_robin_arbiter
// Fix the bug in ff logic
// 20190903
////////////////////////////////////////////////////////////////////////

module arbiter (
    input logic         rst_n,
    input logic	        clk,
    input logic	[3:0]	req,
    output logic [3:0]	grant
);

reg	[1:0]	rotate_ptr;
reg	[3:0]	shift_req;
reg	[3:0]	shift_grant;
reg	[3:0]	grant_comb;


// shift req to round robin the current priority
always_comb begin
    case (rotate_ptr[1:0])
        2'b00: shift_req[3:0] = req[3:0];
        2'b01: shift_req[3:0] = {req[0],req[3:1]};
        2'b10: shift_req[3:0] = {req[1:0],req[3:2]};
        2'b11: shift_req[3:0] = {req[2:0],req[3]};
    endcase
end

// simple priority arbiter
always_comb begin
    shift_grant[3:0] = 4'b0;
    if (shift_req[0])	shift_grant[0] = 1'b1;
    else if (shift_req[1])	shift_grant[1] = 1'b1;
    else if (shift_req[2])	shift_grant[2] = 1'b1;
    else if (shift_req[3])	shift_grant[3] = 1'b1;
end

// generate grant signal
always_comb begin
    case (rotate_ptr[1:0])
        2'b00: grant_comb[3:0] = shift_grant[3:0];
        2'b01: grant_comb[3:0] = {shift_grant[2:0],shift_grant[3]};
        2'b10: grant_comb[3:0] = {shift_grant[1:0],shift_grant[3:2]};
        2'b11: grant_comb[3:0] = {shift_grant[0],shift_grant[3:1]};
    endcase
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)	
        grant[3:0] <= 4'b0;
    else		
        grant[3:0] <= grant_comb[3:0] & ~grant[3:0];
end

// update the rotate pointer
// rotate pointer will move to the one after the current granted

always_comb begin
    rotate_ptr[1:0] = 2'b0;
    case (1'b1) // synthesis parallel_case
        grant[0]: rotate_ptr[1:0] = 2'd1;
        grant[1]: rotate_ptr[1:0] = 2'd2;
        grant[2]: rotate_ptr[1:0] = 2'd3;
        grant[3]: rotate_ptr[1:0] = 2'd0;
    endcase
end

endmodule
