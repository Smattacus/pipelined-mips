module hazard(input logic branch_d_i, jump_d_i, memtorf_e_i, rfwrite_e_i,
    input logic memtorf_m_i, rfwrite_m_i, rfwrite_w_i, 
    input logic [4:0] rs_d_i, rt_d_i, rs_e_i, rt_e_i, writerf_e_i, writerf_m_i, writerf_w_i,
    output logic stall_f_o, stall_d_o, forwardad_o, forwardbd_o, flush_e_o, 
    output logic [1:0] 	forwardae_o, forwardbe_o);

//add in hazard control logic here.
logic lwstall, branchstall;

always_comb 
begin
	//do the forwardae_o logic first - checks rs_e_i.
	if ((rs_e_i != 0) & (rs_e_i == writerf_m_i) & rfwrite_m_i) forwardae_o = 2'b10;
	else if ((rs_e_i != 0) & (rs_e_i == writerf_w_i) & rfwrite_w_i) forwardae_o = 2'b01;
	else	forwardae_o = 2'b00;
	//and the forwardbe_o logic - checks rt_e_i
	if ((rt_e_i != 0) & (rt_e_i == writerf_m_i) & rfwrite_m_i) forwardbe_o = 2'b10;
	else if ((rt_e_i != 0) & (rt_e_i == writerf_w_i) & rfwrite_w_i) forwardbe_o = 2'b01;
	else forwardbe_o = 2'b00;
end


assign forwardad_o = (rs_d_i != 0) & (rs_d_i == writerf_m_i) & rfwrite_m_i;
assign forwardbd_o = (rt_d_i != 0) & (rt_d_i == writerf_m_i) & rfwrite_m_i;

assign branchstall = (branch_d_i & rfwrite_e_i & ((writerf_e_i == rs_d_i)
    | (writerf_e_i == rt_d_i))) | (branch_d_i & memtorf_m_i & ((writerf_m_i == rs_d_i)
    | (writerf_m_i == rt_d_i)));
								
//lwstall for data hazards.
	//note we use the logical or(|), not the boolean or (^)
assign lwstall = ((rs_d_i == rt_e_i) | (rt_d_i == rt_e_i)) & memtorf_e_i;

//send the signal to everything else.
assign #1 stall_d_o = lwstall | branchstall | jump_d_i;
assign #1 flush_e_o = stall_d_o;
assign #1 stall_f_o = stall_d_o;
		


		
				  
endmodule
