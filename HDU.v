module HDU(FD_op, FD_rs, FD_rt, DX_op, DX_rd, XM_op, XM_rd, MW_op, MW_rd, EXresult, MEMresult, WBresult, stl, corr_rs, corr_rt, fwd_rs, fwd_rt);

input [3:0] FD_op, DX_op, XM_op, MW_op;
input [3:0] FD_rs, DX_rd, XM_rd, MW_rd;
input [3:0] FD_rt;
input [15:0] EXresult, MEMresult, WBresult;

output [15:0] corr_rs, corr_rt;
output stl;
output fwd_rs, fwd_rt;

localparam ARITH = 1'b0;
localparam [1:0] NoShift = 2'b00;
localparam [3:0] NOR = 4'b0100;
localparam [2:0] IMMLOAD = 3'b101;
localparam [3:0] LW = 4'b1000;
localparam [3:0] SW = 4'b1001;
localparam [3:0] JR = 4'b1110;

wire [16:0] corr_rs_tmp, corr_rt_tmp;
wire rsZero, rtZero;

//FORWARDING
// 16th bit/MSB is used to signal that a forward has occurred 
assign corr_rs_tmp = ((FD_op[3:1] == IMMLOAD || FD_op[3] == ARITH || FD_op == SW || FD_op == JR || FD_op == LW) && //FWD rs X->D
		(DX_op[3:1] == IMMLOAD ||  DX_op[3] == ARITH) && 
		(FD_rs == DX_rd)) ? {1'b1,EXresult} :
		((FD_op[3:1] == IMMLOAD || FD_op[3] == ARITH || FD_op == SW || FD_op == JR || FD_op == LW) && //FWD rs M->D
		(XM_op[3:1] == IMMLOAD ||  XM_op[3] == ARITH || XM_op == LW) && 
		(FD_rs == XM_rd)) ? {1'b1,MEMresult} :
		((FD_op[3:1] == IMMLOAD || FD_op[3] == ARITH || FD_op == SW || FD_op == JR || FD_op == LW) && //FWD rs W->D
		(MW_op[3:1] == IMMLOAD ||  MW_op[3] == ARITH || MW_op == LW) && 
		(FD_rs == MW_rd)) ? {1'b1,WBresult} : 
					17'b0;
 
// 16th bit/MSB is used to signal that a forward has occurred 
assign corr_rt_tmp = ((FD_op[3:1] == IMMLOAD || FD_op[3] == NoShift || FD_op == NOR || FD_op == SW || FD_op == LW) && //FWD rt X->D
		(DX_op[3:1] == IMMLOAD ||  DX_op[3] == NoShift || DX_op == NOR) && 
		(FD_rt == DX_rd)) ? {1'b1,EXresult} :
		((FD_op[3:1] == IMMLOAD || FD_op[3] == NoShift || FD_op == NOR || FD_op == LW || FD_op == SW) && //FWD rt M->D
		(XM_op[3:1] == IMMLOAD ||  XM_op[3] == NoShift || XM_op == NOR || XM_op == LW) &&
		(FD_rt == XM_rd)) ? {1'b1,MEMresult} :
		((FD_op[3:1] == IMMLOAD || FD_op[3] == NoShift || FD_op == NOR || FD_op == LW || FD_op == SW) && //FWD rt W->D
		(MW_op[3:1] == IMMLOAD ||  MW_op[3] == NoShift || MW_op == NOR || MW_op == LW) && 
		(FD_rt == MW_rd)) ? {1'b1,WBresult} : 
					17'b0;

//R0 is always 0
assign rsZero = (FD_rs == 4'b000) ? 1 : 0;
assign rtZero = (FD_rt == 4'b000) ? 1 : 0;

assign corr_rs = corr_rs_tmp[15:0];
assign corr_rt = corr_rt_tmp[15:0];
assign fwd_rs = (corr_rs_tmp[16] && ~rsZero); 
assign fwd_rt = (corr_rt_tmp[16] && ~rtZero);

//STALLING
assign stl = ((FD_op[3:1] == IMMLOAD || FD_op[3] == NoShift || FD_op == NOR || FD_op == SW || FD_op == LW) && //stall if we have dependance on an 
		(DX_op == LW) && ((FD_rt == DX_rd && ~fwd_rt) || (FD_rs == DX_rd && ~fwd_rs))) ? 1 ://LW in the EX stage and no forwarding fixing this already
		0;

endmodule 