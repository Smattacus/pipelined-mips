module mux2 #(parameter WIDTH = 8)
				 (input logic [WIDTH - 1:0] d0, d1,
				  input logic s,
				  output logic [WIDTH - 1:0] y);
	//TODO: Refactor the input / output ports so the ordering is
	//consistent with mux3.

	// If s = 1, output d1, else output d0.
	assign y = (s) ? d1 : d0;

endmodule
