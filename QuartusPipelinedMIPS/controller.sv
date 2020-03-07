module controller(input logic 	[5:0] opcode_i, funct_i,
						output logic 	rfwrite_o, memtorf_o,
						output logic 	memwrite_o,
						output logic 	alusrc_o, rfdst_o, branch_o, jump_o,
						output logic 	[2:0] alucontrol_o);
	//note we've removed the pipeline suffixes. this controller
	//can also work for a single cycle mips processor.
						
	logic [1:0] aluop;
	logic [8:0] controls;
	assign {rfwrite_o, rfdst_o, alusrc_o, branch_o, memwrite_o, memtorf_o, aluop, jump_o} = controls;
	
	//this is the main lookup table of the instructions.
	//outputs correspond to the different control signals for the processor itself.
	always_comb begin
		//Control signals based on instruction type.
		case(opcode_i)
			6'b000000 : controls <= 9'b110000100; //rtype
			6'b100011 : controls <= 9'b101001000; // lw
			6'b101011 : controls <= 9'b001010000; //sw
			6'b000100 : controls <= 9'b000100010;//beq
			6'b001000 : controls <= 9'b101000000;//addi
			6'b000010 : controls <= 9'b000000011;//j
			default: controls <= 9'bxxxxxxxxx; //illegal op
		endcase
		//Further control for the ALU.
		case(aluop)
			2'b00 : alucontrol_o <= 3'b010; // add (for lw / sw addi)
			2'b01 : alucontrol_o <= 3'b110; // sub (for beq)
			default: case(funct_i) //r - type instructions
				6'b100000 : alucontrol_o <= 3'b010; //add 
				6'b100010 : alucontrol_o <= 3'b110; //sub
				6'b100100 : alucontrol_o <= 3'b000; //and
				6'b100101 : alucontrol_o <= 3'b001; // or
				6'b101010 : alucontrol_o <= 3'b111; // slt
				default   : alucontrol_o <= 3'bxxx; // undefined input.
			endcase
		endcase	
	end
						
endmodule
