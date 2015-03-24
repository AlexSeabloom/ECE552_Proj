module Icache_control(clk, rst_n, hit, irdy, mem_re, stall, cache_we, d_inProg);

input hit, clk, rst_n, d_inProg;
input irdy; 		//deasserted when a read op has completed from memory.
output reg mem_re;		//read enable for the main mem
output reg stall;		//stall the pipeline		
output reg cache_we;	//Asserted when new data is ready to be written into the icache

//typedef enum reg {NORMAL, STALL} state_t;
//state_t state, next_state;
reg state, next_state;
localparam NORMAL = 1'b0;
localparam STALL = 1'b1;

always @(posedge clk, negedge rst_n)
  if(!rst_n)
	state <= NORMAL;
  else
	state <= next_state;

always @(*) begin
next_state = NORMAL;
stall = 0;
mem_re = 0;
cache_we = 0;


 case(state)
  NORMAL:
	if (hit)
	  next_state = NORMAL;
	else if (!hit && !d_inProg) begin
	  next_state = STALL;
	  stall = 1;
	  mem_re = 1;
	end
	else
	  next_state = NORMAL;

  STALL:
	if(irdy) begin 
	   cache_we = 1;
	   stall = 1; 	 //MAY NOT BE NECESSARY 
	   mem_re = 1; 	 //may not be necessary
	   next_state = NORMAL;  
	end
	else begin
	  stall = 1;
	  mem_re = 1;   //may not be necessary
	  next_state = STALL;
	end
 
 endcase
end

endmodule
	