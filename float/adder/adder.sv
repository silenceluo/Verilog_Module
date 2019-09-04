module adder(
    input logic         clk,
    input logic         rst_n,
    
    input logic [31:0]  a,
    input logic         a_valid,
    output logic        a_ready,
    
    input logic [31:0]  b,
    input logic         b_valid,
    output logic        b_ready    
    
    output logic [31:0] c,
    output logic        c_valid,
    input logic         c_ready 
);

logic           a_s;
logic [7:0]     a_exp;
logic [26:0]    a_man;

logic           b_s;
logic [7:0]     b_exp;
logic [26:0]    b_man;

logic           c_s;
logic [7:0]     c_exp;
logic [22:0]    c_man;


always_comb begin
    a_s     = a[31];
    a_exp   = a[30:23] - 127;
    a_man   = {a[22:0], 3'b0};
    
    b_s     = b[31];
    b_exp   = b[30:23] - 127;
    b_man   = {b[22:0], 3'b0};    
end

always_comb begin
    //if a is NaN or b is NaN return NaN 
    if ((a_exp == 128 && a_man != 0) || (a_exp == 128 && b_man != 0)) begin
    
    end else if (a_e == 128) begin  //if a is inf return inf
    
        if(b_e == 128 && (a_s != b_s)) begin    //if a is inf and signs don't match return nan
        
        end
    end else if (b_e == 128) begin  //if b is inf return inf

    end else if ((($signed(a_e) == -127) && (a_m == 0)) && (($signed(b_e) == -127) && (b_m == 0))) begin    
    
    end else if (($signed(a_e) == -127) && (a_m == 0)) begin //if a is zero return b
    
    end else if (($signed(b_e) == -127) && (b_m == 0)) begin //if b is zero return b
    
    end else begin
        //Denormalised Number
        if ($signed(a_e) == -127) begin
            a_e <= -126;
        end else begin
            a_m[26] <= 1;
        end
        //Denormalised Number
            if ($signed(b_e) == -127) begin
        b_e <= -126;
        end else begin
            b_m[26] <= 1;
        end
    end
end

endmodule
