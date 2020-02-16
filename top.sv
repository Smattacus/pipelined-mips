module top(input logic clk, reset,
			  output logic [31:0] writedata, dataadr,
			  output logic 		 memwrite);
		
		//Instantiate mips processor and memories (data memory and program mem)
		
		logic zero;
		
		logic [31:0] PCF, InstrF, InstrD, ALUOutM, WriteDataM, ReadDataM;
		logic [2:0] ALUControlD;
		logic BranchD, JumpD, RegDstD, ALUSrcD, MemWriteD, MemtoRegD, RegWriteD;
		logic MemWriteM;
		
		//Hazard signals to / from the processor.
		logic 			StallF, StallD, ForwardAD, ForwardBD, FlushE;
		logic [1:0]		ForwardAE, ForwardBE;
		//hazard_singles = {MemtoRegE, RegWriteE, MemtoRegM, RegWriteM, RegWriteW}
		logic [5:0] 	hazard_single_bus;
		//hazard_mults = {rsD, rtD, rsE, rtE, WriteRegE, WriteRegM, WriteRegW}
		logic [34:0] 	hazard_mult_bus;
		
		//Pipelined processor.
		pipeline_proc proc(clk, reset, 1'b1, InstrD,
			RegWriteD, MemtoRegD, MemWriteD, ALUControlD, ALUSrcD, RegDstD, BranchD, JumpD,
			PCF, InstrF, ALUOutM, WriteDataM, MemWriteM, ReadDataM,
			StallF, StallD, ForwardAD, ForwardBD, FlushE, ForwardAE, ForwardBE,
			hazard_single_bus,
			hazard_mult_bus);
			
		imem instructions(clk, PCF, InstrF);
		
		dmem data_memory(clk, MemWriteM, ALUOutM, WriteDataM, ReadDataM);
		
		//TODO: Create the hazard control unit here.
		hazard mips_hcu(StallF, StallD, ForwardAD, ForwardBD, FlushE, ForwardAE, ForwardBE,
			BranchD, JumpD, hazard_single_bus, hazard_mult_bus);
		
		assign writedata = WriteDataM;
		assign dataadr = ALUOutM;
		assign memwrite = MemWriteM;
		
		//Controller unit.
		controller mips_controller(InstrD[31:26], InstrD[5:0], zero, RegWriteD, MemtoRegD, 
			MemWriteD, ALUSrcD, RegDstD, BranchD, JumpD, ALUControlD);
		
		
		
endmodule