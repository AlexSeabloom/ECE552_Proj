/**
* File: stage_EX.sv
* Authors: Neil Jerome, Alex Seabloom, Timothy Fronsee
* Date: October 26, 2014
* Description: The "execution" stage of our pipelined WISC-F14 CPU
*/
module stage_EX(clk, rst_n, rs, rt, instr, PCin, PCout, 
	result, rdIn, rdOut, fZ, fN, fOv, rtOut, we);

//||Inputs and outputs||||
input clk, rst_n;
input [3:0] rdIn;
input [15:0]PCin, instr;
input [15:0] rs, rt;//rs is rd for LLB LHB

output [15:0] PCout;
output [15:0] result, rtOut;
output [3:0]rdOut;
output fZ, fN, fOv, we;

//||internal wires||||
wire[15:0] ALUBin;
wire[15:0] PCimm;
wire[2:0] ALUopin;
wire[15:0]ALUout;
wire infOv, infZ, infN;

assign rtOut = rt;

////ALU SECOND INPUT////
assign ALUBin = (instr[15:13] == 3'b100) ? {{12{instr[3]}},instr[3:0]}://SW,LW: 4bit imm  + rs
				rt;//otherwise rt + rs

/////ALU OPCODE////				
assign ALUopin = (instr[15:12] == 4'b1001) ? 3'b000://SW,LW: Add the 4bit imm + rs
				 instr[14:12];//otherwise lower order 3 bits of instruction opcode are ALUop

/////ALU OPCODE////				
assign we = (instr[15:12] == 4'b1001) ? 1'b1://SW,LW: write to memory
				 0;//otherwise don't write 


////ALU////
ALU iALU(.ALUout(ALUout), .ov(infOv), .zr(infZ), .neg(infN), .opA(rs), .opB(ALUBin), .shamt(instr[3:0]), .ALUop(ALUopin));

/////////////OUTPUT ASSIGNMENT/////////////
/////RESULT OUTPUT////
assign result = (instr[15:12] == 4'b1010) ? {instr[7:0],rs[7:0]} : //LHB: load imm into most significant 8 bits of rd(rs)
		(instr[15:12] == 4'b1011) ? {{8{instr[7]}}, instr[7:0]} :///LLB sign ext imm
		(instr[15:12] == 4'b1101) ? (PCin + 1'b1) ://IF JAL WE NEED TO STORE PC+1				 
				ALUout;//otherwise ALU's output
				
////DESTINATION REGISTER OUT////
assign rdOut = rdIn;

////PC OUT////
assign PCimm = (instr[15:12] == 4'b1101) ? {{4{instr[11]}}, instr[11:0]}://JAL: pc + 12bit imm
	      				   {{7{instr[8]}}, instr[8:0]};//B: pc + 9bit imm

assign PCout = (instr[15:13] == 3'b110) ? (PCimm + PCin + 1'b1):///JAL, B: (PC+1) + immediate
			   rs;//JR: rs
			   //(instr[15:12] == 4'b1110) ? rs: //JR: rs

////FLAG REGISTER AND OUTPUTS////			   
flag_select iFlags(.Zin(infZ), .Vin(infOv), .Nin(infN), .rst(rst_n), 
	.clk(clk), .opCode(instr[15:12]), .Zout(fZ), .Vout(fOv), .Nout(fN));
endmodule 
