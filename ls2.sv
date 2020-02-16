module ls2(input logic [31:0] a,
			  output logic [31:0] y);

	//Left shift by two bits. Shift in zeros.
	//(Multiply by four.)
	assign y = {a[29:0], 2'b00};
			  
endmodule