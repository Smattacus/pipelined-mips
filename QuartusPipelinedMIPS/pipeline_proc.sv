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
	
	
		always_ff @(posedge clk, posedge reset)
			if (reset) pcf <= 0;
			else if (~stallf) pcf <= bj_resultf; 
	

		//mux the signal according to branch or jump.
		mux3 #(32) bj_mux3(pcsrcd, pcplus4f, pcbranchd, pcjumpd, bj_resultf);
	
		//imemory is external.
//		imem instr_mem(clk, pcf, instrf);
		
		//create the normal pc step: mips memory is word aligned,
		//so increment by 4 bytes.
		//the memory address in my memory are 32 bits each, so bump up by one to get each instruction.
		assign pcplus4f = pcf + 4;
		
		
	// decode (d)

		assign pcsrcd[0] = branchd & (rd1d_muxed == rd2d_muxed);
		assign pcsrcd[1] = jumpd;
	
		//asynch reset FF with synch clear / enable for pipelining.
		//datapath ffs:
		assign d_ff_rst = reset | (|pcsrcd); //Todo: verify this one liner does actually do (a OR (b[1]OR b[2]))
		
		always_ff @(posedge clk, posedge d_ff_rst)
			if (d_ff_rst) begin
				//Data signals
				instrd <= 0;
				pcplus4d <= 0;
			end
			else if (~stalld) begin
				//Data signals
				instrd <= instrf;
				pcplus4d <= pcplus4f;
			end
		
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
		assign pcjumpd[31:0] = {pcplus4d[31:28], instrd[25:0], 2'b00};
		
		//assign rsd, rtd, rdd from instrd.
		assign rsd = instrd[25:21];
		assign rtd = instrd[20:16];
		assign rdd = instrd[15:11];
		
		
	//execute (e)

		//Execute Stage FF with asynch reset and synch clear.
		always_ff @(posedge clk, posedge reset)
		if (reset) begin
			rd1e <= 0;
			rd2e <= 0;
			rse <= 0;
			rte <= 0;
			rde <= 0;
			signimme <= 0;
			//Control signals
			regwritee <= 0;
			memtorege <= 0;
			memwritee <= 0;
			alucontrole <= 0;
			alusrce <= 0;
			regdste <= 0;		
		end
		else if (flushe) begin //can I just write (reset | flushe) above and get rid of this?
			rd1e <= 0;
			rd2e <= 0;
			rse <= 0;
			rte <= 0;
			rde <= 0;
			signimme <= 0;
			//Control signals
			regwritee <= 0;
			memtorege <= 0;
			memwritee <= 0;
			alucontrole <= 0;
			alusrce <= 0;
			regdste <= 0;	
		end
		else begin
			rd1e <= rd1d;
			rd2e <= rd2d;
			rse <= rsd;
			rte <= rtd;
			rde <= rdd;
			signimme <= signimmd;
			//Control signals
			regwritee <= regwrited;
			memtorege <= memtoregd;
			memwritee <= memwrited;
			alucontrole <= alucontrold;
			alusrce <= alusrcd;
			regdste <= regdstd;
		end
		
		
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

		//Memory FF from Execute stage. Asynch reset.
		always_ff @(posedge clk, posedge reset)
		if (reset) begin
			//Data signals.
			aluoutm <= 0;
			writedatam <= 0;
			writeregm <= 0;
			//Control Signals.
			regwritem <= 0;
			memtoregm <= 0;
			memwritem <= 0;
		end
		else begin
			//Data signals
			aluoutm <= aluoute;
			writedatam <= writedatae;
			writeregm <= writerege;
			//Control Signals
			regwritem <= regwritee;
			memtoregm <= memtorege;
			memwritem <= memwritee;
			
		end
		

		
		//data memory is external -- commented out.
//		dmem data_mem(clk, memwritem, aluoutm, writedatam, readdatam);
		
		
	//Writeback (w)

		always_ff @(posedge clk, posedge reset)
		if (reset) begin
			readdataw <= 0;
			aluoutw <= 0;
			writeregw <= 0;
			//Control Signals
			regwritew <= 0;
			memtoregw <= 0;
		end
		else begin
			readdataw <= readdatam;
			aluoutw <= aluoutm;
			writeregw <= writeregm;
			//Control Signals
			regwritew <= regwritem;
			memtoregw <= memtoregm;
		end
		
		mux2 #(32) mux2_w_alu_readdataw(aluoutw, readdataw, memtoregw, resultw);

endmodule
