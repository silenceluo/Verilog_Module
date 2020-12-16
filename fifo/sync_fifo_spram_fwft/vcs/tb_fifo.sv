module tb_fifo; 
    parameter   DATA_WIDTH  = 8,
                FIFO_DEPTH  = 8,
                ADDR_WIDTH  = $clog2(FIFO_DEPTH);
               
    logic                   clk;
    logic                   rst_n;

    logic                   wen,    wen_q;
    logic [DATA_WIDTH-1:0]  wdata,  wdata_q;    
    logic                   full;

    logic                   ren,    ren_q;    
    logic [DATA_WIDTH-1:0]  rdata; 
    logic                   empty;
    logic                   aempty;

    logic [ADDR_WIDTH:0]    count; 
    
    always_ff @(posedge clk) begin
        wen_q   <= wen;
        wdata_q <= wdata;
        ren_q   <= ren;
    end


    fifo_fwft #( 
        .DATA_WIDTH ( DATA_WIDTH    ),
        .FIFO_DEPTH ( FIFO_DEPTH    )
    )(
        .clk        ( clk       ),
        .rst_n      ( rst_n     ),

        .ren_i      ( ren_q     ),
        .rdata_o    ( rdata     ), 
        .empty_o    ( empty     ),
        .aempty_o   ( aempty    ),      

        .wen_i      ( wen_q     ),
        .wdata_i    ( wdata_q   ),    
        .full_o     ( full      ),

        .count_o    (count      )
    );

    initial begin
        clk     = 0; 
        rst_n   = 0;  
        ren     = 0; 
        wen     = 0; 
        wdata   = 0;
            
        #10 rst_n = 1; 

        #15 wen = 1;    wdata = 1;
        #10 wen = 1;    wdata = 2;  ren = 1;
        #10 wen = 1;    wdata = 3;  ren = 1;
        #10 wen = 1;    wdata = 4;  ren = 1;
        #10 wen = 1;    wdata = 5;  ren = 1;
        #10 wen = 1;    wdata = 6;  ren = 1;
        #10 wen = 1;    wdata = 7;  ren = 1;
        #10 wen = 1;    wdata = 8;  ren = 1;
        #10 wen = 1;    wdata = 9;  ren = 1;
        #10 wen = 1;    wdata = 10; ren = 1;
        #10 wen = 0;    wdata = 11; ren = 1;
        #10 wen = 0;    wdata = 0;  ren = 1;
        #10 wen = 0;    wdata = 0;  ren = 1;
        #10 wen = 0;    wdata = 0;  ren = 1;
        #10 wen = 0;    wdata = 0;  ren = 1;  

        #10 wen = 0;    wdata = 0;  ren = 0;
        #20 wen = 0;    wdata = 0;  ren = 0;
        #10 wen = 1;    wdata = 1;  ren = 0;  
        #10 wen = 0;    wdata = 0;
        #20;
        #10 wen = 1;    wdata = 2;  ren = 1;  
        #10 wen = 0;    wdata = 0;  ren = 0;  
        #20;
        #10 wen = 1;    wdata = 3;  ren = 0;  
        #10 wen = 0;    wdata = 4;  ren = 1;  
        #10 wen = 1;    wdata = 5;  ren = 0;  
        #10 wen = 1;    wdata = 6;  ren = 0;  
        #10 wen = 1;    wdata = 7;  ren = 0;  
        #10 wen = 1;    wdata = 8;  ren = 0;  
        #10 wen = 1;    wdata = 9;  ren = 0;  
        #10 wen = 1;    wdata = 10;  ren = 0;  
        #10 wen = 1;    wdata = 11;  ren = 0;  
        #10 wen = 1;    wdata = 12;  ren = 0;  
        #10 wen = 1;    wdata = 13;  ren = 0;  
        #10 wen = 1;    wdata = 14;  ren = 0;  
        #10 wen = 1;    wdata = 15;  ren = 0;  
    end 
    
    always  begin
        #5 clk = !clk; 
    end

   
  initial 
  #1000 $finish; 
    
  //Rest of testbench code after this line 
    initial begin
        $fsdbDumpfile("encoder.fsdb");
        $fsdbDumpvars();
    end

endmodule
