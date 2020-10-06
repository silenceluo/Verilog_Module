/////////////////////////////////////////////////////////////////
// Arbiter, referred to https://github.com/freecores/round_robin_arbiter
// Fix the bug in ff logic
// 20190903
////////////////////////////////////////////////////////////////////////


module arbiter #(   parameter N = 4 ) (
    input logic             rst_n,
    input logic             clk,
    input logic [N-1:0]     req,
    output logic [N-1:0]    grant
);


logic    [N-1:0]        rotate_ptr;
logic    [N-1:0]        masked_req;
logic    [N-1:0]        masked_grant;
logic    [N-1:0]        grant_comb;

logic                   no_masked_req;
logic    [N-1:0]        unmasked_grant;
logic                   update_ptr;

logic [N-1:0]           grant_q, grant_d;

genvar i;


always_ff @ (posedge clk or negedge rst_n) begin
    if (!rst_n)    begin
        grant_q <= '0;
    end else begin
        grant_q <= grant_d;
    end
end

// rotate pointer update logic
always_comb begin
    update_ptr = |grant_q[N-1:0];
    
    if (~rst_n) begin
        rotate_ptr[0] = 1'b1;
        rotate_ptr[1] = 1'b1;
    end else begin
        if (update_ptr) begin
            rotate_ptr[0] = grant_q[N-1];
            rotate_ptr[1] = grant_q[N-1] | grant_q[0];
        end
    end    
end
    
generate
    for (i=2; i<N; i=i+1) begin
        always_comb begin
            if (~rst_n) begin
                rotate_ptr[i] = 1'b1;
            end else begin
                if (update_ptr) begin
                    rotate_ptr[i] = grant_q[N-1] | (|grant_q[i-1:0]);
                end
            end
        end
    end
endgenerate


// masked and unmasked grant generation logic
always_comb begin
    masked_req[N-1:0]   = req[N-1:0] & rotate_ptr[N-1:0];
    masked_grant[0]     = masked_req[0];
    unmasked_grant[0]   = req[0];
end
    
generate
    for (i=1;i<N;i=i+1) begin
        always_comb begin
            masked_grant[i]     = (~|masked_req[i-1:0]) & masked_req[i];
            unmasked_grant[i]   = (~|req[i-1:0]) & req[i];
        end
    end
endgenerate


// grant generation logic
always_comb begin
    no_masked_req       = ~|masked_req[N-1:0];
    grant_comb[N-1:0]   = masked_grant[N-1:0] | (unmasked_grant[N-1:0] & {N{no_masked_req}});

    grant_d[N-1:0]      = grant_comb[N-1:0];
    grant               = grant_d;
end

endmodule
