module buble #( parameter  WIDTH = 32
)(
    input logic                 clk,
    input logic                 rst_n,

    input logic [WIDTH-1:0]     data_a,
    input logic                 vld_a,
    output logic                rdy_a,

    output logic [WIDTH-1:0]    data_b,
    output logic                vld_b,
    input logic                 rdy_b
);

enum logic [1:0] {Empty, Full} state;
logic   gnt_a;
logic   gnt_b;

assign rdy_a    = rdy_b | (state == Empty);
assign gnt_a    = (vld_a && rdy_a);
assign gnt_b    = (vld_b && rdy_b);


always_ff @(posedge clk or negedge rst_n)   begin
    if( rst_n == 0 ) begin
        data_b  <= '0;
        vld_b   <= 0;

        state   <= Empty;
    end else begin
        case(state) 
            Empty:  begin
                if(gnt_a) begin
                    vld_b   <= 1;
                    data_b  <= data_a;

                    if(rdy_b) begin
                        state   <= Empty;
                    end else begin
                        state   <= Full;
                    end
                end else begin
                    vld_b   <= 0;
                    state   <= Empty;
                end
            end

            Full:   begin
                if(gnt_b) begin
                    if(vld_a) begin
                        data_b  <= data_a;

                        vld_b   <= 1; 
                        state   <= Full;
                    end else begin
                        vld_b   <= 0; 
                        state   <= Empty;
                    end
                end else begin
                    state   <= Full;
                end
            end 
        endcase
    end
end


endmodule
