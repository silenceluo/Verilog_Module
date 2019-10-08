module cdc_handshake_fsm #(
    parameter type T = logic [31:0]
)(
    input  logic src_rst_ni,
    input  logic src_clk_i,
    input  T     src_data_i,
    input  logic src_valid_i,
    output logic src_ready_o,

    input  logic dst_rst_ni,
    input  logic dst_clk_i,
    output T     dst_data_o,
    output logic dst_valid_o,
    input  logic dst_ready_i
);

// Asynchronous handshake signals.
(* dont_touch = "true" *) logic async_req;
(* dont_touch = "true" *) logic async_ack;
(* dont_touch = "true" *) T async_data;

cdc_src #(	.T(T)
) i_src (
    .rst_ni       ( src_rst_ni  ),
    .clk_i        ( src_clk_i   ),
    .data_i       ( src_data_i  ),
    .valid_i      ( src_valid_i ),
    .ready_o      ( src_ready_o ),
    .async_req_o  ( async_req   ),
    .async_ack_i  ( async_ack   ),
    .async_data_o ( async_data  )
);



// The receiver in the destination domain.
cdc_dst #(	.T(T)
) i_dst (
    .rst_ni       ( dst_rst_ni  ),
    .clk_i        ( dst_clk_i   ),
    .data_o       ( dst_data_o  ),
    .valid_o      ( dst_valid_o ),
    .ready_i      ( dst_ready_i ),
    .async_req_i  ( async_req   ),
    .async_ack_o  ( async_ack   ),
    .async_data_i ( async_data  )
);

endmodule