module addi_testbench();

	//This testbench should run with an adjusted instruction memfile 
	//with a single instruction in it.
	//memfile_r_add.dat
	//Implements the MIPS binary for: addi
	//MIPS assembly: addi $3, $0, 5 #set $2 = 5. 
	//machine code: 20020005
	
	logic clk, reset;
	logic [31:0] writedata, dataadr;
	logic memwrite;
	logic [31:0] clock_count;
	
	//Instantiate MIPS processor.
	top dut(clk, reset, writedata, dataadr, memwrite);
	
	//Reset to start out.
	initial
		begin
			clock_count = 0;
			reset <= 1; #22; reset <= 0;
		end
	
	//Clock.
	always begin
		clk <= 1; #5; clk <= 0; #5;
	end
	
	//For now, just stop the simulation after 25 clock cycles.
	always @(posedge clk)
	begin
		if (clock_count === 25) begin
			$display("Simulation done!");
			$stop;
		end
		else
			clock_count++;
	end
	

endmodule