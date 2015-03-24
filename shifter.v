
module shifter (out, in, shamt, cntrl);

output [15:0] out;
input [15:0] in;
input [3:0] shamt;
input [1:0] cntrl;

localparam asr = 2'b11;
localparam lsr = 2'b10;
localparam asl = 2'b00;
localparam lsl = 2'b01;

assign {out} =  (cntrl == asr) ? {$signed(in)>>>shamt} :
		(cntrl == lsr) ? {in>>shamt} :
		(cntrl == asl) ? {in<<shamt} :
		(cntrl == lsl) ? {in<<shamt} :
				16'h0000;
endmodule
