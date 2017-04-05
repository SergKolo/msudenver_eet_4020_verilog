/* Title: two_by_one_mux.v
 * Author: Sergiy Kolodyazhnyy <skolodya@msudenver.edu>
 * Date: March 9, 2017
 * Purpose: Structural verilog code implementing 2x1 multiplexer
 * Developed on: Ubuntu 16.04 LTS , Quartus Prime Lite 16.1
 * Tested on: DE1-SoC , Cyclone V , 5CSEMA5F31
 */
module two_by_one_mux_synth(m_out,x_in,y_in,sel);
    output m_out;
    input x_in,y_in,sel;
    wire s_not,m1,m2;
    not s1(s_not,sel);
    and and1(m1,s_not,x_in);
    and and2(m2,sel,y_in);
    or or1(m_out,m1,m2);
endmodule
