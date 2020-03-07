module addi_testbench();

	//this testbench should run with an adjusted instruction memfile 
	//with a single instruction in it.
	//memfile_addi.dat
	//implements the mips binary for: addi
	//mips assembly: addi $3, $0, 5 #set $2 = 5. 
	//machine code: 20020005
	
	logic clk, reset;
	logic [31:0] writedata, dataadr;
	logic memwrite;
	logic [31:0] clock_count;
	
	//instantiate mips processor.
	mips dut(clk, reset, writedata, dataadr, memwrite);
	
	//reset to start out.
	initial
		begin
			clock_count = 0;
			reset <= 1; #22; reset <= 0;
		end
	
	//clock.
	always begin
		clk <= 1; #5; clk <= 0; #5;
	end
	
	//for now, just stop the simulation after 25 clock cycles.
	always @(posedge clk)
	begin
		if (clock_count === 25) begin
			$display("simulation done!");
			$stop;
		end
		else
			clock_count++;
	end
	

endmodule
