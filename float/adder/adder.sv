/////////////////////////////////////////////////////////////////////////////////
// FP32 adder design, all combinational logic, but split the module into several 
// stages thus can be easily pieplied. The stages are:
// Special case (NaN, zero, etc)
// Align
// Add
// Normalize
// Round
// Pack 
/////////////////////////////////////////////////////////////////////////////////


module adder(
    input logic         clk,
    input logic         rst_n,
    
    input logic [31:0]  a,
    input logic         a_valid,
    output logic        a_ready,
    
    input logic [31:0]  b,
    input logic         b_valid,
    output logic        b_ready,
    
    output logic [31:0] c,
    output logic        c_valid,
    input logic         c_ready 
);

// Decompose the input data
logic           a_s;
logic [7:0]     a_e;
logic [26:0]    a_m;

logic           b_s;
logic [7:0]     b_e;
logic [26:0]    b_m;

logic           c_s;
logic [7:0]     c_e;
logic [23:0]    c_m;



// Preprocess
logic           special;

logic           pre_a_s;
logic [7:0]     pre_a_e;
logic [26:0]    pre_a_m;

logic           pre_b_s;
logic [7:0]     pre_b_e;
logic [26:0]    pre_b_m;




always_comb begin
    a_s     = a[31];
    a_e     = a[30:23] - 127;
    a_m     = {1'b0, a[22:0], 3'b0};
    
    b_s     = b[31];
    b_e     = b[30:23] - 127;
    b_m     = {1'b0, b[22:0], 3'b0};    
end 

// Special case judgement
// Nan, zero, etc, ditectly have results
always_comb begin
    special = 1; 
     
    pre_a_s = 0;
    pre_b_s = 0;
    pre_a_e = 0;
    pre_b_e = 0;
    pre_a_m = 0;
    pre_b_m = 0;
        
    //if a is NaN/SNaN or b is NaN/SNaN return NaN 
    if ((a_e == 128 && a_m != 0) || (a_e == 128 && b_m != 0)) begin
        c_s = 1;
        c_e = 255;
        c_m = {1'b1, 22'b0};
    end else if (a_e == 128) begin   //a is inf           
        if(b_e == 128 && (a_s != b_s)) begin    //b is inf and signs don't match return nan
            c_s = b_s;
            c_e = 255;
            c_m = {1'b1, 22'b0}; 
        end else begin  //b is not inf, return inf      
            c_s = a_s;
            c_e = 255;
            c_m = 24'b0; 
        end
    end else if (b_e == 128) begin  //b is inf, a is not inf return inf
        c_s = b_s;
        c_e = 255;
        c_m = 24'b0;  
    end else if ((($signed(a_e) == -127) && (a_m == 0)) && (($signed(b_e) == -127) && (b_m == 0))) begin    // a,b 0
        c_s = a_s & b_s;
        c_e = 0;
        c_m = 24'b0;      
    end else if (($signed(a_e) == -127) && (a_m == 0)) begin //if a is zero, b not 0, return b
        c_s = b_s;
        c_e = b_e[7:0] + 127;
        c_m = b_m[26:3];      
    end else if (($signed(b_e) == -127) && (b_m == 0)) begin //if b is zero return a
        c_s = a_s;
        c_e = a_e[7:0] + 127;
        c_m = a_m[26:3];  
    end else begin // Not special case
        special = 0; 
        pre_a_s = a_s;
        pre_b_s = b_s;
        
        pre_a_e = a_e;
        pre_b_e = b_e; 
                
        pre_a_m = a_m;
        pre_b_m = b_m;        
         
        //Denormalised Number
        if ($signed(a_e) == -127) begin //subnormal
            pre_a_e     = -126;
        end else begin
            pre_a_m[26] = 1;
        end
        
        //Denormalised Number
        if ($signed(b_e) == -127) begin //subnormal
            pre_b_e     = -126;
        end else begin
            pre_b_m[26] = 1;
        end
    end
end



/////////////////////////////////////////////////////////////////////////////////////////
// Compute part
/////////////////////////////////////////////////////////////////////////////////////////

// Align
//logic           align_s;
//logic [7:0]     align_e;
//logic [23:0]    align_m;

logic           s_large;
logic           s_small;

logic [7:0]     e_small;
logic [7:0]     e_large;

logic [26:0]    m_small;
logic [26:0]    m_large;

logic [7:0]     e_diff;
logic           exp_agtb;
logic [26:0]    m_shift;


always_comb begin
    exp_agtb    = 0;
    e_diff      = 0;

    s_small     = 0;
    s_large     = 0;
    e_small     = 0;
    e_large     = 0;
    m_small     = 0;
    m_large     = 0;

    m_shift     = 0;

    if(special == 0) begin
        exp_agtb    = pre_a_e > pre_b_e;

        s_small     = exp_agtb ? pre_b_s : pre_a_s;
        s_large     = exp_agtb ? pre_a_s : pre_b_s;
        e_small     = exp_agtb ? pre_b_e : pre_a_e;
        e_large     = exp_agtb ? pre_a_e : pre_b_e;
        m_small     = exp_agtb ? pre_b_m : pre_a_m;
        m_large     = exp_agtb ? pre_a_m : pre_b_m;


	    e_diff      = e_large - e_small;
	    
	    if(e_diff > 0) begin
	        m_shift[26:0]   = m_small >> (e_diff);
    	    //m_shift[0]      = m_small[e_diff-1];    //?
	    end else begin
	        m_shift[26:1]   = m_small[26:1];
    	    m_shift[0]      = m_small[0];           //?	    
	    end
    end
end 



// Add 0
logic           add0_s;
logic [7:0]     add0_e;
logic [27:0]    add0_m;     // one more bit cause overflow
always_comb begin
    add0_s  = 0;
    add0_e  = 0;
    add0_m  = 0;

    if(special == 0) begin
        add0_s  = s_large;    
        add0_e  = e_large;
        
        if (s_large == s_small) begin
            add0_m = m_large + m_shift;

        end else begin
            add0_m = m_large - m_shift;
            add0_s = s_large;
        end
    end
end



// Add 1
logic           add1_s;
logic [7:0]     add1_e;
logic [23:0]    add1_m;     // Back from 28 bits to 24 bits

logic           add1_guard;
logic           add1_sticky;
logic           add1_round_bit;

always_comb begin
    add1_s  = 0;
    add1_e  = 0;
    add1_m  = 0;
    
    add1_guard      = 0;
    add1_sticky     = 0;
    add1_round_bit  = 0;
    
    if(special == 0) begin
        add1_s  = add0_s;
    
        if(add0_m[27]) begin
            add1_e          = add0_e + 1;
            add1_m          = add0_m[27:4];
                        
            add1_guard      = add0_m[3];
            add1_round_bit  = add0_m[2];
            add1_sticky     = add0_m[1] | add0_m[0];
        end else begin
            add1_e          = add0_e;
            add1_m          = add0_m[26:3];
            
            add1_guard      = add0_m[2];
            add1_round_bit  = add0_m[1];
            add1_sticky     = add0_m[0];
        end
    end
end



// Normalise 1
logic           norm1_s;
logic [7:0]     norm1_e;
logic [23:0]    norm1_m;

logic           norm1_guard;
logic           norm1_sticky;
logic           norm1_round_bit;

int             i;
logic [7:0]     pos;
logic [7:0]     adj;

always_comb begin
    norm1_s = 0;
    norm1_e = 0;
    norm1_m = 0;
    
    norm1_guard     = 0;
    norm1_sticky    = 0;
    norm1_round_bit = 0;

    if(special == 0) begin
    
        pos = 0;
        for (i = 23; i >= 0; i = i - 1 ) 
            if ( !pos && add1_m[i] ) 
                pos = i;
                
        adj = 23 - pos;
        
        if(add1_e < adj) begin  // Underflow, 0
            norm1_s = 0;
            norm1_e = 0;
            norm1_m = 0;        
        end else begin
            norm1_s = 0;
            norm1_e = add1_e - adj;
            norm1_m = add1_m << adj;
        end
    end
end


// Normalise 2
logic           norm2_s;
logic [7:0]     norm2_e;
logic [23:0]    norm2_m;

logic           norm2_guard;
logic           norm2_round_bit;
logic           norm2_sticky;

logic [7:0]     norm2_shift;

always_comb begin
    norm2_s = 0;
    norm2_e = 0;
    norm2_m = 0;
    
    norm2_guard     = 0;
    norm2_sticky    = 0;
    norm2_round_bit = 0;
    
    norm2_shift     = 0;
    
    if(special == 0) begin
        if ($signed(norm1_e) < -126) begin
            norm2_shift = 126 + $signed(norm1_e);
            
            norm2_s = norm1_s;
            norm2_e = -126;
            norm2_m = norm1_m >> norm2_shift;
        end else begin
            norm2_s = norm1_s;
            norm2_e = norm1_e;
            norm2_m = norm1_m;
            
            norm2_guard     = norm1_guard;
            norm2_round_bit = norm1_round_bit;
            norm2_sticky    = norm1_sticky;
        end 
    end
end


// Round
logic           round_s;
logic [7:0]     round_e;
logic [23:0]    round_m;

always_comb begin
    round_s = 0;
    round_e = 0;
    round_m = 0;
    
    if(special == 0) begin
        round_s = norm2_s;
    
        if (norm2_guard && (norm2_round_bit | norm2_sticky | norm2_m[0])) begin
            round_m = norm2_m + 1;
            
            if (norm2_m == 24'hffffff) begin
                round_e = norm2_e + 1;
            end else begin
                round_e = norm2_e;
            end 
        end else begin
            round_e = norm2_e;
            round_m = norm2_m;
        end
    end
end


// Pack
logic [31:0]    pack;

always_comb begin
    if(special == 0) begin
        pack[22 : 0]    = round_m[22:0];
        pack[30 : 23]   = round_e[7:0] + 127;
        pack[31]        = round_s;
        
        if ($signed(round_e) == -126 && round_m[23] == 0) begin
            pack[30 : 23]   = 0;
        end
        
        if ($signed(round_e) == -126 && round_m[23:0] == 24'h0) begin
            pack[31]    = 1'b0; // FIX SIGN BUG: -a + a = +0.
        end
        
        //if overflow occurs, return inf
        if ($signed(round_e) > 127) begin
            pack[22 : 0]    = 0;
            pack[30 : 23]   = 255;
            pack[31]        = round_s;
        end 
        
        c = pack;       
    end else begin
        c = {c_s, c_e, c_m}; 
    end
end



endmodule
