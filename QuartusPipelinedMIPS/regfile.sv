module regfile(input logic clk_i, reset_i,
						  input logic we3_i,
						  input logic [4:0] ra1_i, ra2_i, wa3_i,
						  input logic [31:0] wd3_i,
						  output logic [31:0] rd1_o, rd2_o);

	logic [31:0] rf[31:0];
	
	always_ff @(posedge clk_i) begin
		if (we3_i) rf[wa3_i] = wd3_i;
	end
		
	assign rd1_o = (ra1_i != 0) ? rf[ra1_i] : 0;
	assign rd2_o = (ra2_i != 0) ? rf[ra2_i] : 0;
						  
endmodule 
					
