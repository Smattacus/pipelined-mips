module ls2(input logic [31:0] a,
			  output logic [31:0] y);

	//left shift by two bits. shift in zeros.
	//(multiply by four.)
	assign y = {a[29:0], 2'b00};
			  
endmodule
