module imem(input logic clk,
				input logic [5:0] a,
				output logic [31:0] rd);

	logic [31:0] ram [17:0]; //again, a 64 word memory of 32 bits per word.
				
	initial
//		$readmemh("memfile.dat", ram);
		$readmemh("memfile_addi.dat", ram);
	
	assign rd = ram[a];
				
endmodule
