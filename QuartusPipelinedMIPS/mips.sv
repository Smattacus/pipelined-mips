module mips(input logic clk, reset,
			  output logic [31:0] writedata, dataadr,
			  output logic 		 memwrite);
		
		//instantiate mips processor and memories (data memory and program mem)
		
		logic zero;
		
		logic [31:0] pcf, instrf, instrd, aluoutm, writedatam, readdatam;
		logic [2:0] alucontrold;
		logic branchd, jumpd, regdstd, alusrcd, memwrited, memtoregd, regwrited;
		logic memwritem;
		
		//hazard signals to / from the processor.
		logic 			stallf, stalld, forwardad, forwardbd, flushe;
		logic [1:0]		forwardae, forwardbe;
		//hazard_singles = {memtorege, regwritee, memtoregm, regwritem, regwritew}
		logic [4:0] 	hazard_single_bus;
		//hazard_mults = {rsd, rtd, rse, rte, writerege, writeregm, writeregw}
		logic [34:0] 	hazard_mult_bus;
		
		//pipelined processor.
		pipeline_proc proc(clk, reset, 1'b1, instrd,
			regwrited, memtoregd, memwrited, alucontrold, alusrcd, regdstd, branchd, jumpd,
			pcf, instrf, aluoutm, writedatam, memwritem, readdatam,
			stallf, stalld, forwardad, forwardbd, flushe, forwardae, forwardbe,
			hazard_single_bus,
			hazard_mult_bus);
			
		imem instructions(clk, pcf[7:2], instrf);
		
		dmem data_memory(clk, memwritem, aluoutm, writedatam, readdatam);
		
		//todo: create the hazard control unit here.
		hazard mips_hcu(stallf, stalld, forwardad, forwardbd, flushe, forwardae, forwardbe,
			branchd, jumpd, hazard_single_bus, hazard_mult_bus);
		
		assign writedata = writedatam;
		assign dataadr = aluoutm;
		assign memwrite = memwritem;
		
		//controller unit.
		controller mips_controller(instrd[31:26], instrd[5:0], regwrited, memtoregd, 
			memwrited, alusrcd, regdstd, branchd, jumpd, alucontrold);
		
		
		
endmodule
