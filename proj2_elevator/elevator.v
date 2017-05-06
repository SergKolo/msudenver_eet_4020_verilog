module elevator(leds,sd_state,switches,clock);
    // for testing only
	 output wire [2:0] sd_state;
	 
    input [9:0] switches;
    output reg [9:0] leds;
    wire [9:0] is_requested;
	 reg [9:0] request_clear;
    input clock;

	 // module sequence_detector(current_state,request,clear,switch,clock);
	 sequence_detector sd0(sd_state,is_requested[0],
	                       switches[1],switches[0],clock);
								  
	 always @(posedge clock) begin

        if (is_requested[0])
		      leds[0] <= 1;
		  else
		      leds[0] <= 0;
	 end
		  
endmodule

/* "Pluggable" modules
 * 
 */
 
module elevator_car_driver(current_floor,direction,destination,clock);
    output reg [4:0] current_floor; // 0000 to 1010
	 input direction; // 0 down, 1 up
	 input [4:0] destination;
	 input clock; // Slow clock or implement 2 sec delay here ?
	 
	 reg [4:0] counter;
	 
	 // which floor do we start at ?
	 initial begin
	     current_floor <= 0;
		  counter <= 0;
	 end
	 
	 always @(posedge clock) begin
	     current_floor <= counter;
	 end
	 
	 always @(posedge clock) begin
	 
	     if ( counter != destination )
	         if (direction)
	             counter = counter + 1;
		      else
		          counter = counter - 1;
	 end
	 
endmodule

module sequence_detector(current_state,request,clear,switch,clock);
    output reg request;
	 output reg [2:0] current_state;
	 
	 input clear,switch,clock;
	 reg [1:0] state;
	 parameter state_a=0, state_b=1,state_c=3;
	 
	 initial begin
	     state <= state_a;
	 end
	 
	 always @(posedge clock)
	     current_state <= state;
	     
	 
	 always @(posedge clock) begin
	     case (state)
		      state_a:
				    if (switch) begin
				        state <= state_b;
					 end

				state_b:
				    if (!switch) begin
					     state <= state_c;
					 end
					 
				state_c:
				    if (clear) begin
					 	  request <= 0;
					     state <= state_a;
					 end
					 else
					     request <= 1;
		  endcase
	 end
endmodule

/*
 *
 */

/* Test benches
 * 
 */
 
module testbench_car_driver;

    reg course,tbclock;
    reg [9:0] target;
    wire [9:0] floor;

    // module elevator_car_driver(current_floor,direction,destination,clock);
    elevator_car_driver cd0(floor,course,target,tbclock);
    initial
       tbclock = 1'b0;

    always
        #1 tbclock = ~tbclock;	
	 
    initial begin
        $monitor("At time",$time," target: %h floor: %h",target,floor);
        #200 $finish;
    end

    initial begin
		  #5 course <= 1;
		  #1 target <= 5;
		  
		  #15 course <= 0;
		  #1  target <= 3;
		  
		  #15 course <= 1;
		  #1 target <= 10;
		  
		  //#45 target <= 10;
    end

endmodule
 
module sequence_detector_testbench;

reg [9:0] switch_in;
reg tb_clock;
wire [9:0] light_out;
wire [2:0] sd_state;

//module elevator(leds,switches,clock);
elevator e0(light_out,sd_state,switch_in,tb_clock);

initial begin
    $monitor("At time",$time," switch is %b and led %b. State %b ",switch_in,light_out,sd_state);
	 #200 $finish;
end

initial begin
    switch_in = 0;
	 #20 switch_in[0] = 1;
	 #20 switch_in[0] = 0;
	 #20 switch_in[1] = 1;
	 #20 switch_in[1] = 0;
	 #20 switch_in[2] = 1;
end

initial
    tb_clock = 1'b0;

always
    #1 tb_clock = ~tb_clock;	 
	 
endmodule