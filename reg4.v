module reg4 (in, rst, clk, out);

input [3:0] in;
input rst, clk;

output [3:0] out;

reg [3:0] IM_ID;

always @(posedge clk or negedge rst)
	if (!rst)
		IM_ID <= 4'b0;
	else  
		IM_ID <= in;

assign out = IM_ID;
endmodule 
