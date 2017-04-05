/* Title: two_by_one_mux.v
 * Author: Sergiy Kolodyazhnyy <skolodya@msudenver.edu>
 * Date: March 9, 2017
 * Purpose: Structural verilog code implementing 2x1 multiplexer
 * Developed on: Ubuntu 16.04 LTS , Quartus Prime Lite 16.1
 * Tested on: DE1-SoC , Cyclone V , 5CSEMA5F31
 */
module two_by_one_mux(m_out,x_in,y_in,sel);
    output m_out;
    input x_in,y_in,sel;
    wire s_not,m1,m2;
    not s1(s_not,sel);
    and and1(m1,s_not,x_in);
    and and2(m2,sel,y_in);
    or or1(m_out,m1,m2);
endmodule

module mux_tb;

    reg local_x_in,local_sel,local_y_in;
    wire local_m_out;

    two_by_one_mux tbom(local_m_out,local_x_in,local_y_in,local_sel);

    initial
    begin
        $monitor($time,"x_in=%b,y_in=%b,sel=%b,---m_out=%b\n",
		           local_x_in,local_y_in,local_sel,local_m_out);
    end
    // Stimulus inputs
    initial begin
            local_x_in=0;local_y_in=0;local_sel=0;
        #10 local_x_in=0;local_y_in=0;local_sel=0;
        #10 local_x_in=0;local_y_in=1;local_sel=0;
        #10 local_x_in=1;local_y_in=0;local_sel=0;
        #10 local_x_in=1;local_y_in=1;local_sel=0;
        #10 local_x_in=0;local_y_in=0;local_sel=1;
        #10 local_x_in=0;local_y_in=1;local_sel=1;
        #10 local_x_in=1;local_y_in=0;local_sel=1;
        #10 local_x_in=1;local_y_in=1;local_sel=1;
    end
endmodule
