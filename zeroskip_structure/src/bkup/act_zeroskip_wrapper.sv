module act_zeroskip_wrapper #(
    parameter M             = 8,
    parameter N             = 8,
    parameter DATA_W        = 8,

    parameter GROUP_SIZE    = 32,
    parameter GROUP_NZ_MAX  = 16,

    parameter ZNZ_SIZE          = GROUP_SIZE
) (
    input logic                         clk,
    input logic                         rst_n,
    input logic                         group_nz_sel,   //  0--8:32, 1--16:32

    input logic [GROUP_SIZE-1:0]        znz_din,
    input logic                         znz_din_vld_i,
    output logic                        znz_din_rdy_o,

    input logic [M-1:0][DATA_W-1:0]     act_din,
    input logic                         act_din_vld_i,
    output logic                        act_din_rdy_o,

    output logic [M-1:0][DATA_W-1:0]    act_enc_dout,
    output logic                        act_enc_vld_o,
    input logic                         act_enc_rdy_i
);

//  Need how many cycles to get the required 
localparam  ACT_IN_CYCLE    = (M==8) ? 4: ( (M==16) ? 2 : 1 );  
localparam  NZ8     = 8;
localparam  NZ16    = 16;

//  ZNZ and ENC fifo control signals
logic                               znz_fifo_clear;
logic [GROUP_SIZE-1:0]              znz_fifo_din;

logic [GROUP_SIZE-1:0]              znz_fifo_dout;
logic                               znz_fifo_ren;
logic                               znz_fifo_vld_o;


logic                               act_fifo_clear;
logic [GROUP_SIZE-1:0][DATA_W-1:0]  act_fifo_din;
logic                               act_fifo_wen;
logic                               act_fifo_rdy_o;

logic [GROUP_SIZE-1:0][DATA_W-1:0]  act_fifo_dout;
logic                               act_fifo_ren;
logic                               act_fifo_vld_o;


logic                                       enc_fifo_clear;
logic [GROUP_NZ_MAX-1:0][DATA_W-1:0]   enc_fifo_din;
logic                                       enc_fifo_wen;
logic                                       enc_fifo_rdy_o;

logic [GROUP_NZ_MAX-1:0][DATA_W-1:0]   enc_fifo_dout;
logic                                       enc_fifo_ren;
logic                                       enc_fifo_vld_o;



typedef enum logic [0:0] {
    GATHER_ACT,
    WAIT_ACT_FIFO
} state_t;

state_t state_d, state_q;

logic [$clog2(ACT_IN_CYCLE)-1 : 0]  act_index_d,    act_index_q;
logic [GROUP_SIZE-1:0][DATA_W-1:0]  act_din_reg_d,  act_din_reg_q;


always_ff @( posedge clk or negedge rst_n ) begin
    if(rst_n == 1'b0) begin
        state_q         <= GATHER_ACT;
        act_index_q     <= '0;
        act_din_reg_q   <= '0;
    end else begin
        //  if(enable == 1'b1) begin
        state_q         <= state_d;
        act_index_q     <= act_index_d;
        act_din_reg_q   <= act_din_reg_d;
        //  end
    end
end

always_comb begin
    state_d         = state_q;

    act_din_rdy_o   = 1'b0;

    act_index_d     = act_index_q;
    act_din_reg_d   = act_din_reg_q;

    act_fifo_din    = act_din_reg_d;
    act_fifo_clear  = 1'b0;

    znz_fifo_clear  = 1'b0;
    enc_fifo_clear  = 1'b0;

    case(state_q)
        GATHER_ACT:  begin
            act_din_rdy_o = 1;
            if( act_din_vld_i == 1'b1) begin
                act_din_reg_d = {act_din_reg_d[GROUP_SIZE-M-1:0], act_din};

                if(act_index_q+1 == ACT_IN_CYCLE) begin
                    act_fifo_wen    = 1'b1;
                    act_index_d     = 0;
                    if( act_fifo_rdy_o == 1'b1 ) begin
                        state_d     = GATHER_ACT;
                    end else begin
                        state_d     = WAIT_ACT_FIFO;
                    end
                    act_index_d = 0;
                end else begin
                    act_index_d = act_index_q + 1;
                end
            end
        end

        WAIT_ACT_FIFO: begin
            act_fifo_wen    = 1'b1;

            if( act_fifo_rdy_o == 1'b1 ) begin
                state_d = GATHER_ACT;
            end else begin
                state_d = WAIT_ACT_FIFO;
            end
        end

        default: begin
            state_d         = state_q;
        end
    endcase
end


fifo_slice #(
    .t  ( logic [GROUP_SIZE-1:0]    )
) znz_fifo_u(
    .clk_i      ( clk   ),
    .rst_ni     ( rst_n ),
    .clear_i    ( znz_fifo_clear    ),

    .din_i      ( znz_fifo_din      ), 
    .vld_i      ( znz_din_vld_i     ),
    .rdy_o      ( znz_din_rdy_o     ),
    
    .dout_o     ( znz_fifo_dout     ),
    .vld_o      ( znz_fifo_vld_o    ),
    .rdy_i      ( znz_fifo_ren      )
);


fifo_slice #(
    .t  ( logic [GROUP_SIZE-1:0][DATA_W-1:0])
) act_fifo_u(
    .clk_i      ( clk   ),
    .rst_ni     ( rst_n ),
    .clear_i    ( act_fifo_clear    ),

    .din_i      ( act_fifo_din      ),
    .vld_i      ( act_fifo_wen      ),
    .rdy_o      ( act_fifo_rdy_o    ),
    
    .dout_o     ( act_fifo_dout     ),
    .vld_o      ( act_fifo_vld_o    ),
    .rdy_i      ( act_fifo_ren      )
);

always_comb begin
    act_fifo_ren    = 0;
    znz_fifo_ren    = 0;
    enc_fifo_wen    = 1'b0;    
    if( (znz_fifo_vld_o==1) && (act_fifo_vld_o==1) && (enc_fifo_rdy_o==1) ) begin
        act_fifo_ren    = 1;
        znz_fifo_ren    = 1;
        enc_fifo_wen    = 1'b1;
    end
end

zeroskip #(
    .GROUP_SIZE         ( GROUP_SIZE        ),
    .GROUP_NZ_MAX  ( GROUP_NZ_MAX ),
    .DATA_W             ( DATA_W            )
) zeroskip_i (
    .znz_din        ( znz_fifo_dout ),
    .act_din        ( act_fifo_dout ),
    .act_enc_dout   ( enc_fifo_din  )
);


fifo_slice #(
    .t  ( logic [GROUP_NZ_MAX-1:0][DATA_W-1:0] )
) act_dout_fifo_u(
    .clk_i      ( clk   ),
    .rst_ni     ( rst_n ),
    .clear_i    ( enc_fifo_clear    ),

    .vld_i      ( enc_fifo_wen      ),
    .din_i      ( enc_fifo_din      ),    
    .rdy_o      ( enc_fifo_rdy_o    ),
    
    .rdy_i      ( enc_fifo_ren      ),
    .dout_o     ( enc_fifo_dout     ),
    .vld_o      ( enc_fifo_vld_o    )
);

////////////////////////////////////////////////////////////////////////////////
//  MAC64:  M=N=8:  NZ=8,16:    Need 1 or 2 cycles to dump one data
//  MAC256: M=N=16: NZ=8,16:    Need 1 or 2 cycles to generate one dump data   
//  MAC1K:  M=N=32: NZ=8,16:    Need 2 or 4 cycles to generate one dump data
//  state_M8NZ16:   M=N=8, NZ=16, Need two cycles to dump one data
//  state_others:   others, need to 1 or multiple cycles to generate 1 data
////////////////////////////////////////////////////////////////////////////////
typedef enum logic [0:0] {
    ACT_OUT_FIRST,
    DUMP_ACT_DOUT
} state_M8NZ16_t;

state_M8NZ16_t                              state_M8NZ16_d,         state_M8NZ16_q;

logic                                       enc_fifo_ren_M8NZ16;
logic [GROUP_NZ_MAX-1:0][DATA_W-1:0]   enc_reg_M8NZ16_d,      enc_reg_M8NZ16_q;
logic                                       enc_index_M8NZ16_d,     enc_index_M8NZ16_q;

logic [M-1:0][DATA_W-1:0]                   enc_dout_M8NZ16;
logic                                       enc_vld_M8NZ16;


always_ff @( posedge clk or negedge rst_n ) begin
    if(rst_n == 1'b0) begin
        state_M8NZ16_q      <= ACT_OUT_FIRST;
        enc_reg_M8NZ16_q    <= '0;
        enc_index_M8NZ16_q  <= '0;
    end else begin
        state_M8NZ16_q      <= state_M8NZ16_d;
        enc_reg_M8NZ16_q    <= enc_reg_M8NZ16_d;
        enc_index_M8NZ16_q  <= enc_index_M8NZ16_d;
    end
end


always_comb begin
    state_M8NZ16_d      = state_M8NZ16_q;
    enc_reg_M8NZ16_d    = enc_reg_M8NZ16_q;
    enc_index_M8NZ16_d  = enc_index_M8NZ16_q;

    enc_fifo_ren_M8NZ16 = 1'b0;
    enc_dout_M8NZ16     = '0;
    enc_vld_M8NZ16      = 1'b0;
    case(state_M8NZ16_q)
        ACT_OUT_FIRST: begin
            enc_fifo_ren_M8NZ16 = 1'b1;
            if(enc_fifo_vld_o == 1'b1) begin
                enc_vld_M8NZ16  = 1'b1;

                if(act_enc_rdy_i == 1) begin
                    enc_dout_M8NZ16     = enc_fifo_dout[M-1 : 0];
                    enc_reg_M8NZ16_d    = {'0, enc_fifo_dout[2*M-1 : M]};
                    enc_index_M8NZ16_d  = 1;
                end else begin
                    enc_reg_M8NZ16_d    = enc_fifo_dout;
                    enc_index_M8NZ16_d  = 0;
                end
                state_M8NZ16_d = DUMP_ACT_DOUT;
            end 
        end

        DUMP_ACT_DOUT: begin
            enc_vld_M8NZ16      = 1'b1;

            if(act_enc_rdy_i == 1) begin
                enc_dout_M8NZ16     = enc_reg_M8NZ16_q[M-1 : 0];
                if(enc_index_M8NZ16_q == 1) begin
                    enc_index_M8NZ16_d  = '0;
                    enc_reg_M8NZ16_d    = '0;
                    state_M8NZ16_d      = ACT_OUT_FIRST;   
                end else begin
                    enc_index_M8NZ16_d  = 1;
                    enc_reg_M8NZ16_d    = { '0, enc_reg_M8NZ16_q[GROUP_NZ_MAX-M-1 : M] };
                    state_M8NZ16_d      = DUMP_ACT_DOUT;      
                end
            end
        end
    endcase
end







typedef enum logic [1:0] {
    ENC_OUT_FIRST,
    WAIT_DOUT_RDY,
    ENC_OUT_GATHER
} state_others_t;
state_t                                     state_others_d,     state_others_q;

logic                                       enc_fifo_ren_others;
logic [M-1:0][DATA_W-1:0]                   enc_dout_others;
logic                                       enc_vld_others;

logic [2:0]                                 gather_index_d,     gather_index_q;
logic [2:0]                                 gather_cnt;
logic [M-1:0][DATA_W-1:0]                   enc_reg_others_d,   enc_reg_others_q;

always_ff @( posedge clk or negedge rst_n ) begin
    if(rst_n == 1'b0) begin
        state_others_q      <= ENC_OUT_FIRST;
        enc_reg_others_q    <= '0;
        gather_index_q      <= '0;
    end else begin
        state_others_q      <= state_others_d;
        enc_reg_others_q    <= enc_reg_others_d;
        gather_index_q      <= gather_index_d;
    end
end

////////////////////////////////////////////////////////////////////////////////
//  Calcualte that how many cycles the module needs to gather all the data for 
//  one MAC (M Bytes)
////////////////////////////////////////////////////////////////////////////////
always_comb begin
    gather_cnt = 1;
    if( (M==8) && (N==8) ) begin
        if( group_nz_sel == 0 ) begin
            gather_cnt  = 1;
        end 
    end else if( (M==16) && (N==16) ) begin 
        if( group_nz_sel == 0 ) begin
            gather_cnt  = 2;
        end else if( group_nz_sel==1 ) begin
            gather_cnt  = 1;
        end
    end else if( (M==32) && (N==32) ) begin 
        if( group_nz_sel == 0 ) begin
            gather_cnt  = 4;
        end else if( group_nz_sel == 1 ) begin
            gather_cnt  = 2;
        end
    end
end


always_comb begin
    enc_fifo_ren_others = 1'b0;
    state_others_d      = state_others_q;
    enc_reg_others_d    = enc_reg_others_q;
    enc_vld_others      = 0;
    gather_index_d      = gather_index_q;

    act_enc_dout        = enc_reg_others_d;

    case(state_others_q)
        ENC_OUT_FIRST: begin
            enc_fifo_ren_others = 1'b1;
            if(enc_fifo_vld_o == 1'b1) begin
                if( group_nz_sel == 0 ) begin   // 8:32
                    enc_reg_others_d[NZ8-1:0]   = enc_fifo_dout[NZ8-1:0];
                end else begin  //  16:32
                    enc_reg_others_d[NZ16-1:0]  = enc_fifo_dout[NZ16-1:0];
                end 

                if(gather_cnt == 1) begin   //already full
                    enc_vld_others  = 1'b1;
                    if(act_enc_rdy_i == 1) begin
                        state_others_d      = ENC_OUT_FIRST;
                    end else begin
                        state_others_d      = WAIT_DOUT_RDY;
                    end
                end else begin
                    state_others_d  = ENC_OUT_GATHER;
                    gather_index_d  = 1;
                end
            end
        end

        ENC_OUT_GATHER: begin
            enc_fifo_ren_others = 1;
            if(enc_fifo_vld_o == 1'b1) begin
                if( group_nz_sel == 0 ) begin   // 8:32
                    enc_reg_others_d    = { enc_reg_others_q[M-NZ8-1:0], enc_fifo_dout[NZ8-1:0] }; 
                end else begin  //  16:32
                    enc_reg_others_d    = { enc_reg_others_q[M-NZ16-1:0], enc_fifo_dout[NZ16-1:0] }; 
                end 

                if( gather_index_q+1 == gather_cnt ) begin
                    enc_vld_others  = 1'b1;
                    if(act_enc_rdy_i == 1) begin
                        state_others_d  = ENC_OUT_FIRST;
                        gather_index_d  = 0;
                    end else begin
                        state_others_d  = WAIT_DOUT_RDY;
                    end
                end else begin
                    gather_index_d  = gather_index_q + 1;
                    state_others_d  = ENC_OUT_GATHER;
                end
            end            
        end

        WAIT_DOUT_RDY: begin
            enc_vld_others = 1;
            if(act_enc_rdy_i == 1) begin
                state_others_d  = ENC_OUT_FIRST;
                gather_index_d  = 0;
            end else begin
                state_others_d  = WAIT_DOUT_RDY;
            end                
        end
    endcase
end


always_comb begin
    if( M==8 && group_nz_sel==1) begin
        act_enc_dout    = enc_dout_M8NZ16;
        act_enc_vld_o   = enc_vld_M8NZ16;
    end else begin
        act_enc_dout    = enc_dout_others;
        act_enc_vld_o   = enc_vld_others;     
    end
end




endmodule