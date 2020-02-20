module maindec(input logic [5:0] op,
					output logic RegWrite, MemtoReg, MemWrite,
					output logic ALUSrc, RegDst, Branch, Jump,
					output logic [1:0] aluop);
					
logic [8:0] controls;

//Combine all the output signals into a single variable.
assign {RegWrite, RegDst, ALUSrc, Branch, MemWrite, MemtoReg, aluop, Jump} = controls;

//This is the main lookup table of the instructions.
//Outputs correspond to the different control signals for the processor itself.
always_comb
	case(op)
		6'b000000 : controls <= 9'b110000100; //RTYPE
		6'b100011 : controls <= 9'b101001000; // LW
		6'b101011 : controls <= 9'b001010000; //SW
		6'b000100 : controls <= 9'b000100010;//BEQ
		6'b001000 : controls <= 9'b101000000;//ADDI
		6'b000010 : controls <= 9'b000000011;//J
	default: controls <= 9'bxxxxxxxxx; //Illegal op
	endcase

endmodule