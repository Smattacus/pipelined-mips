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
	logic d_ff_rst;
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
		//00 -> pcplus4f; 01 -> pcbranchd; 10 -> pcjumpd
		assign bj_resultf = pcsrcd[1] ?  pcjumpd : (pcsrcd[0] ? pcbranchd : pcplus4f);
	
		//imemory is external.
//		imem instr_mem(clk, pcf, instrf);
		
		//create the normal pc step: mips memory is word aligned,
		//so increment by 4 bytes.
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
					  
		//RF read word output muxes
		//todo: adjust s signal to be from hazard unit.
		assign rd1d_muxed = 1'b0 ? aluoutm : rd1d;
		assign rd2d_muxed = 1'b0 ? aluoutm : rd2d;
				
		//sign immediate extension.
		assign signimmd[31:0] = {{16{instrd[15]}}, instrd[15:0]};
		
		//ls by two and add
		assign pcbranchd = {signimmd[29:0], 2'b00} + pcplus4d;
		
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
		assign writerege = regdste ? rde : rte;
		
		//00 -> rd1e; 01 -> resultw; 1x -> aluoutm;
		assign srcae = forwardae[1] ? aluoutm : (forwardae[0] ? resultw : rd1e);
		
		//00 -> rd2e; 01 -> result2; 1x -> aluoutm;
		assign writedatae = forwardbe[1] ? aluoutm : (forwardbe[0] ? resultw : rd2e);
		
		//0 -> signimme; 1 -> alusrce
		assign srcbe = alusrce ? signimme : writedatae;
		
		//alu unit
		//leave "cout" and "zero" disconnected for now.
		alu_32bit alu(.a(srcae), .b(srcbe), .f(alucontrole), .y(aluoute), .cout(), .zero());
		
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
		
		//0 -> aluoutw; 1 -> readdataw
		assign resultw = memtoregw ? aluoutw : readdataw;

endmodule
