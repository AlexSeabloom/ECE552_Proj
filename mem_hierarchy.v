module mem_hierarchy(i_addr, instr, i_stall, clk, rst_n, d_stall, d_addr, re, we, wrt_data, rd_data);

input [15:0] i_addr, d_addr, wrt_data;
input clk, rst_n, re, we;//re and we are only applied to Dcache, since Icache is always reading

output [15:0] instr, rd_data;
output i_stall, d_stall;

// I cache signals
wire [63:0] i_rd_data;
wire [7:0] i_tag_out; 
wire i_hit, i_dirty;
wire i_we, i_re, i_wdirty;
wire i_mm_re;

// D cache signals
wire [63:0] d_rd_data;
wire [7:0] d_tag_out; 
wire d_hit, d_dirty;
wire d_we, d_re, d_wdirty;
wire d_cont_we, d_cont_re;
wire d_mm_we, d_mm_re;
wire [63:0] d_data_in;
wire [63:0] combinedInput, combinedInputMem;

//MAIN MEM signals
wire mm_ready;
wire [63:0] mm_data_out;
wire [13:0] mm_addr;
wire mm_re;

// Instantiation of I and D caches
cache ICache(.clk(clk),.rst_n(rst_n),.addr(i_addr[15:2]),.wr_data(mm_data_out),
			.wdirty(i_wdirty),.we(i_we),.re(1'b1),.rd_data(i_rd_data),
			.tag_out(i_tag_out),.hit(i_hit),.dirty(i_dirty));

cache DCache(.clk(clk),.rst_n(rst_n),.addr(d_addr[15:2]),.wr_data(d_data_in),
			.wdirty(d_we & we),.we(d_we),.re(d_re),.rd_data(d_rd_data),//i think wdirty could be just d_we 
			.tag_out(d_tag_out),.hit(d_hit), .dirty(d_dirty));

// ICACHE STATE MACHINE
Icache_control Icontrol(.clk(clk), .rst_n(rst_n), .hit(i_hit), 
			.irdy(mm_ready), .mem_re(i_mm_re), .stall(i_stall), 
			.cache_we(i_we), .d_inProg(d_stall));

//DCACHE STATE MACHINE
Dcache_control Dcontrol(.clk(clk), .rst_n(rst_n), .dirty(d_dirty), .hit(d_hit), 
			.drdy(mm_ready), .mem_re(d_mm_re), .mem_we(d_mm_we), .stall(d_stall), 
			.cache_we(d_cont_we), .cache_re(d_cont_re),
			.userUse(re | we));//NEED TO FIGURE THIS OUT


//MAIN MEMORY INSTANTIATION
unified_mem MAINMEM(.clk(clk), .rst_n(rst_n), .addr(mm_addr), 
		.re(mm_re), .we(d_mm_we), .wdata(d_rd_data), 
		.rd_data(mm_data_out), .rdy(mm_ready));

//MAIN MEM INPUT MUXES
assign mm_addr = (d_mm_we | d_mm_re) ? (d_addr[15:2]):
		(i_addr[15:2]);

//always @(posedge clk)
//	if(!rst_n)
//	  mm_addr <= 14'd0;
//	else if (d_mm_we | d_mm_re)
//	  mm_addr <= d_addr[15:2];
//	else
//	  mm_addr <= i_addr[15:2];

assign mm_re = (d_mm_we | d_mm_re) ? d_mm_re://block I if D is doing something
		i_mm_re;

//D CACHE INPUT MUXES
assign d_data_in = (d_mm_re) ? combinedInputMem:
		combinedInput;//NOT 64 BITS

assign d_we = (d_cont_we) ? 1'b1:
		we;

assign d_re = (re | we | d_cont_re);

//OUTPUT DECODING
assign instr = (i_addr[1:0] == 2'b00) ? i_rd_data[15:0] : 
		(i_addr[1:0] == 2'b01) ? i_rd_data[31:16] :
		(i_addr[1:0] == 2'b10) ? i_rd_data[47:32] :
		i_rd_data[63:48];

assign rd_data = (d_addr[1:0] == 2'b00) ? d_rd_data[15:0] :
		(d_addr[1:0] == 2'b01) ? d_rd_data[31:16] :
		(d_addr[1:0] == 2'b10) ? d_rd_data[47:32] :
		d_rd_data[63:48];

//D USER WRITE DATA ENCODING
assign combinedInput = (d_addr[1:0] == 2'b00) ? {d_rd_data[63:16], wrt_data} :
			(d_addr[1:0] == 2'b01) ? {d_rd_data[63:32], wrt_data, d_rd_data[15:0]} :
			(d_addr[1:0] == 2'b10) ? {d_rd_data[63:48], wrt_data, d_rd_data[31:0]} :
			{wrt_data, d_rd_data[47:0]};

//D MEM WRITE DATA ENCODING
assign combinedInputMem = (d_addr[1:0] == 2'b00) ? {mm_data_out[63:16], wrt_data} :
			(d_addr[1:0] == 2'b01) ? {mm_data_out[63:32], wrt_data, mm_data_out[15:0]} :
			(d_addr[1:0] == 2'b10) ? {mm_data_out[63:48], wrt_data, mm_data_out[31:0]} :
			{wrt_data, mm_data_out[47:0]};

endmodule
