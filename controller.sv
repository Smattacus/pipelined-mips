module controller(input logic 	[5:0] Opcode, Funct,
						input logic 			zero,
						output logic 	RegWrite, MemtoReg,
						output logic 	Memwrite,
						output logic 	ALUSrc, RegDst, Branch, Jump,
						output logic 	[2:0] alucontrol);
	//Note we've removed the pipeline suffixes. This controller
	//can also work for a single cycle MIPS processor.
						
	logic [1:0] aluop;
	logic branch;
	
	maindec md(Opcode, RegWrite, MemtoReg, MemWrite, ALUSrc,
					RegDst, Branch, Jump, aluop);
		
	aludec ad(funct, aluop, alucontrol);
						
	assign pcscr = branch & zero;
endmodule