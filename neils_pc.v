module neils_pc(clk, rst_n, stall, isBranch, branchAddr, PCout);

input [15:0] branchAddr;
input clk, rst_n, stall, isBranch;

output [15:0] PCout;

wire [15:0] PCregIn, PCregOut;

//the PC is in this
reg [15:0] pcReg;

assign PCregOut = pcReg;
//Assign new PC based on whether there is any branching or stalling or nothing
assign PCregIn = (rst_n == 0) ? 16'h0:
		 (stall == 1) ? PCregOut :
		 (isBranch == 1) ? branchAddr :
				PCregOut + 1;

always @(posedge clk or negedge rst_n)
	if (!rst_n)
		pcReg <= 16'b0;
	else  
		pcReg <= PCregIn;

assign PCout = PCregOut;

endmodule
