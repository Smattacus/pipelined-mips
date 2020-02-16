module imem(input logic clk,
				input logic [31:0] a,
				output logic [31:0] rd);

	logic [31:0] RAM [63:0]; //Again, a 64 word memory of 32 bits per word.
				
	initial
		$readmemh("memfile.dat", RAM);
	
	assign rd = RAM[a];
				
endmodule