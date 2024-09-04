module fifo_fwft #( 
  DATA_WIDTH  = 8,
  FIFO_DEPTH  = 8,
  ADDR_WIDTH  = $clog2(FIFO_DEPTH),
  THRESHOLD   = 4
)(
  input logic                     clk,
  input logic                     rst_n,
  
  input logic                     ren_i,
  output logic [DATA_WIDTH-1:0]   rdata_o, 
  output logic                    empty_o,
  output logic                    aempty_o,
  
  input logic                     wen_i,
  input logic [DATA_WIDTH-1:0]    wdata_i,
  output logic                    full_o,
  
  output logic [ADDR_WIDTH:0]     count_o
);


logic [1:0]                     wen;
logic [1:0][DATA_WIDTH-1:0]     wdata;
logic [1:0]                     full;

logic [1:0]                     ren;
logic [1:0][DATA_WIDTH-1:0]     rdata;
logic [1:0]                     empty;

logic [ADDR_WIDTH : 0]          waddr_d,    waddr_q;    //  Addr of current writing
logic [ADDR_WIDTH : 0]          raddr_d,    raddr_q;    //  Addr of next reading
logic [ADDR_WIDTH : 0]          cnt_d,      cnt_q;

logic                           reading,    writing;
always_comb begin
  wdata[0]    = wdata_i;
  wdata[1]    = wdata_i;
  if(waddr_q[0] == 0) begin
    full_o  = full[0];
    wen[0]  = wen_i & (~full[0]);
    wen[1]  = 0;
  end else begin
    full_o  = full[1];
    wen[0]  = 0;
    wen[1]  = wen_i & (~full[1]);
  end

  if(raddr_q[0] == 0) begin
    ren[0]  = ren_i;
    ren[1]  = 0;
    empty_o = empty[0];
    rdata_o = rdata[0];
  end else begin
    ren[0]  = 0;
    ren[1]  = ren_i;    
    empty_o = empty[1];
    rdata_o = rdata[1];
  end
end

always_ff @(posedge clk or negedge rst_n) begin
  if(rst_n == 0) begin
    waddr_q <= '0;
    raddr_q <= '0;
    cnt_q   <= '0;
  end else begin
    waddr_q <= waddr_d;
    raddr_q <= raddr_d;
    cnt_q   <= cnt_d;
  end
end

always_comb begin
  reading = 0;
  writing = 0;
  
  waddr_d = waddr_q;
  raddr_d = raddr_q;
  cnt_d   = cnt_q;

  if(wen_i==1 && full_o==0) begin
    writing = 1;
    waddr_d = waddr_q + 1;
  end 

  if(ren_i==1 && empty_o==0) begin
    reading = 1;
    raddr_d = raddr_q + 1;
  end 

  if( (writing==1) && (reading==0) ) begin
    cnt_d   = cnt_q + 1;
  end else if( (writing==0) && (reading==1) ) begin
    cnt_d   = cnt_q - 1;
  end

  aempty_o    = (cnt_q <= THRESHOLD);
  count_o     = cnt_q;
end


fifo_bank #( 
  .DATA_WIDTH ( DATA_WIDTH    ),
  .FIFO_DEPTH ( FIFO_DEPTH>>1 )
) fifo_bank_a (  
  .clk        ( clk       ),
  .rst_n      ( rst_n     ),

  .wen        ( wen[0]    ),
  .wdata      ( wdata[0]  ),    
  .full_o     ( full[0]   ),

  .ren        ( ren[0]    ),
  .rdata      ( rdata[0]  ), 
  .empty_o    ( empty[0]  )
);

fifo_bank #( 
  .DATA_WIDTH ( DATA_WIDTH    ),
  .FIFO_DEPTH ( FIFO_DEPTH>>1 )
) fifo_bank_b (  
  .clk        ( clk       ),
  .rst_n      ( rst_n     ),

  .wen        ( wen[1]    ),
  .wdata      ( wdata[1]  ),    
  .full_o     ( full[1]   ),

  .ren        ( ren[1]    ),
  .rdata      ( rdata[1]  ), 
  .empty_o    ( empty[1]  )
);




endmodule
