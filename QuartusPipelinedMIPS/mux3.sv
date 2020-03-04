module mux3 #(parameter WIDTH = 8)
			  (input logic  [1:0] 			s,
				input logic  [WIDTH - 1:0]	d0, d1, d2,
				output logic [WIDTH - 1:0] y);

 //Three input mux with parameterized data width inputs.
 always_comb
	case (s)
		2'b00	:	y <= d0;
		2'b01	:	y <= d1;
		2'b10	:	y <= d2;
		default: y <= {WIDTH{1'b0}};
	endcase
				
endmodule
