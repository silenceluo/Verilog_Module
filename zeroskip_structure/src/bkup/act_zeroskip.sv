module act_zeroskip #(
    parameter GROUP_SIZE    = 32,
    parameter GROUP_NZ_BITS = 16,
    parameter DATA_W        = 8,

    parameter ZNZ_BITS      = GROUP_SIZE,
    parameter NUM_GROUP     = ZNZ_BITS/GROUP_SIZE,
    parameter NZ_BITS       = NUM_GROUP*GROUP_NZ_BITS
) (
    input logic [ZNZ_BITS-1:0]              znz_din,
    input logic [ZNZ_BITS-1:0][DATA_W-1:0]  act_din,
    output logic [NZ_BITS-1:0][DATA_W-1:0]  act_enc_dout
);

logic [NUM_GROUP-1:0][GROUP_SIZE-1:0]                   znz_din_array;
logic [NUM_GROUP-1:0][GROUP_SIZE-1:0][DATA_W-1:0]       act_din_array;
logic [NUM_GROUP-1:0][GROUP_NZ_BITS-1:0][DATA_W-1:0]    act_enc_dout_array;


genvar  i;
generate
    for( i=0; i<NUM_GROUP; i++ ) begin  : gen_in
        assign znz_din_array[i] = znz_din[ (i+1)*GROUP_SIZE-1 : i*GROUP_SIZE ];
        assign act_din_array[i] = act_din[ (i+1)*GROUP_SIZE-1 : i*GROUP_SIZE ];
    end
endgenerate

generate
    for( i=0; i<NUM_GROUP; i++ ) begin  : gen_zeroskip
        zeroskip #(
            .GROUP_SIZE     ( GROUP_SIZE    ),
            .GROUP_NZ_BITS  ( GROUP_NZ_BITS ),
            .DATA_W         ( DATA_W        )
        ) zeroskip_i(
            .znz_din        ( znz_din_array[i]      ),
            .act_din        ( act_din_array[i]      ),
            .act_enc_dout   ( act_enc_dout_array[i] )
        );
    end
endgenerate 

generate
    for( i=0; i<NUM_GROUP; i++) begin   : gen_out
        assign act_enc_dout[(i+1)*GROUP_NZ_BITS-1 : i*GROUP_NZ_BITS]  = act_enc_dout_array[i]
    end
endgenerate

endmodule