module pipeline_proc(input  logic 			clk, reset, enable,
							//output to external controller
							output logic [31:0] 	InstrD, 
							//controller inputs
							input logic 			RegWriteD, MemtoRegD, 
							input logic 			MemWriteD, 
							input logic [2:0] 	ALUControlD,
							input logic 			ALUSrcD, 
							input logic 			RegDstD,
							input logic 			BranchD,
							input logic 			JumpD,
							//output to instr mem
							output logic [31:0] 	PCF, 
							//instruction input
							input logic [31:0] 	InstrF, 
							//Output to data mem
							output logic [31:0] 	ALUOutM, WriteDataM, 
							output logic 			MemWriteM,
							//word read from data mem
							input logic [31:0] 	ReadDataM, 
							//Hazard Inputs.
							input logic 			StallF, StallD,
							input logic 			ForwardAD, ForwardBD,
							input logic 			FlushE,
							input logic [1:0] 	ForwardAE, ForwardBE,
							//Define hazard outputs here.
							//Six one bit signals:
							//{MemtoRegE, RegWriteE, MemtoRegM, RegWriteM, RegWriteW}
							//Note branchD comes from the controller to the HCU.
							output logic [4:0]	hazard_singles,
							//{rsD, rtD, rsE, rtE, WriteRegE, WriteReg, WriteRegW}
							//Each of these is 5 bits.
							output logic [34:0] 	hazard_mults);
							
					 
	//This is the pipelined processor.
	//The memories and controller are external,
	//so we have to send data in / out to them.
	//The controller inputs come in at the "decode" stage.
	
	//Sections:
	//1. Signal definitions.
	//2. Module definitions.
	
	//Signal list - grouped by fetch, decode, execute, memory, writeback.
	logic [31:0] PC;

	//Fetch (F):

	logic [31:0] bj_ResultF;
	logic [31:0] PCPlus4F;
	
	
	//Decode (D) suffix

	//Datapath:
	logic [31:0] RD1D, RD1D_muxed;
	logic [31:0] RD2D, RD2D_muxed;
	logic [31:0] SignImmD, SignImmDls2;
	logic [31:0] PCPlus4D;
	logic [31:0] PCBranchD;
	logic [31:0] PCJumpD;
	logic EqualD;
	logic [4:0] RsD, RtD, RdD;

	//Controller signals:
	logic [1:0] PCSrcD;
	
	//Execute (E) Suffix:
	
	//Datapath:
	logic [31:0] RD1E; 
	logic [31:0] RD2E;
	logic [4:0] RsE;
	logic [4:0] RtE;
	logic [4:0] RdE;
	logic [4:0] WriteRegE;
	logic [31:0] SrcAE; 
	logic [31:0] SrcBE;
	logic [31:0] WriteDataE;
	logic [31:0] SignImmE;
	logic [31:0] AluOutE;
	
	//Controller
	logic RegWriteE;
	logic MemtoRegE;
	logic MemWriteE;
	logic [2:0] ALUControlE;
	logic ALUSrcE;
	logic RegDstE;
	
	//Memory stage (M)
	//Datapath
	logic [4:0] WriteRegM;
	
	//Controller
	logic RegWriteM;
	logic MemtoRegM;
	
	//Writeback Stage (W)
	//Datapath
	logic [31:0] ReadDataW;
	logic [31:0] ALUOutW;
	logic [4:0] WriteRegW;
	logic [31:0] ResultW;
	
	//Controller
	logic RegWriteW;
	logic MemtoRegW;
	
	//Set up bus signals to go to / from the HCU.
	
	assign hazard_singles = {MemtoRegE, RegWriteE, MemtoRegM, RegWriteM, RegWriteW};
	assign hazard_mults = {RsD, RtD, RsE, RtE, WriteRegE, WriteRegM, WriteRegW};
		
	//Organize this into the pipelined sections.
	//From left to right:
	
	//Fetch (F)
	
		//Mux the signal according to branch or jump.
		mux3 #(32) bj_mux3({PCSrcD, JumpD}, PCPlus4D, PCBranchD, PCJumpD, bj_ResultF);
	
		//FF with synchronous clear.
		//TODO: Convert to enable for pipelined.
		floprc #(32) pcreg(clk, reset, StallF, bj_ResultF, PCF);
	
		//imemory IS EXTERNAL.
//		imem instr_mem(clk, PCF, InstrF);
		
		//Create the normal PC step: MIPS memory is word aligned,
		//so increment by 4 bytes.
		assign PCPlus4F = PCF + 4;
		
		
	// Decode (D)

		assign PCSrcD[0] = BranchD & (RD1D_muxed == RD2D_muxed);
		assign PCSrcD[1] = JumpD;
	
		//TODO: Convert to clear / enable for pipelined.
		floprce #(32) Dreg_inst(clk, reset, StallD, |PCSrcD, InstrF, InstrD);
		floprce #(32) Dreg_pcpl(clk, reset, StallD, |PCSrcD, PCPlus4F, PCPlus4D);
		
		//Register file
		regfile rf(clk, reset, 
					  RegWriteW,
					  InstrD[25:21],
					  InstrD[20:16],
					  WriteRegW,
					  ResultW,
					  RD1D,
					  RD2D);
					  
		//RF rd output muxes
		//TODO: Adjust s signal to be from hazard unit.
		mux2 #(32) rd1_mux2(RD1D, ALUOutM, 1'b0, RD1D_muxed);
		mux2 #(32) rd2_mux2(RD2D, ALUOutM, 1'b0, RD2D_muxed);
				
		//Sign Immediate extension.
		signext signext_imm(InstrD[15:0], SignImmD);
		
		ls2 ls2_SignExtImm(SignImmD, SignImmDls2);
		
		adder add_PC_SignImmExt(SignImmDls2, PCPlus4D, PCBranchD);
		
		//Calculate JTA for jump instructions.
		assign PCJumpD = {PCPlus4D[31:28], InstrD[25:0], 2'b00};
		
		//TODO: Controller signals pipelining.
		//Note: the controller inputs are already in the D stage.
		
		
	//Execute (E)
	
		//TODO: Convert to hazard enabled FFs.
		flopre #(32) flopr_E_RD1D(clk, reset, FlushE, RD1D_muxed, RD1E);
		flopre #(32) flopr_E_RD2D(clk, reset, FlushE, RD2D_muxed, RD2E);
		
		flopre #(5) flopr_rsE(clk, reset, FlushE, RsD, RsE);
		flopre #(5) flopr_rtE(clk, reset, FlushE, RtD, RtE);
		flopre #(5) flopr_rdE(clk, reset, FlushE, RdD, RdE);
		
		flopre #(32) flopr_SignImmE(clk, reset, FlushE, SignImmD, SignImmE);
		
		//Rt vs Rd mux.
		mux2 #(5) mux2_Rt_Rs(RtE, RdE, RegDstE, WriteRegE);
		
		//Muxes for hazard control. Set to always pass the RD1, RD2 values for now.
		//TODO: update with control signals and FF for hazards.
		mux3 #(32) mux3_RD1_ResultW_ALUOutM(2'b00, RD1E, ResultW, ALUOutM, SrcAE);
		mux3 #(32) mux3_RD2_ResultW_ALUOutM(2'b00, RD2E, ResultW, ALUOutM, SrcBE);
		
		//ALU unit
		//Leave "cout" and "zero" disconnected for now.
		alu_32bit alu(SrcAE, SrcBE, ALUControlE, ALUOutE, , );
		
		//TODO: Controller signals pipelining.
		
	// Memory (M)
		
		//TODO: convert to hazard enabled FFs.
		flopr #(32) flopr_M_ALUOut(clk, reset, ALUOutE, ALUOutM);
		flopr #(32) flopr_M_WriteDataM(clk, reset, WriteDataE, WriteDataM);
		flopr #(32) flopr_M_WriteReg(clk, reset, WriteRegE, WriteRegM);
		
		//Data memory is external -- commented out.
//		dmem data_mem(clk, MemWriteM, ALUOutM, WriteDataM, ReadDataM);
	
		//TODO: Controller signals pipelining.
		
		
	//Writeback (W)
		
		//TODO: Convert to hazard FFs.
		flopr #(32) flopr_W_readData(clk, reset, ReadDataM, ReadDataW);
		flopr #(32) flopr_W_ALUOut(clk, reset, ALUOutM, ALUOutW);
		
		mux2 #(32) mux2_W_ALU_ReadDataW(ALUOutW, ReadDataW, MemtoRegW, ResultW);
	
		
		//TODO: Controller signals pipelining.

endmodule