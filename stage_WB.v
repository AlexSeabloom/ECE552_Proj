module stage_WB(clk, memResult, instr, PCjump, rd, rdOut, wdata, regWrite);//memtoReg,

input [15:0] memResult, instr, PCjump;
input [3:0] rd;
input clk;//memtoReg,

output [15:0] wdata; 
output [3:0] rdOut;
output regWrite;

wire regZero;

assign regZero = (rd == 4'b0000) ? 1:
			0;

// Pass along destination reg
assign rdOut = (instr[15:12] == 4'b1101) ? 4'b1111 : rd; 	// For JAL

// Decide whether to write to registers
assign regWrite = //(rd == 4'b0000) ? 0 :
		  (instr[15] == 0 && regZero != 1'b1) ? 1 :
		  (instr[15:13] == 3'b101 && regZero != 1'b1) ? 1 :
		  (instr[15:12] == 4'b1000 && regZero != 1'b1) ? 1 :
		  (instr[15:12] == 4'b1101 && regZero != 1'b1) ? 1 :		// For JAL 
					0;

// Decide the location of write data
//assign wdata = (instr[15:12] == 4'b1101) ? PCjump : memResult;
assign wdata = memResult;

endmodule 
