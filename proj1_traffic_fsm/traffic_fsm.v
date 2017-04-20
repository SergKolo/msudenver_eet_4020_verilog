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

reg [3:0] sleep;// = 4'b1010; // starting point of timer
wire [3:0] current_count; // counter output

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
						  //cross_tracker <= 1'b0;
						  //cross_arrow_tracker <= 1'b0;
						  //main_arrow_tracker <= 1'b0;
				    end
				cross_go:
                begin
                    main_lights <= 5'b10000;
					     cross_lights <= 5'b00100;
						  //cross_tracker <= 1'b1;
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
						  //main_arrow_tracker <= 1'b1;
					 end
				cross_arrow_go:
				    begin
					     main_lights <= 5'b10000;
					     cross_lights <= 5'b00001;
						  //cross_arrow_tracker <= 1'b0;
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
 		
always @(posedge clk)
    begin
	     // propagate the new value of sleep to timer
	     //if(current_count == 4'b0001)
		    //  begin
		if(state == main_go && (sensors[0]|sensors[1]|sensors[2]|sensors[4]))
		begin
		    if( current_count == 4'b0001 )
			     sleep = 4;
			 if( current_count == 4'b0000 )
			     state = main_wait;
		end
		
		else if(state == main_wait || state == cross_wait || state == main_arrow_wait || state == cross_arrow_wait)
		begin
		    if( current_count == 4'b0001 )
			     sleep = 3;
			 if( current_count == 4'b000)
			     state = all_stop;
		end
		
		// handle cross left, check for main left
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
		
		//
		else if(state == cross_arrow_go)
		begin
		    if( current_count == 4'b0001 )
			 begin
			     sleep = 3;
//				  if (sensors[0])
				  cross_arrow_tracker = 1'b0;
			 end
			 if( current_count == 4'b0000 )
			     state = cross_arrow_wait;
		end
		//
		
	   else if(state == main_arrow_go)
		begin
		    if( current_count == 4'b0001 )
			 begin
			     sleep = 3;
//				  if (sensors[0])
				  main_arrow_tracker = 1'b0;
			 end
			 if( current_count == 4'b0000 )
			     state = main_arrow_wait;
		end
		
		else if(state == all_stop)
		begin
		    // we've come from main_go state, and there's cross traffic waiting
			 // we shouldn't need sensors[2] here, because cross_tracker will tell us if we come from main_go
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
		
//			 if (sensors[2])
//			 begin
//				  sleep = 6;
//			 end
//			 else
//			 begin
//				  sleep = 6;
//			 end
				//end
				
//	    if(current_count == 4'b0000)
//					begin
//					
//						if(state == main_go && (sensors[0]|sensors[1]|sensors[2]|sensors[4]))
//						begin
//							 state = main_wait;
//						end
//						
//						else if(state == main_wait || state == cross_wait)
//						begin
//							 state = all_stop;
//						end
//						
//						else if(state == cross_go)
//						begin
//							 state = cross_wait;
//						end
//						else if(state == all_stop)
//						begin
//	//reg cross_tracker,cross_arrow_tracker,main_arrow_tracker;
//                      
//							 if (sensors[2])
//							 begin
//								  state = cross_go;
//							 end
//							 else
//							 begin
//								  state = main_go;
//							 end
//							 
//						end
//					end
    end
endmodule

//--------------------
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
    //counter <= duration;
	 begin
	      if ( counter == 0)
			    begin
				     ticker <= tick_count;
					  counter <= duration;
				 end
	      ticker <= ticker - 1;
			if ( ticker == 0 )
			    counter <= counter - 1;
	 end
	 

//parameter tick_count = 49999999;
//
////always @(posedge duration)
//initial
//    begin
//	     ticker <= tick_count;
//		  counter <= duration;
//	 end
//	 
//	 
//always @(posedge clk or posedge reset)
//       if(reset)
//		 begin
//		     ticker <= tick_count;
//			  counter <= duration;
//		 end
//		 else
//		 begin
//   	     ticker <= ticker - 1;
//			  if (ticker == 0)
//			  begin
//					ticker <= tick_count;
//					//if (counter > 0)
//					counter <= counter-1;
//			  end
//		 end
endmodule

//-------
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

     // note: tmp variables use implicit nets

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

module stimulus_seven_seg;
    reg [3:0] bin_in = 4'b1011;
    wire [3:0] led_out;
    reg clk,rst;
	 
    //module timer(counter,duration,clk, reset);
    timer tm1(led_out,bin_in,clk,rst);
    // instantiate the seven segment decoder
    //seven_seg_decoder s1(led_out,bin_in);
    // We'll make a counter that counts from 00 to 1111
    // In order to do that, we'll need a clock
    initial 
        clk = 1'b0;
                        
    always
        #5 clk = ~clk; //toggle clock every 5 time units
            
    //always @(posedge clk)
        //bin_in = bin_in + 1;
            
    initial
    begin
        $monitor("At time",$time,"binary input=%b and hex output=%b\n",bin_in,led_out);
		  //#20 rst = 1;
		  //#1 rst=0;
        #160 $stop;
    end
          
endmodule