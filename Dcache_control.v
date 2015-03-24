module Dcache_control(clk, rst_n, dirty, hit, drdy, mem_re, mem_we, stall, cache_we, cache_re, userUse);

input hit, clk, rst_n, dirty, userUse;
input drdy; 		//deasserted when a read op has completed from memory.
output reg mem_re;		//read enable for the main mem
output reg stall;		//stall the pipeline		
output reg cache_we;	//Asserted when new data is ready to be written into the icache
output reg mem_we; 
output reg cache_re;

//typedef enum reg [1:0] {NORMAL, READ, WRITE_BACK} state_t;
//state_t state, next_state;

reg[1:0] state, next_state;

localparam NORMAL = 2'b00;
localparam READ = 2'b01;
localparam WRITE_BACK = 2'b10;

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
mem_we = 0;
cache_re = 0;

 case(state)
  NORMAL:
	if (hit | ~(userUse))
	  next_state = NORMAL;
	else if (!hit) begin
	  if (dirty) begin
	    next_state = WRITE_BACK;
	    stall = 1;
	    mem_we = 1;
	    cache_re = 1;
	  end
	  else begin
	    next_state = READ;
	    stall = 1;
	    mem_re = 1;
	  end
	end
	else begin
	  next_state = NORMAL;
	end

  READ:
	if(drdy) begin 
	   cache_we = 1;
	   stall = 1;	 //MAY NOT BE NECESSARY 
	   mem_re = 1;
	   next_state = NORMAL;  
	end
	else begin
	  stall = 1;
	  mem_re = 1;
	  next_state = READ;
	end

  WRITE_BACK:
	if(drdy) begin 
	   cache_re = 1;//necessary?
	   stall = 1; 	 //MAY NOT BE NECESSARY 
	   mem_we = 1;
	   next_state = READ;  
	end
	else begin
	  stall = 1;
	  mem_we = 1;
	  cache_re = 1;
	  next_state = WRITE_BACK;
	end
 
 endcase
end

endmodule
	
