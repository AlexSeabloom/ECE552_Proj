module stage_ID(clk, hlt, PCin, instr, regWrite, regDst, writeData, PCout, rs, rt, opOut, rtAddr, rsAddr, rdAddr);//, signEx);

input [15:0] PCin, instr, writeData;
input [3:0]regDst;
input regWrite, clk, hlt;

output [15:0] PCout, rs, rt;//, signEx; 
output [3:0] opOut, rtAddr, rsAddr, rdAddr;

wire [3:0] p0Addr, p1Addr;
wire [15:0] rsWire, rtWire;
wire p0re, p1re;                         

// Pass along the PC
assign PCout = PCin;

localparam ARITHnoSHIFT = 2'b00;
localparam ARITH = 1'b0;
localparam NOR = 4'b0100;
localparam JR = 4'b1110;
localparam MEM = 3'b100;
localparam LHB = 4'b1010;

// Decode the instruction 
assign p0re = (instr[15] == ARITH || instr[15:13] == MEM || instr[15:12] == JR || instr[15:12] == LHB) ? 1 : 0;
assign p1re = (instr[15:13] == MEM || instr[15:14] == ARITHnoSHIFT || instr[15:12] == NOR) ? 1 : 0;
assign p0Addr = (instr[15] == ARITH || instr[15:13] == MEM || instr[15:12] == JR) ? instr[7:4] :
		(instr[15:12] == LHB) ? instr[11:8] : 4'b0;
assign p1Addr = (instr[15:14] == ARITHnoSHIFT || instr[15:12] == NOR) ? instr[3:0] :
		(instr[15:13] == MEM) ? instr[11:8]: 4'b0;

//RTaDDR RSaDDR OPCODE
assign rtAddr = p1Addr;
assign rsAddr = p0Addr;
assign opOut = instr[15:12];

////DESTINATION REGISTER OUT////
assign rdAddr = (instr[15:12] == 4'b1101) ? 4'b1111 ://check if JAL to put in reg15
			   (instr[15:12] == 4'b1000 || instr[15] == 1'b0 || instr[15:13] == 3'b101) ? (instr[11:8]) : //LW, ALUop, LLB, LHB
			         4'b0000;//no register saving

// Decode the instruction using the Registers 
rf iRegPipe(.clk(clk),.p0_addr(p0Addr),.p1_addr(p1Addr),.p0(rsWire),.p1(rtWire),.re0(p0re),.re1(p1re),
		.dst_addr(regDst),.dst(writeData),.we(regWrite),.hlt(hlt));

assign rs = (p0re == 1'b1) ? rsWire : 16'b0;
assign rt = (p1re == 1'b1) ? rtWire : 16'b0;

endmodule 
