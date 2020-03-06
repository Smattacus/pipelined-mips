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
		pipeline_proc proc(.clk_i(clk), .reset_i(reset), .enable_i(1'b1), 
			.instr_d_o(instrd),
			.rfwrite_d_i(regwrited), 
			.memtorf_d_i(memtoregd), 
            .memwrite_d_i(memwrited), 
            .alucontrol_d_i(alucontrold), 
            .alusrc_d_i(alusrcd), 
            .regdst_d_i(regdstd), 
            .branch_d_i(branchd), 
            .jump_d_i(jumpd),
			.pc_f_o(pcf), 
            .instr_f_i(instrf), 
            .aluout_m_o(aluoutm), 
            .writedata_m_o(writedatam), 
            .memwrite_m_o(memwritem), 
            .readdata_m_o(readdatam),
            .stall_f_i(stallf), 
            .stall_d_i(stalld), 
            .forwardad_i(forwardad), 
            .forwardbd_i(forwardbd), 
            .flush_e_i(flushe), 
            .forwardae_i(forwardae), 
            .forwardbe_i(forwardbe),
			.memtorf_e_o(hazard_single_bus[4]),
            .rfwrite_e_o(hazard_single_bus[3]),
            .memtorf_m_o(hazard_single_bus[2]),
            .rfwrite_m_o(hazard_single_bus[1]),
            .rfwrite_w_o(hazard_single_bus[0]),
            .rs_d_o(hazard_mult_bus[34:30]),
            .rt_d_o(hazard_mult_bus[29:25]),
            .rs_e_o(hazard_mult_bus[24:20]),
            .rt_e_o(hazard_mult_bus[19:15]),
            .writerf_e_o(hazard_mult_bus[14:10]),
            .writerf_m_o(hazard_mult_bus[9:5]),
            .writerf_w_o(hazard_mult_bus[4:0]));
			
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
