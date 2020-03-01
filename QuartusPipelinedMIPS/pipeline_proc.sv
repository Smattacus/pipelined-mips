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
	logic [7:0] ControlDtoE, ControlEfromD;
	
	//Execute (E) Suffix:
	
	//Datapath:
	logic [31:0] RD1E; 
	logic [31:0] RD2E;
	logic [4:0] RsE;
	logic [4:0] RtE;
	logic [4:0] RdE;
	logic [4:0] WriteRegE;
	logic [31:0] SrcAE; 
	logic [31:0] SrcBE, SrcBE_pre;
	logic [31:0] WriteDataE;
	logic [31:0] SignImmE;
	logic [31:0] ALUOutE;
	
	//Controller
	logic RegWriteE;
	logic MemtoRegE;
	logic MemWriteE;
	logic [2:0] ALUControlE;
	logic ALUSrcE;
	logic RegDstE;
	
	logic [2:0] ControlMfromE, ControlEtoM;
	
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
		mux3 #(32) bj_mux3({PCSrcD, JumpD}, PCPlus4F, PCBranchD, PCJumpD, bj_ResultF);
	
	
		//FF with synchronous clear.
		//TODO: Convert to enable for pipelined.
		flopre #(32) pcreg(clk, reset, ~StallF, bj_ResultF, PCF);
	
		//imemory IS EXTERNAL.
//		imem instr_mem(clk, PCF, InstrF);
		
		//Create the normal PC step: MIPS memory is word aligned,
		//so increment by 4 bytes.
		//The memory address in my memory are 32 bits each, so bump up by one to get each instruction.
		assign PCPlus4F = PCF + 32'b100;
		
		
	// Decode (D)

		assign PCSrcD[0] = BranchD & (RD1D_muxed == RD2D_muxed);
		assign PCSrcD[1] = JumpD;
	
		//Asynch reset FFs with synch clear / enable for pipelining.
		//Datapath FFs:
		floprce #(32) Dreg_inst_FD(clk, reset, PCSrcD[0] | PCSrcD[1], ~StallD, InstrF, InstrD);
		floprce #(32) Dreg_pcpl_FD(clk, reset, PCSrcD[0] | PCSrcD[1], ~StallD, PCPlus4F, PCPlus4D);
		
		
		//Register file
		regfile rf(~clk, reset, 
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
		
		//Assign RsD, RtD, RdD from InstrD.
		assign RsD = InstrD[25:21];
		assign RtD = InstrD[20:16];
		assign RdD = InstrD[15:11];
		
		
	//Execute (E)
	
		//Data path FFs.
		
		//todo: correct input -> rd1, not the muxed signal!
		floprc #(32) flopr_DE_RD1D(clk, reset, FlushE, RD1D, RD1E);
		floprc #(32) flopr_DE_RD2D(clk, reset, FlushE, RD2D, RD2E);
		
		floprc #(5) flopr_rs_DE(clk, reset, FlushE, RsD, RsE);
		floprc #(5) flopr_rt_DE(clk, reset, FlushE, RtD, RtE);
		floprc #(5) flopr_rd_DE(clk, reset, FlushE, RdD, RdE);
		
		floprc #(32) flopr_SignImm_DE(clk, reset, FlushE, SignImmD, SignImmE);
		

		
		
		//Rt vs Rd mux.
		mux2 #(5) mux2_Rt_Rs(RtE, RdE, RegDstE, WriteRegE);
		
		//Muxes for hazard control. Set to always pass the RD1, RD2 values for now.
		//TODO: update with control signals and FF for hazards.
		mux3 #(32) mux3_RD1_ResultW_ALUOutM(ForwardAE, RD1E, ResultW, ALUOutM, SrcAE);
		mux3 #(32) mux3_RD2_ResultW_ALUOutM(ForwardBE, RD2E, ResultW, ALUOutM, WriteDataE);
		
		mux2 #(32) mux2_RD2_toALU(WriteDataE, SignImmE, ALUSrcE, SrcBE);
		
		//ALU unit
		//Leave "cout" and "zero" disconnected for now.
		alu_32bit alu(SrcAE, SrcBE, ALUControlE, ALUOutE, , );
		
		//TODO: Controller signals pipelining.
		
	// Memory (M)
		
		//No need for pipelining chunks here.
		flopr #(32) flopr_EM_ALUOut(clk, reset, ALUOutE, ALUOutM);
		flopr #(32) flopr_EM_WriteDataM(clk, reset, WriteDataE, WriteDataM);
		flopr #(32) flopr_EM_WriteReg(clk, reset, WriteRegE, WriteRegM);
		
		//Set up control pipeline signals.

		
		//Data memory is external -- commented out.
//		dmem data_mem(clk, MemWriteM, ALUOutM, WriteDataM, ReadDataM);
		
		
	//Writeback (W)
		
		//Pipeline register. No HCU inputs necessary here.
		flopr #(32) flopr_MW_readData(clk, reset, ReadDataM, ReadDataW);
		flopr #(32) flopr_MW_ALUOut(clk, reset, ALUOutM, ALUOutW);
		flopr #(32) flopr_MW_WriteReg(clk, reset, WriteRegM, WriteRegW);
		
		
		mux2 #(32) mux2_W_ALU_ReadDataW(ALUOutW, ReadDataW, MemtoRegW, ResultW);

	//CONTROL SIGNALS PIPELINING.
	
	//D to E pipeline register.
	//Controller FFs:
	//Define the input / output FF bus:
	assign ControlDtoE = {RegWriteD, MemtoRegD, MemWriteD, ALUControlD, ALUSrcD, RegDstD};
	assign {RegWriteE, MemtoRegE, MemWriteE, ALUControlE, ALUSrcE, RegDstE} = ControlEfromD;
	floprc #(8) floprc_ctrl_DE(clk, reset, FlushE, ControlDtoE, ControlEfromD);	
//	floprc #(1) floprc_ctrl_DE_rgwd(clk, reset, FlushE, RegWriteD, RegWriteE);
	
	//E to M pipeline register.
	assign ControlEtoM = {RegWriteE, MemtoRegE, MemWriteE};
	assign {RegWriteM, MemtoRegM, MemWriteM} = ControlMfromE;
	//Control FF.
	flopr #(3) flopr_ctrl_EM(clk, reset, ControlEtoM, ControlMfromE);
	
	//M to W pipeline register.
	//Control FF.
	flopr #(2) flopr_ctrl_MW(clk, reset, {RegWriteM, MemtoRegM}, {RegWriteW, MemtoRegW});

		
		
endmodule