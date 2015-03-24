module reg16 (in, rst, clk, out);

input [15:0] in;
input rst, clk;

output [15:0] out;

reg [15:0] IM_ID;

always @(posedge clk or negedge rst)
	if (!rst)
		IM_ID <= 16'hFFFF;
	else  
		IM_ID <= in;

assign out = IM_ID;
endmodule 
