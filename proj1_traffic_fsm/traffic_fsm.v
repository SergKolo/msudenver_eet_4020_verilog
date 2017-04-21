/* Title: traffic_fsm.v
 * Author: Sergiy Kolodyazhnyy <skolodya@msudenver.edu>
 * Date: April 20, 2017
 * Purpose: Implementation of traffic control system as Moore FSM
 * Developed on: Ubuntu 16.04 LTS , Quartus Prime Lite 16.1
 * Tested on: DE1-SoC , Cyclone V , 5CSEMA5F31
 * TODO: implement the pedestrian timer in cross_go and main_go states
 */

module traffic_fsm(hex_pins,main_lights,cross_lights,sensors,clk);

input clk; // Cyclone's 50MHz clock
/*
* left main - sensors[0]
* left cross - sensors[1]
* traffic cross - sensors[2]
* walk main - sensors[3]
* walk cross - sensors[4]
*/
input [4:0] sensors;

// order of the lights:
// red,yellow,green,yellow_arrow,green_arrow
output reg [4:0] main_lights;
output reg [4:0] cross_lights;
output [6:0] hex_pins;

reg [3:0] state;
// constants for idiomatic state definitions
parameter main_go=0,cross_go=1,
		  main_wait=2,cross_wait=3,
		  main_arrow_go=4,cross_arrow_go=5,
		  main_arrow_wait=6,cross_arrow_wait=7,
		  all_stop=8;

reg [3:0] sleep;
wire [3:0] current_count; // counter output

/* These registers help keeping track of which states have
 * been visited during transitions between a specific "go"
 * state and "all_stop" state.
 */
reg cross_tracker,cross_arrow_tracker,main_arrow_tracker;

//module timer(counter,duration,clk);
timer tm0(current_count,sleep,clk);

//module seven_seg_decoder(led_out,bin_in);
seven_seg_decoder ssd(hex_pins,current_count);

// ensure we start out with main street traffic
initial
    begin 
	     state <= main_go;
		  sleep <= 6;
	 end

// output logic
always @(posedge clk)
    begin
	     case(state)
		      main_go:
				    begin
				        main_lights <= 5'b00100;
					     cross_lights <= 5'b10000;
				    end
				cross_go:
                begin
                    main_lights <= 5'b10000;
					     cross_lights <= 5'b00100;
                end
				main_wait:
				    begin
					     main_lights <= 5'b01000;
					     cross_lights <= 5'b10000;
					 end
				cross_wait:
				    begin
					     main_lights <= 5'b10000;
					     cross_lights <= 5'b01000;
                end
				main_arrow_go:
				    begin
					     main_lights <= 5'b00001;
					     cross_lights <= 5'b10000;
					 end
				cross_arrow_go:
				    begin
					     main_lights <= 5'b10000;
					     cross_lights <= 5'b00001;
                end
			   main_arrow_wait:
				    begin
					     main_lights <= 5'b00010;
					     cross_lights <= 5'b10000;
					 end
				cross_arrow_wait:
				    begin
					     main_lights <= 5'b10000;
					     cross_lights <= 5'b00010;
					 end
			   all_stop:
				   begin
					    main_lights <= 5'b10000;
						 cross_lights <= 5'b10000;

					end
		  endcase
	 end
 		
/*
 * This portion handles state transitions and propagates
 * new value to the timer that keeps FSM in specific states
 *
 */
always @(posedge clk)
    begin

		if(state == main_go && (sensors[0]|sensors[1]|sensors[2]|sensors[4]))
		begin
		    if( current_count == 4'b0001 )
			     sleep = 4;
			 if( current_count == 4'b0000 )
			     state = main_wait;
		end
		
		else if(state == main_wait || state == cross_wait || 
		        state == main_arrow_wait || state == cross_arrow_wait)
		begin
		    if( current_count == 4'b0001 )
			     sleep = 3;
			 if( current_count == 4'b000)
			     state = all_stop;
		end
		
		else if(state == cross_go)
		begin
		    if( current_count == 4'b0001 )
			 begin
			     cross_tracker = 1'b1;
			     sleep = 3;
				  if (sensors[1])
				      cross_arrow_tracker = 1'b1;
				  if (sensors[0])
				      main_arrow_tracker = 1'b1;
			 end
			 if( current_count == 4'b0000 )
			     state = cross_wait;
		end
		
		else if(state == cross_arrow_go)
		begin
		    if( current_count == 4'b0001 )
			 begin
			     sleep = 3;
				  cross_arrow_tracker = 1'b0;
			 end
			 if( current_count == 4'b0000 )
			     state = cross_arrow_wait;
		end
		
	   else if(state == main_arrow_go)
		begin
		    if( current_count == 4'b0001 )
			 begin
			     sleep = 3;
				  main_arrow_tracker = 1'b0;
			 end
			 if( current_count == 4'b0000 )
			     state = main_arrow_wait;
		end
		
		else if(state == all_stop)
		begin
		    // we've come from main_go state, and there's cross traffic waiting
		    if ( current_count == 4'b0001 && ~cross_tracker )
			     sleep = 6;
			 if ( current_count == 4'b0000 && ~cross_tracker )
			     state = cross_go;
				  
			 // we've let cross traffic go, but somebody is waiting for an arrow
			 if ( cross_tracker && (cross_arrow_tracker|main_arrow_tracker) )
			 begin
			     if ( current_count == 4'b0001 )
			     		sleep = 4;
				  if ( current_count == 4'b0000 )
				      if ( cross_arrow_tracker )
				          state = cross_arrow_go;
						else
						    state = main_arrow_go;
		 
			 end
			 
			 // we've let cross traffic go, but nobody is waiting for an arrow
			 else if ( cross_tracker && (~cross_arrow_tracker && ~main_arrow_tracker) )
			 begin
			     if ( current_count == 4'b0001 )
				      sleep = 6;
		        if ( current_count == 4'b0000 )
				  begin
				      cross_tracker = 1'b0;
				      state = main_go;
				  end
			 end
			 
		end

    end // End of transition logic
endmodule

/* This module returns countdown value from initial value
 * "duration" to 0. The module uses Cyclone's 50MHz clock
 * which ticks at 50 million times each second, thus counter
 * is decremented each second
 */
module timer(counter,duration,clk);

input clk;
input [3:0] duration;
output reg [3:0] counter;
reg [25:0] ticker; 

parameter tick_count = 49999999;
initial
    begin
	     ticker <= tick_count;
	     counter <= duration;
	 end
	 
always @(posedge clk)
	 begin
	      // checking counter status is most important
			// hence it's top most statement
	      if ( counter == 0)
			    begin
				     ticker <= tick_count;
					  counter <= duration;
				 end
	      ticker <= ticker - 1;
			if ( ticker == 0 )
			    counter <= counter - 1;
	 end
endmodule

/* This module is technically boilerplate code
 * that is reused from Lab 3. Uses data flow modeling.
 */
module seven_seg_decoder(led_out,bin_in);

    output [6:0] led_out;
    input [3:0] bin_in;
      
    wire [3:0] bin_in_inv;
    assign bin_in_inv = ~bin_in;
	  

    /* A => bin_in[3]
     * B => bin_in[2]
     * C => bin_in[1]
     * D => bin_in[0]
     */

     //led_out[6] = A’B’C’ + A’BCD + ABC’D’
     assign led_out[6] = (bin_in_inv[3] & bin_in_inv[2] & bin_in_inv[1]) |
                         (bin_in_inv[3] & bin_in[2] & bin_in[1] & bin_in[0]) |
                         (bin_in[3] & bin_in[2] & bin_in_inv[1] & bin_in_inv[0]);

     //led_out[5] = A’B’D + A’B’C + A’CD +ABC’D
     assign led_out[5] = (bin_in_inv[3] & bin_in_inv[2] & bin_in[0]) | 
                         (bin_in_inv[3] & bin_in_inv[2] & bin_in[1]) | 
                         (bin_in_inv[3] & bin_in[1] & bin_in[0]) | 
                         (bin_in[3] & bin_in[2] & bin_in_inv[1] & bin_in[0]);

     //led_out[4] = A’D + B’C’D + A’BC’
     assign led_out[4] = (bin_in_inv[3] & bin_in[0]) |
                         (bin_in_inv[2] & bin_in_inv[1] & bin_in[0]) |
                         (bin_in_inv[3] & bin_in[2] & bin_in_inv[1]);

     //led_out[3] = B’C’D + BCD + A’BC’D’ + AB’CD’
     assign led_out[3] = (bin_in_inv[2] & bin_in_inv[1] & bin_in[0]) | 
                         (bin_in[2] & bin_in[1] & bin_in[0]) | 
                         (bin_in_inv[3] & bin_in[2] & bin_in_inv[1] & bin_in_inv[0]) | 
                         (bin_in[3] & bin_in_inv[2] & bin_in[1] & bin_in_inv[0]);

     //led_out[2] = ABD’ + ABC + A’B’CD’
     assign led_out[2] = (bin_in[3] & bin_in[2] & bin_in_inv[0]) | 
                         (bin_in[3] & bin_in[2] & bin_in[1]) | 
                         (bin_in_inv[3] & bin_in_inv[2] & bin_in[1] & bin_in_inv[0]);

     //led_out[1] = BCD’ + ACD + ABD’ + A’BC’D
     assign led_out[1] = (bin_in[2] & bin_in[1] & bin_in_inv[0]) | 
                         (bin_in[3] & bin_in[1] & bin_in[0]) | 
                         (bin_in[3] & bin_in[2] & bin_in_inv[0]) | 
                         (bin_in_inv[3] & bin_in[2] & bin_in_inv[1] & bin_in[0]);

     //led_out[0] = A’B’C’D + A’BC’D’ + AB’CD + ABC’D
     assign led_out[0] = (bin_in_inv[3] & bin_in_inv[2] & bin_in_inv[1] & bin_in[0]) | 
                         (bin_in_inv[3] & bin_in[2] & bin_in_inv[1] & bin_in_inv[0]) | 
                         (bin_in[3] & bin_in_inv[2] & bin_in[1] & bin_in[0]) | 
                         (bin_in[3] & bin_in[2] & bin_in_inv[1] & bin_in[0]);
endmodule