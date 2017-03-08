/* Title: VerilogAND.v
 * Description: Verilog implementation of 2 input AND gate
 * Date: 2/23/2017
 * Author: Sergiy Kolodyazhnyy
 */
module veriogAND(Fv,Av,Bv);
    input Av,Bv;
	 output Fv;
	 and v_and(Fv,Av,Bv);
endmodule
