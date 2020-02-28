/// Half of the two-phase clock domain crossing located in the source domain.
module cdc_src #(
    parameter type T = logic [31:0]
)(
    input  logic clk_i,
    input  logic rst_ni,
	
    input  T     data_i,
    input  logic valid_i,
    
	input  logic async_ack_i,

    output logic async_req_o,
    output T     async_data_o,
	
	output logic ready_o
);


localparam	WAIT_GRANT	= 2'b00,
			WAIT_ACK    = 2'b01;

logic 	[1:0] state;
logic async_ack_tx0, async_ack_tx1, async_ack_tx2;

always_ff @(posedge clk_i or negedge rst_ni) begin
	if(rst_ni == 0) begin
		{async_ack_tx2, async_ack_tx1, async_ack_tx0} <= 3'b000;
	end else begin
		{async_ack_tx2, async_ack_tx1, async_ack_tx0} <= {async_ack_tx1, async_ack_tx0, async_ack_i};
	end
end

always_ff @(posedge clk_i or negedge rst_ni) begin
	if(rst_ni == 0) begin
		state			<= WAIT_GRANT;
		async_req_o		<= 0;
		async_data_o	<= '0;
		ready_o			<= 1;
	end else begin
		case(state)
			WAIT_GRANT: begin
				if(valid_i && ready_o) begin
					ready_o			<= 0;
					async_req_o		<= ~async_req_o;
					async_data_o	<= data_i;
					ready_o			<= 0;
					state			<= WAIT_ACK;
				end else begin
					state	<= WAIT_GRANT;
				end
			end
			
			WAIT_ACK: begin
				if(async_ack_tx2 != async_ack_tx1) begin
					state	<= WAIT_GRANT;
					ready_o	<= 1;
				end else begin
					state	<= WAIT_ACK;
				end	
			end
		endcase
	end
end

endmodule