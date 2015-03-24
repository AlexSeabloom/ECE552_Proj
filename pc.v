module pc(dst_ID_EX, pc_ID_EX, pc_EX_DM, stall, clk, rst_n, flow_change_ID_EX, addr);

output [15:0]addr;
output [15:0]pc_ID_EX, pc_EX_DM;	//PC values for pipeline
input [15:0]dst_ID_EX;			//branch address
input flow_change_ID_EX, clk, rst_n, stall;

wire [15:0]pc_IM_ID;
wire [15:0]a, b, c;
wire [15:0]pc;
wire [15:0]counted;
 
reg16 r1(.clk(clk), .rst(1), .in(c[15:0]), .out(pc_IM_ID[15:0]));	//
reg16 r2(.clk(clk), .rst(1), .in(pc_IM_ID[15:0]), .out(pc_ID_EX[15:0]));
reg16 r3(.clk(clk), .rst(1), .in(pc_ID_EX[15:0]), .out(pc_EX_DM[15:0]));
reg16 r4(.clk(clk), .rst(rst_n), .in(b[15:0]), .out(pc[15:0]));

assign a = (flow_change_ID_EX) ? dst_ID_EX : //mux for branching
		counted;
assign b = (stall) ? pc:
		a;
assign counted = pc + 1;

assign c = (stall) ? pc_IM_ID:
		counted;
assign addr = pc;

endmodule 
