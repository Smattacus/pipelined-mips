module alu_32bit(input logic [31:0] a, b, 
					  input logic [2:0] f,
					  output logic [31:0] y,
					  output logic cout,
					  output logic zero);
			
	//ALU with the following operations (listed by control signal f:)
	//000	- a AND b
	//001 - a OR b
	//010 - a + b
	//011 - not used
	//100 - a AND bbar
	//101 - a OR bbar
	//110 - a - b
	//111 - SLT ( sign less than; a < b).
	
	logic [31:0] bb;
	logic [31:0] s;
	
	assign bb = f[2] ? ~b : b;
	assign {s, cout} = a + bb + f[2];
	
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