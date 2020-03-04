module controller(input logic 	[5:0] opcode, funct,
						output logic 	regwrite, memtoreg,
						output logic 	memwrite,
						output logic 	alusrc, regdst, branch, jump,
						output logic 	[2:0] alucontrol);
	//note we've removed the pipeline suffixes. this controller
	//can also work for a single cycle mips processor.
						
	logic [1:0] aluop;
	
	maindec md(opcode, regwrite, memtoreg, memwrite, alusrc,
					regdst, branch, jump, aluop);
		
	aludec ad(funct, aluop, alucontrol);
						
endmodule
