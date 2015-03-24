module reg1 (in, rst, clk, out);

input in;
input rst, clk;

output out;

reg IM_ID;

always @(posedge clk or negedge rst)
	if (!rst)
		IM_ID <= 1'b0;
	else  
		IM_ID <= in;

assign out = IM_ID;
endmodule 
