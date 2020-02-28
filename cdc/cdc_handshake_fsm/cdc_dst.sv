module cdc_dst #(
    parameter type T = logic
)(
    input  logic clk_i,
    input  logic rst_ni,
    input  logic ready_i,
    
	input  logic async_req_i,
    input  T     async_data_i,
	
    output T     data_o,
    output logic valid_o,
	
	output logic async_ack_o
);

localparam	WAIT_GRANT 	= 2'b00,
			WAIT_READY	= 2'b01,
			GOBACK		= 2'b10;

logic [1:0] state;

logic async_req_rx0, async_req_rx1, async_req_rx2;

always_ff @(posedge clk_i or negedge rst_ni) begin
	if(rst_ni == 0) begin
		{async_req_rx2, async_req_rx1, async_req_rx0} <= 3'b000;
	end else begin
		{async_req_rx2, async_req_rx1, async_req_rx0} <= {async_req_rx1, async_req_rx0, async_req_i};
	end
end

always_ff @(posedge clk_i or negedge rst_ni) begin
	if(rst_ni == 0) begin
		state 	<= WAIT_GRANT;
		valid_o	<= 0;
		data_o	<= '0;
		async_ack_o	<= 0;
	end else begin
		case(state)
			WAIT_GRANT: begin
				if( async_req_rx2 != async_req_rx1 ) begin
					valid_o 	<= 1;
					data_o		<= async_data_i;
					
					// If next stage is ready, data is sent
					if(ready_i == 1) begin
						state		<= GOBACK;
						async_ack_o	<= ~async_ack_o;
					end else begin
						state	<= WAIT_READY;
					end
				end else begin
					valid_o <= 0;
					state 	<= WAIT_GRANT;
				end
			end

			WAIT_READY:	begin
				// If next stage is ready, data is sent
				if(ready_i == 1) begin
					state		<= GOBACK;
					async_ack_o	<= ~async_ack_o;
				end else begin
					state	<= WAIT_READY;
				end
			end
			
			GOBACK: begin
				valid_o	<= 0;
				state	<= WAIT_GRANT;
			end
		endcase
	end
end

endmodule