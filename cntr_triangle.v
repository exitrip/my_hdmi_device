
// UP/DN binary counter with all of the register secondary
// hardware. (1 cell per bit)

module cntr_triangle (clk, ena, rst, sload, sdata, sclear, q);

parameter WIDTH = 16;

input clk,ena,rst,sload,sclear;
input [WIDTH-1:0] sdata;

reg inc_not_dec;
output reg [WIDTH-1:0] q;
//reg [WIDTH-1:0] q;

always @(posedge clk or posedge rst) begin
	if (rst) q <= 0;
	else begin
		if (ena) begin
			if (sclear) q <= 0;
			else if (sload) q <= sdata;
			else q <= (inc_not_dec ? (q + 1'b1) : (q - 1'b1) );
		end
	end
end

always @(negedge clk) begin
    if (q == {WIDTH{1'b0}}) 
        inc_not_dec <= 1'b1;
    else if (q == {WIDTH{1'b1}}) 
        inc_not_dec <= 1'b0;
end

endmodule