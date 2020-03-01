module dmem(input logic clk, we,
				 input logic [31:0] a, wd,
				 output logic [31:0] rd);

logic [31:0] RAM [63:0]; //Make it, for now, 64 words deep.

assign rd = RAM[a[31:2]]; // word aligned

always_ff @(posedge clk)
	if (we) RAM[a[31:2]] <= wd;

//initialize it.
//ONLY FOR DEBUGGING PURPOSES.
initial $readmemh("dmem_init_increasing.dat", RAM);
	
endmodule