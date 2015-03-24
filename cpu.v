module cpu(clk, rst_n, pc, hlt);

input clk, rst_n;

output [15:0] pc;
output hlt;

wire WD_we;
wire fwd_chk_rs, fwd_chk_rt;
//CROSS-STAGE WIRES (branching, jumping, writeback, stalling, etc)
wire [15:0]MF_branchPC;
wire MF_PCsrc;
wire WD_regWrite;
wire [3:0] WD_rd;
wire [15:0] WD_wdata;
wire hltOut;
wire stl;
wire [15:0] i_addr; //I mem address
wire [15:0] i_data;//I mem data (to IF stage)
wire dmem_re, dmem_we;
wire [15:0] dmem_rdData, dmem_wrtData, dmem_addr;
wire i_stall, d_stall;//memory stalling

//REGISTERS IF/ID
wire [15:0] F_pcOut, D_pcIn;
wire [15:0] F_instOut, D_instIn;
wire F_hlt_detOut, D_hlt_detIn;

//REGISTERS ID/EX
wire [3:0] D_opOut, X_opIn; 
wire [3:0] D_rs_addrOut, D_rd_addrOut, D_rt_addrOut;
wire [3:0] X_rs_addrIn, X_rd_addrIn, X_rt_addrIn;
wire [15:0] D_pcOut, X_pcIn;
wire [15:0] D_rtOut, X_rtIn;
wire [15:0] D_rsOut, X_rsIn;
wire [15:0] X_instIn;
wire X_hlt_detIn;

//REGISTERS EX/MEM
wire [3:0] M_opIn; 
wire [3:0] M_rs_addrIn, M_rd_addrIn, M_rt_addrIn;
wire [3:0] X_rs_addrOut, X_rd_addrOut, X_rt_addrOut;
wire [15:0] X_pcOut, M_pcIn;
wire [15:0] M_instIn;
wire [3:0] X_rdOut, M_rdIn;
wire [15:0] X_resultOut, M_resultIn;
wire X_fZout, M_fZin, X_fNout, M_fNin, X_fOvout, M_fOvin;
wire [15:0] X_rtOut, M_rtIn;
wire M_hlt_detIn;

//REGISTERS MEM/WB
wire [3:0] W_opIn; 
wire [3:0] W_rs_addrIn, W_rd_addrIn, W_rt_addrIn;
wire [3:0] M_rs_addrOut, M_rd_addrOut, M_rt_addrOut;
wire [15:0] W_instIn;
wire [3:0] W_rdIn;
wire [15:0] M_resultOut, W_resultIn;

// Begin instantiating the pipeline
stage_IF IF(.clk(clk), .rst_n(rst_n), .hlt_det(F_hlt_detOut), 
.stall(stl | i_stall | d_stall), .PCin(MF_branchPC), .PCsrc(MF_PCsrc), .instr(F_instOut), .PCout(F_pcOut), 
.memDataIn(i_data), .memAddrOut(i_addr), .memStallIn(i_stall));

assign pc = (F_pcOut + 1);

// FORWARDING
wire fd_chk_rt, fd_chk_rs;
wire [15:0] corr_rs, corr_rt;
wire [15:0] rs_mux, rt_mux;

//STALLING
wire [15:0] muxed_Fpc;
wire [15:0] muxed_instrIn;
wire muxed_hltDetF;

//stalling
assign muxed_Fpc = (stl == 1'b1 || i_stall == 1'b1 || d_stall == 1'b1) ? D_pcIn : F_pcOut;
assign muxed_instrIn = (stl == 1'b1 || i_stall == 1'b1 || d_stall == 1'b1) ? D_instIn : F_instOut;
assign muxed_hltDetF = (stl == 1'b1 || i_stall == 1'b1 || d_stall == 1'b1) ? D_hlt_detIn : F_hlt_detOut;

//BRANCH FLUSHING
wire rstFDDX;
assign rstFDDX = (MF_PCsrc) ? 0 : 
		 (~rst_n) ? 0 : 
			   1;

//REGISTERS IF/ID
reg16 FD_pcReg(.in(muxed_Fpc), .rst(rstFDDX), .clk(clk), .out(D_pcIn));//PC
reg16 FD_instReg(.in(muxed_instrIn), .rst(rstFDDX), .clk(clk), .out(D_instIn));//INSTRUCTION
reg1 FD_hlt_detReg(.in(muxed_hltDetF), .rst(rstFDDX), .clk(clk), .out(D_hlt_detIn));//HLT DETECTION

stage_ID ID(.clk(clk), .hlt(hltOut), .PCin(D_pcIn), .instr(D_instIn), .regWrite(WD_regWrite), .regDst(WD_rd), 
.writeData(WD_wdata), .PCout(D_pcOut),  .opOut(D_opOut), .rtAddr(D_rt_addrOut), .rsAddr(D_rs_addrOut), .rdAddr(D_rd_addrOut),
.rs(D_rsOut), .rt(D_rtOut));//, .signEx(*));

// HDU AND FORWARDING
HDU iHDU(.FD_op(D_opOut), .FD_rs(D_rs_addrOut), .FD_rt(D_rt_addrOut), .DX_op(X_opIn), .DX_rd(X_rd_addrIn), .XM_op(M_opIn),
		 .XM_rd(M_rdIn), .MW_op(W_opIn), .MW_rd(W_rdIn), .EXresult(X_resultOut), 
		.MEMresult(M_resultOut), .WBresult(WD_wdata), .stl(stl), .corr_rs(corr_rs), .corr_rt(corr_rt), .fwd_rs(fwd_chk_rs),
		 .fwd_rt(fwd_chk_rt));
assign rs_mux = (fwd_chk_rs) ? corr_rs : 
				D_rsOut;
assign rt_mux = (fwd_chk_rt) ? corr_rt :
				D_rtOut;

//stalling ID/EX
wire [3:0] in1, in2, in3, in4;
wire [15:0] in5, in6, in7, in8;
wire in9;
assign in1 = (i_stall == 1'b1 || d_stall == 1'b1) ? X_opIn : D_opOut;
assign in2 = (i_stall == 1'b1 || d_stall == 1'b1) ? X_rt_addrIn : D_rt_addrOut;
assign in3 = (i_stall == 1'b1 || d_stall == 1'b1) ? X_rs_addrIn : D_rs_addrOut;
assign in4 = (i_stall == 1'b1 || d_stall == 1'b1) ? X_rd_addrIn : D_rd_addrOut;
assign in5 = (i_stall == 1'b1 || d_stall == 1'b1) ? X_pcIn : D_pcOut;
assign in6 = (i_stall == 1'b1 || d_stall == 1'b1) ? X_instIn : D_instIn;
assign in7 = (i_stall == 1'b1 || d_stall == 1'b1) ? X_rsIn : rs_mux;
assign in8 = (i_stall == 1'b1 || d_stall == 1'b1) ? X_rtIn : rt_mux;
assign in9 = (i_stall == 1'b1 || d_stall == 1'b1) ? X_hlt_detIn : D_hlt_detIn;

//REGISTERS ID/EX
reg4 DX_op(.in(in1), .rst(rstFDDX), .clk(clk), .out(X_opIn));//OP
reg4 DX_rtAddr(.in(in2), .rst(rstFDDX), .clk(clk), .out(X_rt_addrIn));
reg4 DX_rsAddr(.in(in3), .rst(rstFDDX), .clk(clk), .out(X_rs_addrIn));
reg4 DX_rdAddr(.in(in4), .rst(rstFDDX), .clk(clk), .out(X_rd_addrIn));

reg16 DX_pcReg(.in(in5), .rst(rstFDDX), .clk(clk), .out(X_pcIn));//PC
reg16 DX_instReg(.in(in6), .rst(rstFDDX), .clk(clk), .out(X_instIn));//INSRUCTION
reg16 DX_rsReg(.in(in7), .rst(rstFDDX), .clk(clk), .out(X_rsIn));//RS
reg16 DX_rtReg(.in(in8), .rst(rstFDDX), .clk(clk), .out(X_rtIn));//RT
reg1 DX_hlt_detReg(.in(in9), .rst(rstFDDX), .clk(clk), .out(X_hlt_detIn));//HLT DETECTION

stage_EX EX(.clk(clk), .rst_n(rst_n), .rs(X_rsIn), .rt(X_rtIn), .instr(X_instIn), .PCin(X_pcIn), .PCout(X_pcOut), .result(X_resultOut), 
.rdOut(X_rdOut), .rdIn(X_rd_addrIn), .fZ(X_fZout), .fN(X_fNout), .fOv(X_fOvout), .rtOut(X_rtOut), .we(WD_we));

//stalling EX/MEM
wire [3:0] inM1, inM2, inM3, inM6;
wire [15:0] inM4, inM5, inM7, inM9;
wire inM10, inZ, inOv, inN;
assign inM1 = (i_stall == 1'b1 || d_stall == 1'b1) ? M_opIn : X_opIn;
assign inM2 = (i_stall == 1'b1 || d_stall == 1'b1) ? M_rt_addrIn : X_rt_addrIn;
assign inM3 = (i_stall == 1'b1 || d_stall == 1'b1) ? M_rs_addrIn : X_rs_addrIn;
assign inM4 = (i_stall == 1'b1 || d_stall == 1'b1) ? M_pcIn : X_pcOut;
assign inM5 = (i_stall == 1'b1 || d_stall == 1'b1) ? M_instIn : X_instIn;
assign inM6 = (i_stall == 1'b1 || d_stall == 1'b1) ? M_rdIn : X_rdOut;
assign inM7 = (i_stall == 1'b1 || d_stall == 1'b1) ? M_resultIn : X_resultOut;
assign inM9 = (i_stall == 1'b1 || d_stall == 1'b1) ? M_rtIn : X_rtOut;
assign inM10 = (i_stall == 1'b1 || d_stall == 1'b1) ? M_hlt_detIn : X_hlt_detIn;
assign inZ = (i_stall == 1'b1 || d_stall == 1'b1) ? M_fZin : X_fZout;
assign inOv = (i_stall == 1'b1 || d_stall == 1'b1) ? M_fOvin : X_fOvout;
assign inN = (i_stall == 1'b1 || d_stall == 1'b1) ? M_fNin : X_fNout;

//REGISTERS EX/MEM
reg4 XM_op(.in(inM1), .rst(rst_n), .clk(clk), .out(M_opIn));//OP
reg4 XM_rtAddr(.in(inM2), .rst(rst_n), .clk(clk), .out(M_rt_addrIn));
reg4 XM_rsAddr(.in(inM3), .rst(rst_n), .clk(clk), .out(M_rs_addrIn));

reg16 XM_pcReg(.in(inM4), .rst(rst_n), .clk(clk), .out(M_pcIn));//PC
reg16 XM_instReg(.in(inM5), .rst(rst_n), .clk(clk), .out(M_instIn));//INSRUCTION
reg4 XM_rdReg(.in(inM6), .rst(rst_n), .clk(clk), .out(M_rdIn));//RD ADDRESS
reg16 XM_resultReg(.in(inM7), .rst(rst_n), .clk(clk), .out(M_resultIn));//EX_RESULT
flag_reg_3bit XM_flagsReg(.Zin(inZ), .Vin(inOv), .Nin(inN), .rst(rst_n), .clk(clk), .Zout(M_fZin), .Vout(M_fOvin), .Nout(M_fNin));//FLAGS
reg16 XM_rtReg(.in(inM9), .rst(rst_n), .clk(clk), .out(M_rtIn));//RT
reg1 XM_hlt_detReg(.in(inM10), .rst(rst_n), .clk(clk), .out(M_hlt_detIn));//HLT DETECTION

stage_MEM MEM(.clk(clk), .PCin(M_pcIn), .inst(M_instIn), .EXresult(M_resultIn), .rt(M_rtIn), .fZ(M_fZin), .fN(M_fNin), .fOv(M_fOvin),
.result(M_resultOut), .PCout(MF_branchPC), .PCsrc(MF_PCsrc),
.mem_reOut(dmem_re), .mem_weOut(dmem_we), .mem_rdIn(dmem_rdData), .mem_wrtOut(dmem_wrtData), .mem_addrOut(dmem_addr));

//stalling MEM/WB
wire [3:0] inW1, inW2, inW3, inW5;
wire [15:0] inW6, inW4;
wire inW7;
assign inW1 = (i_stall == 1'b1 || d_stall == 1'b1) ? W_opIn : M_opIn;
assign inW2 = (i_stall == 1'b1 || d_stall == 1'b1) ? W_rt_addrIn : M_rt_addrIn;
assign inW3 = (i_stall == 1'b1 || d_stall == 1'b1) ? W_rs_addrIn : M_rs_addrIn;
assign inW4 = (i_stall == 1'b1 || d_stall == 1'b1) ? W_instIn : M_instIn;
assign inW5 = (i_stall == 1'b1 || d_stall == 1'b1) ? W_rdIn : M_rdIn;
assign inW6 = (i_stall == 1'b1 || d_stall == 1'b1) ? W_resultIn : M_resultOut;
assign inW7 = (i_stall == 1'b1 || d_stall == 1'b1) ? hltOut : M_hlt_detIn;

//REGISTERS MEM/WB
reg4 MW_op(.in(inW1), .rst(rst_n), .clk(clk), .out(W_opIn));//OP
reg4 MW_rtAddr(.in(inW2), .rst(rst_n), .clk(clk), .out(W_rt_addrIn));
reg4 MW_rsAddr(.in(inW3), .rst(rst_n), .clk(clk), .out(W_rs_addrIn));

reg16 MW_instReg(.in(inW4), .rst(rst_n), .clk(clk), .out(W_instIn));//INSRUCTION
reg4 MW_rdReg(.in(inW5), .rst(rst_n), .clk(clk), .out(W_rdIn));//RD ADDRESS
reg16 MW_resultReg(.in(inW6), .rst(rst_n), .clk(clk), .out(W_resultIn));//MEM_RESULT
reg1 MW_hlt_detReg(.in(inW7), .rst(rst_n), .clk(clk), .out(hltOut));//HLT DETECTION

assign hlt = hltOut;
stage_WB iWB(.clk(clk), .memResult(W_resultIn), .instr(W_instIn), .PCjump(MF_branchPC), .rd(W_rdIn), .rdOut(WD_rd), .wdata(WD_wdata), .regWrite(WD_regWrite));

//MEMORY INSTANTIATION
mem_hierarchy iMEM_HI(.i_addr(i_addr), .instr(i_data), .i_stall(i_stall), .clk(clk), 
			.rst_n(rst_n), .d_stall(d_stall), .d_addr(dmem_addr), .re(dmem_re), 
			.we(dmem_we), .wrt_data(dmem_wrtData), .rd_data(dmem_rdData));

endmodule 
