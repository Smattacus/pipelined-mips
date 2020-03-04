module hazard(output logic 			stallf, stalld,
				  output logic 			forwardad, forwardbd, flushe,
				  output logic [1:0] 	forwardae, forwardbe,
				  input logic 			branchd,
				  input logic 			jumpd,
				  input logic [4:0]	hazard_single_bus,
				  input logic [34:0] hazard_mult_bus);
//hazard_singles = {memtorege, regwritee, memtoregm, regwritem, regwritew}
//hazard_mults = {rsd, rtd, rse, rte, writerege, writeregm, writeregw}

				  
				  
//add in hazard control logic here.
logic lwstall, branchstall;

//bus stop.
logic memtorege, regwritee, memtoregm, regwritem, regwritew;
logic [4:0] rsd, rtd, rse, rte, writerege, writeregm, writeregw;

assign {memtorege, regwritee, memtoregm, regwritem, regwritew} = hazard_single_bus;				  
assign {rsd, rtd, rse, rte, writerege, writeregm, writeregw} = hazard_mult_bus;


always_comb 
begin
	//do the forwardae logic first - checks rse.
	if ((rse != 0) & (rse == writeregm) & regwritem) forwardae = 2'b10;
	else if ((rse != 0) & (rse == writeregw) & regwritew) forwardae = 2'b01;
	else	forwardae = 2'b00;
	//and the forwardbe logic - checks rte
	if ((rte != 0) & (rte == writeregm) & regwritem) forwardbe = 2'b10;
	else if ((rte != 0) & (rte == writeregw) & regwritew) forwardbe = 2'b01;
	else forwardbe = 2'b00;
end


assign forwardad = (rsd != 0) & (rsd == writeregm) & regwritem;
assign forwardbd = (rtd != 0) & (rtd == writeregm) & regwritem;

assign branchstall = (branchd & regwritee & (writerege == rsd | writerege == rtd)) |
							(branchd & memtoregm & (writeregm == rsd | writeregm == rtd));
								
//lwstall for data hazards.
	//note we use the logical or(|), not the boolean or (^)
assign lwstall = ((rsd == rte) | (rtd == rte)) & memtorege;

//send the signal to everything else.
assign #1 stalld = lwstall | branchstall | jumpd;
assign #1 flushe = stalld;
assign #1 stallf = stalld;
		
		
				  
endmodule
