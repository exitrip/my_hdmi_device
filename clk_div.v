
module clk_div (input clk, input ena, output reg clk_out);

parameter DIV = 16;
parameter WIDTH = $clog2(DIV + 1);

reg [WIDTH-1:0] q;

always @(posedge clk) begin
	if (ena) begin
		q <= q + 1'b1;
		if (q >= (DIV-1)) begin
			q <= {WIDTH{1'b0}};
		end
		clk_out <= (q < DIV/2) ? 1'b1:1'b0;
	end
end

endmodule   

module clk_div_var (input clk, input [31:0] div, input ena, output reg clk_out);

parameter WIDTH = 32;

reg [WIDTH-1:0] q;

always @(posedge clk) begin
	if (ena) begin
		q <= q + 1'b1;
		if (q >= (div-1)) begin
			q <= {WIDTH{1'b0}};
		end
		clk_out <= (q < div/2) ? 1'b1:1'b0;
	end
end

endmodule   