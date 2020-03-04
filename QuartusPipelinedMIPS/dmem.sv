module dmem(input logic clk, we,
				 input logic [31:0] a, wd,
				 output logic [31:0] rd);

logic [31:0] ram [63:0]; //make it, for now, 64 words deep.

assign rd = ram[a[31:2]]; // word aligned

always_ff @(posedge clk)
	if (we) ram[a[31:2]] <= wd;

//initialize it.
//only for debugging purposes.
initial $readmemh("dmem_init_increasing.dat", ram);
	
endmodule
