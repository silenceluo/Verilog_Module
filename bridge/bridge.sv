/************************************************************************
This is an interview question at Google TPU, the description: Design a 
bridge using valid/ready protocol with input size N and output size M

Keypoints:	1. The input and output size are parameterized
			2. M does not need to be factorial of N, in this case you need
				to figure out the best behavior. Split and re-combine is the 
				requirement here actually.
			3. When the bridge get enough data and ready to dump, the ready 
				input the receiver may not be ready, then you can actually 
				keep receiving data to avoud bubble, until you need to dump
				the second data while the first data is still there -- you do 
				not need to wait for the previoud data dumped before you receiver
				the next data -- dout and data_r are separate registers.
************************************************************************/
module brdige #(parameter   N             = 32,
                                M             = 128,
                                CNT_WIDTH     = $clog2(N+M)
) (    
    input logic             clk,
    input logic             rst_n,
    
    input logic             vld_i,
    input logic [N-1:0]     din,
    output logic            rdy_o,

    output logic            vld_o,
    output logic [M-1:0]    dout,
    input logic             rdy_i 
);

typedef enum logic [1:0] {
    Empty, 
    Fill,
    Full
} state_t;

state_t state_d,    state_q;

logic [CNT_WIDTH-1:0]   cnt_d, cnt_q;
logic [M-1:0]           reg_d, reg_q;



assign dout = reg_q[M-1 : 0];

always_ff @(posedge clk or negedge rst_n) begin
    if(rst_n == 0) begin
        state_q <= Empty;
        cnt_q   <= 0;
        reg_q   <= 0;
    end else if(rst_n == 1) begin
        state_q <= state_d;
        cnt_q   <= cnt_d;
        reg_q   <= reg_d;
    end    
end

always_comb begin
    state_d = state_q;
    cnt_d   = cnt_q;
    reg_d   = reg_q;
    
    vld_o   = 0;
    rdy_o   = 0;

    case(state_q) 
        Empty: begin
            rdy_o = 1;
            if(vld_i == 1) begin
                reg_d = { din, {M-N{1'b0}} };
                cnt_d = N;
                state_d = Fill;
            end
        end

        Fill: begin
            rdy_o = 1;
            if(vld_i == 1) begin
                reg_d = ({ din, {(M-N){1'b0}} } >> cnt_q) | reg_d;
                cnt_d = cnt_q + N;

                if(cnt_d >= M) begin
                    state_d = Full;
                end
            end           
        end

        Full: begin
            vld_o = 1;
            if(rdy_i == 1) begin
                reg_d = reg_q << M;
                cnt_d = cnt_q - M;

                rdy_o = 1;
                if(vld_i == 1) begin
                    reg_d = ({ din, {(M-N){1'b0}} } >> cnt_d) | reg_d;
                    cnt_d = cnt_d + N;

                    if(cnt_d >= M) begin
                        state_d = Full;
                    end else begin
                        state_d = Fill;
                    end
                end
            end     
        end
    endcase
end

endmodule