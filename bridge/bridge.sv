module brdige #(parameter 	N 			= 8,
							M 			= 32,
							THRESHOLD 	= M- N,
							CNT_WIDTH 	= $clog2(N+M)
	) (	input logic 			clk,
		input logic 			rst_n,
		
		input logic 			vld_i,
		input logic [N-1:0] 	din,
		output logic 			rdy_o,

		output logic 			vld_o,
		output logic [M-1:0] 	dout,
		input logic 			rdy_i 
);
		
localparam 	INIT 	= 2'd0,
			WORK	= 2'd1,
			DUMP	= 2'd2;
			
logic [1:0]				state;
logic [CNT_WIDTH-1:0] 	cnt;
logic [M-1:0] 			data_r;

always_ff @(posedge clk or negedge rst_n) begin
	if(rst_n == 0) begin
		state 	<= INIT;
		cnt 	<= 0;
		
		rdy_o	<= 0;
		vld_o	<= 0;
		dout	<= 0;
		data_r	<= 0;
	end else begin
		case(state) 
			INIT: begin
				state 	<= WORK;
				rdy_o	<= 1;
			end
			
			WORK: begin
				vld_o	<= 0;

				if(vld_i == 1) begin
					if(cnt < THRESHOLD) begin 	// Can take more data
						data_r 	<= (data_r << N) | din;
						state 	<= WORK;
						cnt 	<= cnt + N;
					end else begin	// Full, need to dump data
						dout	<= (data_r << cnt) | (din >> (N+cnt-M));		// {data_r[cnt-1:0], din[N-1:N+cnt-M]};
						vld_o	<= 1;	
						data_r	<= ( {M{1'b1}} >> (M-cnt) )  &  din;			//{ (N+cnt-M){1'b1} } & din;
						cnt	<= N+cnt-M;

						if(rdy_i == 1) begin 	// Dump directly
							state 	<= WORK;
						end else begin 			// go to Dump and wait
							state 	<= DUMP;
							rdy_o	<= 0;
						end
					end
				end else begin
					state 	<= WORK;
				end
			end
			
			DUMP: begin
				if(rdy_i == 1) begin 	// Dump directly
					state 	<= WORK;
					vld_o	<= 0;
					rdy_o	<= 1;
				end else begin 			// go to Dump and wait
					state 	<= DUMP;
					rdy_o	<= 0;
				end			
			end
		endcase
	end	
end


endmodule