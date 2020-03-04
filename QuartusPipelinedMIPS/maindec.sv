module maindec(input logic [5:0] op,
					output logic regwrite, memtoreg, memwrite,
					output logic alusrc, regdst, branch, jump,
					output logic [1:0] aluop);
					
logic [8:0] controls;

//combine all the output signals into a single variable.
assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, aluop, jump} = controls;

//this is the main lookup table of the instructions.
//outputs correspond to the different control signals for the processor itself.
always_comb
	case(op)
		6'b000000 : controls <= 9'b110000100; //rtype
		6'b100011 : controls <= 9'b101001000; // lw
		6'b101011 : controls <= 9'b001010000; //sw
		6'b000100 : controls <= 9'b000100010;//beq
		6'b001000 : controls <= 9'b101000000;//addi
		6'b000010 : controls <= 9'b000000011;//j
	default: controls <= 9'bxxxxxxxxx; //illegal op
	endcase

endmodule
