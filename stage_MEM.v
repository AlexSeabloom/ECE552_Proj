module stage_MEM(clk, PCin, inst, EXresult, rt, fZ, fN, fOv, result, PCout, PCsrc, mem_reOut, mem_weOut, mem_rdIn, mem_wrtOut, mem_addrOut);//rd,

input [15:0] rt, PCin, inst, EXresult;
//input [3:0] rd;
input clk, fZ, fN, fOv;
input [15:0] mem_rdIn;
 
output [15:0] result, PCout;
output PCsrc;
output [15:0] mem_wrtOut, mem_addrOut ;
output mem_reOut, mem_weOut;

wire [15:0] memOut;
wire re, we, condition, isControl;



// Pass along PC
assign PCout = PCin;  

assign we = (inst[15:12] == 4'b1001) ? 1 : 0;
assign re = (inst[15:12] == 4'b1000) ? 1 : 0;

// Determine if branch should be set
assign condition = (inst[11:9] == 3'b000 && fZ == 0) ? 1 : 
	       (inst[11:9] == 3'b001 && fZ == 1) ? 1 : 
	       (inst[11:9] == 3'b010 && fZ == 0 && fN == 0) ? 1 : 
	       (inst[11:9] == 3'b011 && fZ == 0 && fN == 1) ? 1 : 
	       (inst[11:9] == 3'b100 && (fZ == 1 || (fZ == 0 && fN == 0))) ? 1 : 
   	       (inst[11:9] == 3'b101 && (fZ == 1 || fN == 1)) ? 1 : 
	       (inst[11:9] == 3'b110 && fOv == 1) ? 1 : 
	       (inst[11:9] == 3'b111) ? 1 :
	       (inst[15:12] == 4'b1101 || inst[15:12] == 4'b1110) ? 1 : 
						0; 
// Determine if the instruction is a control instruction
assign isControl = (inst[15:13] ==  3'b110) ? 1 : 
		   (inst[15:12] == 4'b1110) ? 1 :
						0;

// Set the branch 
assign PCsrc = condition & isControl;

// Read/Write from Memory using data memory module
//DM iDataMem1234(.clk(clk), .addr(EXresult), .re(re), .we(we), .wrt_data(rt), .rd_data(memOut));

assign mem_reOut = re;
assign mem_weOut = we;
assign mem_wrtOut = rt;
assign memOut = mem_rdIn;
assign mem_addrOut = EXresult;

// Save the result from memory if LW, otherwise save the result from ALU
assign result = (inst[15:12] == 4'b1000) ? memOut : EXresult;
 

endmodule 
