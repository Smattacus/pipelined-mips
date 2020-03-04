module alu_32bit(input logic [31:0] a, b, 
					  input logic [2:0] f,
					  output logic [31:0] y,
					  output logic cout,
					  output logic zero);
			
	//alu with the following operations (listed by control signal f:)
	//000	- a and b
	//001 - a or b
	//010 - a + b
	//011 - not used
	//100 - a and bbar
	//101 - a or bbar
	//110 - a - b
	//111 - slt ( sign less than; a < b).
	
	logic [31:0] bb;
	logic [31:0] s;
	
	assign bb = f[2] ? ~b : b;
	assign {cout, s} = a + bb + f[2];
	
	always_comb
		case(f[1:0])
			2'b00	:	y <= a & bb;
			2'b01	:	y <= a | bb;
			2'b10	:	y <= s;
			2'b11 :	y <= {31'b0, s[31]};
			default 	: y <= 32'b0;
		endcase

	assign zero = (y == 32'b0);	
		
endmodule
