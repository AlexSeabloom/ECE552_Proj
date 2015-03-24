module cpu_tb();

reg clk,rst_n;

wire [15:0] pc;

//////////////////////
// Instantiate CPU //
////////////////////
cpu iCPU(.clk(clk), .rst_n(rst_n), .hlt(hlt), .pc(pc));

initial begin
  clk = 0;
  $display("rst assert\n");
  rst_n = 0;
  @(posedge clk);
  @(negedge clk);
  rst_n = 1;
	$monitor("I:%b - D:%b |clk:%b | pc:%h | rst_n:%b hit%b, irdy%b, mem_re%b, cache_we%b, d_inProg%b, state:%b", 
	  iCPU.i_stall, iCPU.d_stall, clk, iCPU.IF.thePC.pcReg, iCPU.IF.thePC.rst_n, 
		iCPU.iMEM_HI.Icontrol.hit, iCPU.iMEM_HI.Icontrol.irdy, iCPU.iMEM_HI.Icontrol.mem_re, iCPU.iMEM_HI.Icontrol.cache_we,
		iCPU.iMEM_HI.Icontrol.d_inProg, iCPU.iMEM_HI.Icontrol.state);
	//$monitor("%h -- %b", pc, clk);
  $display("rst deassert\n");
end 
  
always
  #1 clk = ~clk;
  
initial begin
  @(posedge hlt);
  @(posedge clk);
  $stop();
end  

endmodule
