module elevator(current_floor,leds,switches,clock);
    //output wire [2:0] sd_state; // testing only
    //integer test[7:0] = {11,12,13,14,15,16,17,18};     
    input [9:0] switches;
    output reg [9:0] leds;
    wire [9:0] is_requested;
    wire [9:0] request_clear;
    input clock;

    output wire [4:0] current_floor;
    reg [4:0] request_floor;
    reg up;

    //module elevator_car_driver(current_floor,direction,destination,clock);
    elevator_car_driver cd0(request_clear,current_floor,up,request_floor,clock);

     // module sequence_detector(current_state,request,clear,switch,clock);
     sequence_detector sd0(is_requested[0],
                           request_clear[0],switches[0],clock);
                                  
     sequence_detector sd1(is_requested[1],
                           request_clear[1],switches[1],clock);
                                  
     sequence_detector sd2(is_requested[2],
                           request_clear[2],switches[2],clock);
                                  
     sequence_detector sd3(is_requested[3],
                           request_clear[3],switches[3],clock);
                                  
     sequence_detector sd4(is_requested[4],
                           request_clear[4],switches[4],clock);
                                  
     sequence_detector sd5(is_requested[5],
                           request_clear[5],switches[5],clock);
                                  
     sequence_detector sd6(is_requested[6],
                           request_clear[6],switches[6],clock);
                                  
     sequence_detector sd7(is_requested[7],
                           request_clear[7],switches[7],clock);
                                  
     sequence_detector sd8(is_requested[8],
                           request_clear[8],switches[8],clock);
                                  
     sequence_detector sd9(is_requested[9],
                           request_clear[9],switches[9],clock);


    always @(posedge clock) begin
        if (|is_requested) begin
            if (is_requested[0]) begin
                  leds[0] <= 1;
                  request_floor <= 0;
                  if (current_floor > 0)
                      up <= 0;
            end          
            else
                  leds[0] <= 0;

            if (is_requested[1]) begin
                  leds[1] <= 1;
                  request_floor <= 1;
                  if ( current_floor > 1)
                      up <= 0;
                  else
                      up <= 1;
            end          
            else
                  leds[1] <= 0;

            if (is_requested[2]) begin
                  leds[2] <= 1;
                  request_floor <= 2;
                  if ( current_floor > 2)
                      up <= 0;
                  else
                      up <= 1;
            end
          
            else
                  leds[2] <= 0;
        end

        else
            if ( current_floor < 5 ) begin
                request_floor <= 0;
                up <= 0;
            end
            else begin
                request_floor <= 9;
                up <= 1;
            end
    end
          
endmodule

/* "Pluggable" modules
 * 
 */
 
module elevator_car_driver(clear,current_floor,direction,destination,clock);
     output reg [4:0] current_floor; // 0000 to 1010
     output reg [9:0] clear;
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
    // Should I add the "state" indicator (moving/stationary)     
     always @(posedge clock) begin
     
         if ( counter != destination ) begin
             clear[counter] <= 0;
             if (direction)
                 counter = counter + 1;
             else
                  counter = counter - 1;
         end
         else
             clear[counter] <= 1;
             //we arrived, clear the request
     end
     
endmodule

module sequence_detector(request,clear,switch,clock);
    output reg request;
     //output reg [2:0] current_state;
     
     input clear,switch,clock;
     reg [1:0] state;
     parameter state_a=0, state_b=1,state_c=3;
     
     initial begin
         state <= state_a;
     end
     
     //always @(posedge clock)
     //    current_state <= state;
         
     
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
 
module testbench_single_request;
    
   reg tbclock;
   reg [9:0] sw;
   wire [4:0] cf;
   wire [9:0] lights;
   //module elevator(current_floor,leds,switches,clock);
   elevator ev0(cf,lights,sw,tbclock);

    initial
       tbclock = 1'b0;

    always
        #1 tbclock = ~tbclock;    
     
    initial begin
        $monitor("At time",$time," switches:%b,lights:%b,floor:%d",sw,lights,cf);
        #200 $finish;
    end

    initial begin
        #5 sw[2] <= 1;
        #1 sw[2] <= 0;

        #50 sw[1] <= 1;
        #1 sw[1] <= 0;
    end

endmodule
//--
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
wire [9:0] floor_num;

// Original testbench included state of the sequence detector
// Removed it because it's sufficient to observe state change via LED
//wire [2:0] sd_state;

//module elevator(leds,switches,clock);
elevator e0(floor_num,light_out,switch_in,tb_clock);

initial begin
    $monitor("At time",$time," switch is %b and led %b. State %b ",switch_in,light_out); //,sd_state);
     #200 $finish;
end

initial begin
    // original testing was performed with switch[1] being the request_clear input
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
