module fifo_bank #( 
  DATA_WIDTH  = 8,
  FIFO_DEPTH  = 16,
  ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  
  input logic                   clk,
  input logic                   rst_n,

  input logic                   wen,
  input logic [DATA_WIDTH-1:0]  wdata,  
  output logic                  full_o,
      
  input logic                   ren,
  output logic [DATA_WIDTH-1:0] rdata, 
  output logic                  empty_o
);

typedef enum logic [1:0] {
  Idle,
  FifoEmpty,
  Process,
  WriteDelay
} state_t;

state_t                     state_d,  state_q;

logic                       mem_cs,   mem_wea;
logic [ADDR_WIDTH-1 : 0]    mem_addr;
logic [DATA_WIDTH-1 : 0]    mem_din;
logic [DATA_WIDTH-1 : 0]    mem_dout;

logic [ADDR_WIDTH : 0]      waddr_d,  waddr_q;    //  Addr of current writing
logic [ADDR_WIDTH : 0]      raddr_d,  raddr_q;    //  Addr of next reading

logic [DATA_WIDTH-1 : 0]    wdata_d,  wdata_q;    //  Write data buffer
logic [DATA_WIDTH-1 : 0]    rdata_d,  rdata_q;    //  Read data buffer

logic [ADDR_WIDTH : 0]      count_d,  count_q;    //  Number elements in FIFO
logic                       onlyone;                //  Fifo has only one data remaining

logic                       mux_d,    mux_q;      //  mux rdata from buffer reg and memory

always_ff @(posedge clk or negedge rst_n) begin
  if(rst_n == 0) begin
    state_q <= Idle;
    waddr_q <= '0;
    raddr_q <= '0;
    count_q <= '0;

    wdata_q <= '0;
    rdata_q <= '0;

    mux_q   <= 0;
  end else begin
    state_q <= state_d;
    waddr_q <= waddr_d;
    raddr_q <= raddr_d;
    count_q <= count_d;

    wdata_q <= wdata_d; //  Read/Write buffer registers
    rdata_q <= rdata_d;

    mux_q   <= mux_d;
  end
end

always_comb begin
  state_d = state_q;

  waddr_d = waddr_q;
  raddr_d = raddr_q;
  count_d = count_q;

  wdata_d = wdata_q;
  rdata_d = rdata_q;

  mem_cs  = 0;
  mem_wea = 0;
  mem_addr= '0;
  mem_din = '0;

  onlyone = ( waddr_q == raddr_q);

  empty_o = (count_q == 0);
  full_o  = (count_q == FIFO_DEPTH);

  mux_d   = mux_q;

  case(state_q)
    Idle: begin
      state_d = FifoEmpty;
    end

    FifoEmpty: begin
      if(wen == 1) begin
        mem_cs  = 1;
        mem_wea = 1;
        mem_addr= waddr_q;
        mem_din = wdata;

        waddr_d = waddr_q + 1;  //  Update w pointer

        rdata_d = wdata;        //  Save data to rdata_d for FWFT
        raddr_d = raddr_q + 1;  //  Data in current address has been sent to rdata_q
                                //  Get ready to read next one
        count_d = count_q + 1;

        state_d = Process;

        mux_d   = 1;            // Need to mux read data from the rdata_q
      end
    end

    //  Todo: when conflict, may write before read as the current may be the last data
    Process: begin
      if( wen && ren ) begin      //  Read the data first when conflict
        if(onlyone == 0) begin
          mem_cs  = 1;        //  Read the data out and mux from mem out
          mem_wea = 0;
          mem_addr= raddr_q;
          mux_d   = 0;

          raddr_d = raddr_q + 1;  //  Update r pointer
          count_d = count_q - 1;
          wdata_d = wdata;        //  Save data to wdata_q to write next cycle

          state_d = WriteDelay;   //  Write mem
        end else begin      // Fifo is onlyone now, just write the data and pass to buffer reg
          mem_cs  = 1;    // The write can be optimed out to save power
          mem_wea = 1;
          mem_addr= waddr_q;
          mem_din = wdata;

          waddr_d = waddr_q + 1;  //  Update r pointer
          raddr_d = raddr_q + 1;  //  Update r pointer
          count_d = count_q;
          rdata_d = wdata;        //  Save data to rdata_d for FWFT
          mux_d   = 1;            //  Mux the data from reg

          state_d = Process;      //  Still onlyone=1 in Process
        end
      end else if( wen == 1 ) begin
        if(full_o == 0) begin       // full_o
          mem_cs  = 1;
          mem_wea = 1;
          mem_addr= waddr_q;
          mem_din = wdata;

          waddr_d = waddr_q + 1;  //  Update w pointer
          count_d = count_q + 1;
        end
      end else if( ren == 1 ) begin
        if(empty_o == 0) begin      //  Not empty
          if(onlyone == 0) begin  //  
            mem_cs  = 1;
            mem_wea = 0;
            mem_addr= raddr_q;
            mux_d   = 0;        //  Mux from mem out

            raddr_d = raddr_q + 1;  //  Update r pointer
            count_d = count_q - 1;

            if(count_d == 0) begin
                state_d = FifoEmpty;    //  This line should never be valid
            end else begin
                state_d = Process;
            end
          end else begin          //  Only one left and already in buffer reg
            raddr_d = raddr_q;  //  No need to update the pointer, FifoEmpty will do it instead
            count_d = count_q - 1;
            state_d = FifoEmpty;
          end
        end
      end 
    end

    WriteDelay: begin
      mem_cs  = 1;
      mem_wea = 1;
      mem_addr= waddr_q;
      mem_din = wdata_q;

      waddr_d = waddr_q + 1;  //  Update w pointer
      count_d = count_q + 1;

      state_d = Process;          //  WR & RD last cycle, must be idle this cycle
    end

    default: begin
      state_d = state_q; 
    end
  endcase
end

spram #(
  .DATA_WIDTH ( DATA_WIDTH    ),
  .FIFO_DEPTH ( FIFO_DEPTH    )
) U0 (
  .clk        ( clk       ),
  .rst_n      ( rst_n     ),

  .cs         ( mem_cs    ),
  .we         ( mem_wea   ),

  .addr       ( mem_addr  ),
  .wdata      ( mem_din   ),
  .rdata      ( mem_dout  )
);

assign rdata = mux_q ? rdata_q: mem_dout;

endmodule

