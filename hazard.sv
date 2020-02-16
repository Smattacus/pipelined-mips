module hazard(output logic 			StallF, StallD,
				  output logic 			ForwardAD, ForwardBD, FlushE,
				  output logic [1:0] 	ForwardAE, ForwardBE,
				  input logic 			BranchD,
				  input logic 			JumpD,
				  input logic [5:0]	hazard_single_bus,
				  input logic [34:0] hazard_mult_bus);
//hazard_singles = {MemtoRegE, RegWriteE, MemtoRegM, RegWriteM, RegWriteW}
//hazard_mults = {rsD, rtD, rsE, rtE, WriteRegE, WriteRegM, WriteRegW}

				  
				  
//Add in hazard control logic here.
logic lwstall, branchstall;

//Bus stop.
logic MemtoRegE, RegWriteE, MemtoRegM, RegWriteM, RegWriteW;
logic [4:0] rsD, rtD, rsE, rtE, WriteRegE, WriteRegM, WriteRegW;

assign {MemtoRegE, RegWriteE, MemtoRegM, RegWriteM, RegWriteW} = hazard_single_bus;				  
assign {rsD, rtD, rsE, rtE, WriteRegE, WriteRegM, WriteRegW} = hazard_mult_bus;


always_comb 
begin
	//Do the forwardAE logic first - checks rsE.
	if ((rsE != 0) & (rsE == WriteRegM) & RegWriteM) ForwardAE = 2'b10;
	else if ((rsE != 0) & (rsE == WriteRegW) & RegWriteW) ForwardAE = 2'b01;
	else	ForwardAE = 2'b00;
	//And the forwardBE logic - checks rtE
	if ((rtE != 0) & (rtE == WriteRegM) & RegWriteM) ForwardBE = 2'b10;
	else if ((rtE != 0) & (rtE == WriteRegW) & RegWriteW) ForwardBE = 2'b01;
	else ForwardBE = 2'b00;
end


assign ForwardAD = (rsD != 0) & (rsD == WriteRegM) & RegWriteM;
assign ForwardBD = (rtD != 0) & (rtD == WriteRegM) & RegWriteM;

assign branchstall = (BranchD & RegWriteE & (WriteRegE == rsD | WriteRegE == rtD)) |
							(BranchD & MemtoRegM & (WriteRegM == rsD | WriteRegM == rtD));
								
//lwstall for data hazards.
	//Note we use the logical OR(|), not the boolean OR (^)
assign lwstall = ((rsD == rtE) | (rtD == rtE)) & MemtoRegE;

//Send the signal to everything else.
assign #1 StallD = lwstall | branchstall | JumpD;
assign #1 FlushE = StallD;
assign #1 StallF = StallD;
		
		
				  
endmodule