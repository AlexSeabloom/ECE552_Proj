module stage_IF(clk, rst_n, stall, PCin, PCsrc, instr, PCout, hlt_det, memDataIn, memAddrOut, memStallIn);//MIGHT NEED A READ ENABLE TO MEM

input [15:0] PCin;
input clk, rst_n, PCsrc, stall;
input [15:0] memDataIn;
input memStallIn;
output [15:0] PCout, instr;
output hlt_det;
output [15:0] memAddrOut;

wire [15:0] PCregOut;
wire rd_en, stallPC;

assign memAddrOut = PCregOut;
assign instr = memDataIn;

assign stallPC = stall || hlt_det;

//check for hlt
assign hlt_det = (memStallIn) ? 1'b0: 
		(instr[15:12] == 4'b1111 && PCsrc != 1'b1) ? 1'b1:
					1'b0;

// Decide which PC value to use source 
//assign PC = (PCsrc) ? PCin : PCoffset;

// Update the program counter
//pc IDUT(.dst_ID_EX()*****, .pc_ID_EX(pc_ID_EX)*****, .pc_EX_DM(pc_EX_DM)*****, .stall(stall), .clk(clk), .rst_n(rst_n), flow_change_ID_EX*****, .addr(addr));

//The PC, will update on clock edge, has rst, stall, and branch capabilities.
neils_pc thePC(.clk(clk), .rst_n(rst_n), .stall(stallPC), .isBranch(PCsrc), .branchAddr(PCin), .PCout(PCregOut));

//assign the read enable
assign rd_en = (stall == 1) ? 0:
			      1;

// Use the instruction memory to fetch the current instruction
//IM iInstrMem(.clk(clk),.addr(PCregOut),.rd_en(rd_en),.instr(instr));//connect cpu PCout to PCregOut in this module

assign PCout = (PCsrc) ? PCin :PCregOut;

endmodule 