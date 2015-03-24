module ALU (opA, opB, shamt, ALUop, ov, zr, neg, ALUout); 

output [15:0] ALUout;
output ov, zr, neg;
input  [15:0] opA, opB;
input  [3:0] shamt;
input [2:0] ALUop;
wire [15:0]shiftOut;
wire [15:0] addOut;
wire [15:0] subOut;

localparam ADD    = 3'b000;
localparam PADDSB = 3'b001;
localparam SUB    = 3'b010;
localparam AND    = 3'b011;
localparam NOR    = 3'b100;
localparam SLL    = 3'b101;
localparam SRL    = 3'b110;
localparam SRA    = 3'b111;

shifter shifter(.out(shiftOut[15:0]), .in(opA[15:0]), .shamt(shamt), .cntrl(ALUop[1:0]));

assign addOut = (opA + opB);
assign subOut = (opA - opB);

assign {ALUout} =  (ALUop == ADD && opA[15] == 0 && opB[15] == 0 && addOut[15] == 1) ? {16'h7fff} :
		   (ALUop == ADD && opA[15] == 1 && opB[15] == 1 && addOut[15] == 0) ? {16'h8000} :	
		   (ALUop == SUB && opA[15] == 0 && opB[15] == 1 && subOut[15] == 1) ? {16'h7fff} :
		   (ALUop == SUB && opA[15] == 1 && opB[15] == 0 && subOut[15] == 0) ? {16'h8000} :
		   (ALUop == ADD)    ? (opA[15:0] + opB[15:0]) :
		   (ALUop == PADDSB) ? {(opA[15:8] + opB[15:8]), (opA[7:0] + opB[7:0])} :
		   (ALUop == SUB)    ? (opA[15:0] - opB[15:0]) :
		   (ALUop == AND)    ? (opA[15:0] & opB[15:0]) :
		   (ALUop == NOR)    ? ~(opA[15:0] | opB[15:0]) :
		   (ALUop == SLL)    ? (shiftOut) :
		   (ALUop == SRL)    ? (shiftOut) :
		   (ALUop == SRA)    ? (shiftOut) :
				     16'h0000;
assign {zr} = 	(ALUout == 0) ? {1'b1} :
				1'b0;
assign {neg} = 	(ALUout[15] == 1) ? {1'b1} :
				1'b0;
assign {ov} = 	(ALUop == ADD && opA[15] == 0 && opB[15] == 0 && addOut[15] == 1) ? {1'b1} :
		(ALUop == ADD && opA[15] == 1 && opB[15] == 1 && addOut[15] == 0) ? {1'b1} :	
		(ALUop == SUB && opA[15] == 0 && opB[15] == 1 && subOut[15] == 1) ? {1'b1} :
		(ALUop == SUB && opA[15] == 1 && opB[15] == 0 && subOut[15] == 0) ? {1'b1} :
				1'b0;

endmodule

