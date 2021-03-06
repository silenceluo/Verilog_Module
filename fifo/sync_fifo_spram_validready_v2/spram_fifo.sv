module spram_fifo #(DATA_WIDTH  = 8,
                    FIFO_DEPTH  = 32,
                    ADDR_WIDTH  = $clog2(FIFO_DEPTH)
)(  input logic                     clk,
    input logic                     rst_n,

    input  logic [DATA_WIDTH-1:0]   in_data,
    input  logic                    in_valid,
    output logic                    in_ready,
    
    output logic [DATA_WIDTH-1:0]   out_data,
    output logic                    out_valid,
    input  logic                    out_ready
);


logic [DATA_WIDTH-1:0]  bank0_in_data;
logic                   bank0_in_valid;
logic                   bank0_in_ready;

logic [DATA_WIDTH-1:0]  bank0_out_data;
logic                   bank0_out_valid;
logic                   bank0_out_ready;


logic [DATA_WIDTH-1:0]  bank1_in_data;
logic                   bank1_in_valid;
logic                   bank1_in_ready;

logic [DATA_WIDTH-1:0]  bank1_out_data;
logic                   bank1_out_valid;
logic                   bank1_out_ready;

logic   in_exec, out_exec;
logic   bank0_in_exec, bank1_in_exec;
logic   bank0_out_exec, bank1_out_exec;

logic   in_sel, out_sel;
logic   out_sel_r1; // Memory delay is 1 cycle, thus need to remember the sel for 1 cycle

logic   in_sel_next;
logic   out_sel_next;

always_comb begin
    in_exec     = in_ready & in_valid;
    out_exec    = out_ready & out_valid;   

    bank0_in_exec  = bank0_in_ready & bank0_in_valid;
    bank1_in_exec  = bank1_in_ready & bank1_in_valid; 
     
    bank0_out_exec  = bank0_out_ready & bank0_out_valid;
    bank1_out_exec  = bank1_out_ready & bank1_out_valid;        
end




always_comb begin
    if(in_sel == 0) begin
        if(bank0_in_exec) begin
            in_sel_next = 1;
        end else begin
            in_sel_next = 0;
        end
    end else if(in_sel == 1) begin
        if(bank1_in_exec) begin
            in_sel_next = 0;
        end else begin
            in_sel_next = 1;
        end
    end
    
    if(out_sel == 0) begin
        if(bank0_out_exec) begin
            out_sel_next = 1;
        end else begin
            out_sel_next = 0;
        end
    end else if(out_sel == 1) begin
        if(bank1_out_exec) begin
            out_sel_next = 0;
        end else begin
            out_sel_next = 1;
        end
    end
end



always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        in_sel      <= 0;
        out_sel     <= 0;        
        out_sel_r1  <= 0;  
    end else begin
        in_sel      <= in_sel_next;
        out_sel     <= out_sel_next;        
        out_sel_r1  <= out_sel;
    end
end

always_comb begin
    bank0_in_data   = in_sel ? 0 : in_data;
    bank0_in_valid  = in_sel ? 0 : in_valid;

    bank1_in_data   = in_sel ? in_data : 0;
    bank1_in_valid  = in_sel ? in_valid : 0;  
    
    in_ready        = in_sel ? bank1_in_ready : bank0_in_ready;

    bank0_out_ready = out_sel ? 0 : out_ready;
    bank1_out_ready = out_sel ? out_ready : 0; 
end



always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_valid   <= 0;
    end else begin
        if(out_sel == 0) begin
            out_valid   <= bank0_out_valid;
        end else begin
            out_valid   <= bank1_out_valid;
        end 
    end
end
assign out_data = out_sel_r1 ? bank1_out_data : bank0_out_data;


fifo_bank bank_0(   
                    .clk        ( clk   ),
                    .rst_n      ( rst_n ),

                    .in_data    ( bank0_in_data     ),
                    .in_valid   ( bank0_in_valid    ),
                    .in_ready   ( bank0_in_ready    ),

                    .out_data   ( bank0_out_data    ),
                    .out_valid  ( bank0_out_valid   ),
                    .out_ready  ( bank0_out_ready   )  
);

fifo_bank bank_1(   
                    .clk        ( clk   ),
                    .rst_n      ( rst_n ),

                    .in_data    ( bank1_in_data     ),
                    .in_valid   ( bank1_in_valid    ),
                    .in_ready   ( bank1_in_ready    ),

                    .out_data   ( bank1_out_data    ),
                    .out_valid  ( bank1_out_valid   ),
                    .out_ready  ( bank1_out_ready   )  
);

endmodule
