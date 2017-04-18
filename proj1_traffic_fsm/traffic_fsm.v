module traffic_fsm(hex_pins,main_lights,cross_lights,sensors,clk);

/*
 *
 */

 input clk;
 input [4:0] sensors;
 
 // red,yellow,green,yellow_arrow,green_arrow
 output reg [4:0] main_lights;
 output reg [4:0] cross_lights;
 output [6:0] hex_pins;
 
 reg [3:0] state;
 parameter main_go=0,cross_go=1,
           main_wait=2,cross_wait=3,
			  main_arrow_go=4,cross_arrow_go=5,
           main_arrow_wait=6,cross_arrow_wait=7,
			  all_stop=8;

reg [3:0] sleep;
wire [3:0] current_count;
//module timer(counter,duration,clk,reset);
timer tm0(current_count,sleep,clk);

seven_seg_decoder ssd(hex_pins,current_count);
//module seven_seg_decoder(led_out,bin_in);
initial
    begin 
	     state <= main_go;
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
  * left main - sensors[0]
  * left cross - sensors[1]
  * traffic cross - sensors[2]
  * walk main - sensors[3]
  * walk cross - sensors[4]
  */
 // next state logic
always @(posedge clk)
    begin
	     //wait(! current_count);
	     case (state)
		      main_go:
				    begin
					     if (sensors[0])
						  begin
						      state <= main_wait;
								sleep <= 4'b0111;
						  end
					 end
				    
				main_wait:
				    begin
					     if (sensors[1])
						  begin
					          state <= all_stop;
								 sleep <= 4'b1010;
						  end
					 end
				    
				all_stop:
				    begin
					     if (~sensors[0] & ~sensors[1])
						      state <= main_go;
					 end

		  endcase
	end
endmodule

//--------------------
module timer(counter,duration,clk);

input clk;
input [3:0] duration;
output reg [3:0] counter;
reg [25:0] ticker; 

initial 
    begin
	     ticker = 49999999;
		  counter = duration;
	 end
	 
	 
always @(posedge clk)

		 begin
           if(counter == 0)
			      counter <= duration;
			      ticker <= ticker - 1;
			  if (ticker == 0)
			  begin
					ticker <= 49999999;
					counter <= counter-1;
			  end
		 end
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
