/*module zeroskip #(
    parameter GROUP_SIZE    = 32,
    parameter GROUP_NZ_MAX  = 16,   //  8:32 and 16:32 must share this

    parameter DATA_W        = 8
) (
    input logic [GROUP_SIZE-1:0]                    znz_din,
    input logic [GROUP_SIZE-1:0][DATA_W-1:0]        act_din,
    output logic [GROUP_NZ_MAX-1:0][DATA_W-1:0]     act_enc_dout
);

////////////////////////////////////////////////////////////////////////////////
//  Define the parameters and local parameters
////////////////////////////////////////////////////////////////////////////////
localparam  NUM_GROUP           = 4;
localparam  QUAR_GROUP_SIZE     = GROUP_SIZE >> 2;
localparam  QUAR_GROUP_NZ_MAX   = QUAR_GROUP_SIZE;

logic [QUAR_GROUP_SIZE-1:0]                 group_znz_din   [3:0];
logic [QUAR_GROUP_SIZE-1:0][DATA_W-1:0]     group_act_din   [3:0];
logic [QUAR_GROUP_NZ_MAX-1:0][DATA_W-1:0]   group_enc_dout  [3:0];
logic [$clog2(QUAR_GROUP_SIZE) : 0]         group_cnt_nz    [3:0];
logic [$clog2(GROUP_NZ_MAX) : 0]            pre_nz_cnt      [3:0];

//  Divide the data into groups
genvar m, n;
generate 
    for ( m=0; m<NUM_GROUP; m++ ) begin
        for ( n=0; n<QUAR_GROUP_SIZE; n++ ) begin
            assign group_znz_din[m][n]  = znz_din[m*QUAR_GROUP_SIZE + n];
            assign group_act_din[m][n]  = act_din[m*QUAR_GROUP_SIZE + n];
        end
        //  Fixed for group size 32, and 4 sub groups
        assign group_cnt_nz[m]  = group_znz_din[m][0] + group_znz_din[m][1] + group_znz_din[m][2] + group_znz_din[m][3] 
                                + group_znz_din[m][4] + group_znz_din[m][5] + group_znz_din[m][6] + group_znz_din[m][7] ;
    end

    assign pre_nz_cnt[0]    = 0;
    assign pre_nz_cnt[1]    = group_cnt_nz[0];
    assign pre_nz_cnt[2]    = group_cnt_nz[0] + group_cnt_nz[1];
    assign pre_nz_cnt[3]    = group_cnt_nz[0] + group_cnt_nz[1] + group_cnt_nz[2];
endgenerate

//  Call the znz-8 kernels
generate
    for ( m=0; m<NUM_GROUP; m++ ) begin
        zeroskip_kernel zeroskip_kernel_i (
            .znz_din        ( group_znz_din[m]  ),
            .act_din        ( group_act_din[m]  ),
            .act_enc_dout   ( group_enc_dout[m] )
        );
    end
endgenerate

//  combine and Reorg the data

always_comb begin 
    act_enc_dout = '0;

    for(int i=0; i<group_cnt_nz[0]; i++) begin
        act_enc_dout[i] = group_enc_dout[0][i];
    end

    for(int i=0; i<group_cnt_nz[1]; i++) begin
        act_enc_dout[i + pre_nz_cnt[1]] = group_enc_dout[1][i];
    end

    for(int i=0; i<group_cnt_nz[2]; i++) begin
        act_enc_dout[i + pre_nz_cnt[2]] = group_enc_dout[2][i];
    end

    for(int i=0; i<group_cnt_nz[3]; i++) begin
        act_enc_dout[i + pre_nz_cnt[3]] = group_enc_dout[3][i];
    end
end

endmodule






module zeroskip_kernel #(
    parameter GROUP_SIZE    = 8,
    parameter GROUP_NZ_MAX  = 8,   //  8:32 and 16:32 must share this

    parameter DATA_W        = 8
) (
    input logic [GROUP_SIZE-1:0]                    znz_din,
    input logic [GROUP_SIZE-1:0][DATA_W-1:0]        act_din,
    output logic [GROUP_NZ_MAX-1:0][DATA_W-1:0]     act_enc_dout
);


logic [$clog2(GROUP_SIZE)-1 : 0]    index;

always_comb begin
    index           = '0;
    act_enc_dout    = '0;

    for(int i=0; i<GROUP_SIZE; i++) begin
        if(znz_din[i] == 1'b1) begin
            act_enc_dout[index] = act_din[i];
            index               = index + 1;
        end
    end
end

endmodule
*/

