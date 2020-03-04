module pipeline_proc(input  logic 			clk, reset, enable,
							//output to external controller
							output logic [31:0] 	instrd, 
							//controller inputs
							input logic 			regwrited, memtoregd, 
							input logic 			memwrited, 
							input logic [2:0] 	alucontrold,
							input logic 			alusrcd, 
							input logic 			regdstd,
							input logic 			branchd,
							input logic 			jumpd,
							//output to instr mem
							output logic [31:0] 	pcf, 
							//instruction input
							input logic [31:0] 	instrf, 
							//output to data mem
							output logic [31:0] 	aluoutm, writedatam, 
							output logic 			memwritem,
							//word read from data mem
							input logic [31:0] 	readdatam,
							//hazard inputs.
							input logic 			stallf, stalld,
							input logic 			forwardad, forwardbd,
							input logic 			flushe,
							input logic [1:0] 	forwardae, forwardbe,
							//define hazard outputs here.
							//six one bit signals:
							//{memtorege, regwritee, memtoregm, regwritem, regwritew}
							//note branchd comes from the controller to the hcu.
							output logic [4:0]	hazard_singles,
							//{rsd, rtd, rse, rte, writerege, writereg, writeregw}
							//each of these is 5 bits.
							output logic [34:0] 	hazard_mults);
							
					 
	//this is the pipelined processor.
	//the memories and controller are external,
	//so we have to send data in / out to them.
	//the controller inputs come in at the "decode" stage.
	
	//sections:
	//1. signal definitions.
	//2. module definitions.
	
	//signal list - grouped by fetch, decode, execute, memory, writeback.
	logic [31:0] pc;

	//fetch (f):

	logic [31:0] bj_resultf;
	logic [31:0] pcplus4f;
	
	
	//decode (d) suffix

	//datapath:
	logic [31:0] rd1d, rd1d_muxed;
	logic [31:0] rd2d, rd2d_muxed;
	logic [31:0] signimmd, signimmdls2;
	logic [31:0] pcplus4d;
	logic [31:0] pcbranchd;
	logic [31:0] pcjumpd;
	logic equald;
	logic [4:0] rsd, rtd, rdd;

	//controller signals:
	logic [1:0] pcsrcd;
	logic [7:0] controldtoe, controlefromd;
	
	//execute (e) suffix:
	
	//datapath:
	logic [31:0] rd1e; 
	logic [31:0] rd2e;
	logic [4:0] rse;
	logic [4:0] rte;
	logic [4:0] rde;
	logic [4:0] writerege;
	logic [31:0] srcae; 
	logic [31:0] srcbe, srcbe_pre;
	logic [31:0] writedatae;
	logic [31:0] signimme;
	logic [31:0] aluoute;
	
	//controller
	logic regwritee;
	logic memtorege;
	logic memwritee;
	logic [2:0] alucontrole;
	logic alusrce;
	logic regdste;
	
	logic [2:0] controlmfrome, controletom;
	
	//memory stage (m)
	//datapath
	logic [4:0] writeregm;
	
	//controller
	logic regwritem;
	logic memtoregm;
	
	//writeback stage (w)
	//datapath
	logic [31:0] readdataw;
	logic [31:0] aluoutw;
	logic [4:0] writeregw;
	logic [31:0] resultw;
	
	//controller
	logic regwritew;
	logic memtoregw;
	
	//set up bus signals to go to / from the hcu.
	
	assign hazard_singles = {memtorege, regwritee, memtoregm, regwritem, regwritew};
	assign hazard_mults = {rsd, rtd, rse, rte, writerege, writeregm, writeregw};
		
	//organize this into the pipelined sections.
	//from left to right:
	
	//fetch (f)
	
		//mux the signal according to branch or jump.
		mux3 #(32) bj_mux3({pcsrcd, jumpd}, pcplus4f, pcbranchd, pcjumpd, bj_resultf);
	
	
		//ff with synchronous clear.
		//todo: convert to enable for pipelined.
		flopre #(32) pcreg(clk, reset, ~stallf, bj_resultf, pcf);
	
		//imemory is external.
//		imem instr_mem(clk, pcf, instrf);
		
		//create the normal pc step: mips memory is word aligned,
		//so increment by 4 bytes.
		//the memory address in my memory are 32 bits each, so bump up by one to get each instruction.
		assign pcplus4f = pcf + 32'b100;
		
		
	// decode (d)

		assign pcsrcd[0] = branchd & (rd1d_muxed == rd2d_muxed);
		assign pcsrcd[1] = jumpd;
	
		//asynch reset ffs with synch clear / enable for pipelining.
		//datapath ffs:
		floprce #(32) dreg_inst_fd(clk, reset, pcsrcd[0] | pcsrcd[1], ~stalld, instrf, instrd);
		floprce #(32) dreg_pcpl_fd(clk, reset, pcsrcd[0] | pcsrcd[1], ~stalld, pcplus4f, pcplus4d);
		
		
		//register file
		regfile rf(~clk, reset, 
					  regwritew,
					  instrd[25:21],
					  instrd[20:16],
					  writeregw,
					  resultw,
					  rd1d,
					  rd2d);
					  
		//rf rd output muxes
		//todo: adjust s signal to be from hazard unit.
		mux2 #(32) rd1_mux2(rd1d, aluoutm, 1'b0, rd1d_muxed);
		mux2 #(32) rd2_mux2(rd2d, aluoutm, 1'b0, rd2d_muxed);
				
		//sign immediate extension.
		signext signext_imm(instrd[15:0], signimmd);
		
		ls2 ls2_signextimm(signimmd, signimmdls2);
		
		adder add_pc_signimmext(signimmdls2, pcplus4d, pcbranchd);
		
		//calculate jta for jump instructions.
		assign pcjumpd = {pcplus4d[31:28], instrd[25:0], 2'b00};
		
		//assign rsd, rtd, rdd from instrd.
		assign rsd = instrd[25:21];
		assign rtd = instrd[20:16];
		assign rdd = instrd[15:11];
		
		
	//execute (e)
	
		//data path ffs.
		
		//todo: correct input -> rd1, not the muxed signal!
		floprc #(32) flopr_de_rd1d(clk, reset, flushe, rd1d, rd1e);
		floprc #(32) flopr_de_rd2d(clk, reset, flushe, rd2d, rd2e);
		
		floprc #(5) flopr_rs_de(clk, reset, flushe, rsd, rse);
		floprc #(5) flopr_rt_de(clk, reset, flushe, rtd, rte);
		floprc #(5) flopr_rd_de(clk, reset, flushe, rdd, rde);
		
		floprc #(32) flopr_signimm_de(clk, reset, flushe, signimmd, signimme);
		

		
		
		//rt vs rd mux.
		mux2 #(5) mux2_rt_rs(rte, rde, regdste, writerege);
		
		//muxes for hazard control. set to always pass the rd1, rd2 values for now.
		//todo: update with control signals and ff for hazards.
		mux3 #(32) mux3_rd1_resultw_aluoutm(forwardae, rd1e, resultw, aluoutm, srcae);
		mux3 #(32) mux3_rd2_resultw_aluoutm(forwardbe, rd2e, resultw, aluoutm, writedatae);
		
		mux2 #(32) mux2_rd2_toalu(writedatae, signimme, alusrce, srcbe);
		
		//alu unit
		//leave "cout" and "zero" disconnected for now.
		alu_32bit alu(srcae, srcbe, alucontrole, aluoute, , );
		
		//todo: controller signals pipelining.
		
	// memory (m)
		
		//no need for pipelining chunks here.
		flopr #(32) flopr_em_aluout(clk, reset, aluoute, aluoutm);
		flopr #(32) flopr_em_writedatam(clk, reset, writedatae, writedatam);
		flopr #(32) flopr_em_writereg(clk, reset, writerege, writeregm);
		
		//set up control pipeline signals.

		
		//data memory is external -- commented out.
//		dmem data_mem(clk, memwritem, aluoutm, writedatam, readdatam);
		
		
	//writeback (w)
		
		//pipeline register. no hcu inputs necessary here.
		flopr #(32) flopr_mw_readdata(clk, reset, readdatam, readdataw);
		flopr #(32) flopr_mw_aluout(clk, reset, aluoutm, aluoutw);
		flopr #(32) flopr_mw_writereg(clk, reset, writeregm, writeregw);
		
		
		mux2 #(32) mux2_w_alu_readdataw(aluoutw, readdataw, memtoregw, resultw);

	//control signals pipelining.
	
	//d to e pipeline register.
	//controller ffs:
	//define the input / output ff bus:
	assign controldtoe = {regwrited, memtoregd, memwrited, alucontrold, alusrcd, regdstd};
	assign {regwritee, memtorege, memwritee, alucontrole, alusrce, regdste} = controlefromd;
	floprc #(8) floprc_ctrl_de(clk, reset, flushe, controldtoe, controlefromd);	
//	floprc #(1) floprc_ctrl_de_rgwd(clk, reset, flushe, regwrited, regwritee);
	
	//e to m pipeline register.
	assign controletom = {regwritee, memtorege, memwritee};
	assign {regwritem, memtoregm, memwritem} = controlmfrome;
	//control ff.
	flopr #(3) flopr_ctrl_em(clk, reset, controletom, controlmfrome);
	
	//m to w pipeline register.
	//control ff.
	flopr #(2) flopr_ctrl_mw(clk, reset, {regwritem, memtoregm}, {regwritew, memtoregw});

		
		
endmodule
