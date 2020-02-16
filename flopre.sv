module flopre	#(parameter WIDTH = 8)
					 (input logic clk, reset, enable,
					  input logic [WIDTH - 1:0] d,
					  output logic [WIDTH - 1:0] q);

	//This flip flop outputs d -> q if enable = 1. Otherwise it will hold.
	//
	always_ff @(posedge clk, posedge reset)
		if (reset) q <= 0;
		else if (enable) q <= d;		
					  
endmodule