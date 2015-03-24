module flag_select(Zin, Vin, Nin, rst, clk, opCode, Zout, Vout, Nout);

input Zin, Vin, Nin;	//from ALU
input rst, clk;
input [3:0]opCode;
output Zout, Vout, Nout;

wire Z, V, N; //input into FLAG reg

localparam ADD    = 4'b0000;
localparam SUB    = 4'b0010;
localparam PADDSB = 4'b0001;


flag_reg_3bit iflag_reg(.Zin(Z), .Vin(V), .Nin(N), .rst(rst), .clk(clk), .Zout(Zout), .Vout(Vout), .Nout(Nout));

//If the op is ADD or SUB, set the N flag. Else, keep it the same
assign N = (opCode == ADD) ? Nin:
	   (opCode == SUB) ? Nin:
		Nout;

//If the op is ADD or SUB, set the V flag. Else, keep it the same
assign V = (opCode == ADD) ? Vin:
	   (opCode == SUB) ? Vin:
		Vout;
//Don't set Z for PADDSB, and if MSB of opCode is 1, it's not an ALU op, so don't set Z
assign Z = (opCode == PADDSB) ? Zout:
	   (opCode[3] == 1) ? Zout:
		Zin;

endmodule 