/* Title: eight_bit_counter.v
 * Author: Sergiy Kolodyazhnyy <skolodya@msudenver.edu>
 * Date: May 2nd, 2017
 * Purpose: Behavioral module for simple 8-bit binary counter 
 * Developed on: Ubuntu 16.04 LTS , Quartus Prime Lite 16.1
 * Tested on: DE1-SoC , Cyclone V , 5CSEMA5F31
 */

module eight_bit_counter(count_out,enable,clock,clear);
    input enable,clock,clear;
	 output [7:0] count_out;
	 wire [6:0] temp;
 	 // Use counter_clock for RTL simulation, clk_1hz for hardware test
	 wire counter_clock;
	 //assign counter_clock = clock;
	 frequency_divider clk_1hz(counter_clock,clock);
	 
	 // module t_ff(q_out,t_in,clock,clear);
	 t_ff tff0(count_out[0],enable,counter_clock,clear);
	 
	 assign temp[0] = count_out[0] & enable;
	 t_ff tff1(count_out[1],temp[0],counter_clock,clear);
	 
	 assign temp[1] = temp[0] & count_out[1];
	 t_ff tff2(count_out[2],temp[1],counter_clock,clear);
	 
	 assign temp[2] = temp[1] & count_out[2];
	 t_ff tff3(count_out[3],temp[2],counter_clock,clear);
	 
	 assign temp[3] = temp[2] & count_out[3];
	 t_ff tff4(count_out[4],temp[3],counter_clock,clear);
	 
	 assign temp[4] = temp[3] & count_out[4];
	 t_ff tff5(count_out[5],temp[4],counter_clock,clear);
	 
	 assign temp[5] = temp[4] & count_out[5];
	 t_ff tff6(count_out[6],temp[5],counter_clock,clear);
	 
	 assign temp[6] = temp[5] & count_out[6];
	 t_ff tff7(count_out[7],temp[6],counter_clock,clear);
endmodule

module frequency_divider(clock_out,clock_in);
    input clock_in;
	 output reg clock_out;
	 /* 
	  * Frequency divider should be 1 cycle per second,
	  * which means it toggles twice in 1 second.
	  * 50000000 cycles is 1 second, and half of that is 
	  * 25000000. To represent that we need
	  * log_2 (25000000) = 24.57 or 25 bit wide vector
	  */
	 reg [24:0] counter;
	 
	 initial
	 begin
	     counter = 0;
		  clock_out = 0;
	 end
	 
	 always @(posedge clock_in)
	 begin
	     if(counter == 0)
		  begin
		      counter <= 24999999;
				clock_out <= ~clock_out;
		  end
		  else
		      counter <= counter - 1;    
	 end	 
endmodule


/* T Flip Flop, uses characteristic equation and
 * behavioral modeling
 */
module t_ff(q_out,t_in,clock,clear);
    input t_in,clock,clear;
	 output reg q_out;

	 always @(posedge clock or negedge clear)
	     begin
		      if(~clear)
				   q_out <= 1'b0;
				else
				    //if(t_in)
				    q_out <= t_in ^ q_out;  
		  end
endmodule

module stimulus_counter;
   reg clear, enable, clock;
	wire [7:0] count_out;
	
	// Instantiate the eight-bit synchronous counter
	// module eight_bit_counter(count_out,enable,clock,clear);
	eight_bit_counter s1(count_out,enable,clock,clear);
	
	initial
	begin
	    $monitor("At time",$time," clear = %b, enable = %b, and count = %h\n",clear,enable,count_out);
		 #2700 $finish;
	end
	
	// Initialize the inputs clear and enable
	initial
	begin
	    clear = 0;
		 enable = 0;
		 #10 clear = 1;
		 #20 enable = 1;
		 #2600 clear = 0;
	end
	
	// We'll make a counter that counts from 00000000 to 11111111.
	// In order to do that, we'll need a clock.
	initial
	   clock = 1'b0;
	always
	    #5 clock = ~clock; // Toggle clock every 5 time units.
endmodule
