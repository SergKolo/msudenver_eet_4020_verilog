/* Title: seven_seg_decoder.v
 * Author: Sergiy Kolodyazhnyy <skolodya@msudenver.edu>
 * Date: March 9, 2017
 * Purpose: Data-flow code for simple binary to hex display driver
 * Developed on: Ubuntu 16.04 LTS , Quartus Prime Lite 16.1
 * Tested on: DE1-SoC , Cyclone V , 5CSEMA5F31
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
    reg [3:0] bin_in = 0000;
    wire [6:0] led_out;
    reg clk;
	  
    // instantiate the seven segment decoder
    seven_seg_decoder s1(led_out,bin_in);
    // We'll make a counter that counts from 00 to 1111
    // In order to do that, we'll need a clock
    initial 
        clk = 1'b0;
			
    always
        #5 clk = ~clk; //toggle clock every 5 time units
            
    always @(posedge clk)
        bin_in = bin_in + 1;
            
    initial
    begin
        $monitor("At time",$time,"binary input=%b and hex output=%h\n",bin_in,led_out);
        #160 $stop;
    end
	  
endmodule
