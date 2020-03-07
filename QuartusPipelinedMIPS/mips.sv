module mips(input logic clk_i, reset_i,
              output logic [31:0] writedata_o, dataadr_o,
              output logic       memwrite_o);
    
    //Signals to and from the MIPS and memories.    
    logic           branch_d, jump_d, rfdst_d, alusrc_d, memwrite_d;
    logic           memtorf_d, rfwrite_d, memwrite_m;
    logic [2:0]     alucontrol_d;
    logic [31:0]    pc_f, instr_f, instr_d, aluout_m, writedata_m, readdata_m;
    
    //hazard signals to / from the processor.
    logic           memtorf_e, rfwrite_e, memtorf_m, rfwrite_m, rfwrite_w;
    logic           stall_f, stall_d, forwardad, forwardbd, flush_e;
    logic [1:0]     forwardae, forwardbe;
    logic [4:0]     rs_d, rt_d, rs_e, rt_e, writerf_e, writerf_m, writerf_w;
    
    //pipelined processor.
    pipeline_proc proc(.clk_i(clk_i), .reset_i(reset_i), .enable_i(1'b1), 
        .instr_d_o(instr_d),
        .rfwrite_d_i(rfwrite_d), 
        .memtorf_d_i(memtorf_d), 
        .memwrite_d_i(memwrite_d), 
        .alucontrol_d_i(alucontrol_d), 
        .alusrc_d_i(alusrc_d), 
        .regdst_d_i(rfdst_d), 
        .branch_d_i(branch_d), 
        .jump_d_i(jump_d),
        .pc_f_o(pc_f), 
        .instr_f_i(instr_f), 
        .aluout_m_o(aluout_m), 
        .writedata_m_o(writedata_m), 
        .memwrite_m_o(memwrite_m), 
        .readdata_m_o(readdata_m),
        .stall_f_i(stall_f), 
        .stall_d_i(stall_d), 
        .forwardad_i(forwardad), 
        .forwardbd_i(forwardbd), 
        .flush_e_i(flush_e), 
        .forwardae_i(forwardae), 
        .forwardbe_i(forwardbe),
        .memtorf_e_o(memtorf_e),
        .rfwrite_e_o(rfwrite_e),
        .memtorf_m_o(memtorf_m),
        .rfwrite_m_o(rfwrite_m),
        .rfwrite_w_o(rfwrite_w),
        .rs_d_o(rs_d),
        .rt_d_o(rt_d),
        .rs_e_o(rs_e),
        .rt_e_o(rt_e),
        .writerf_e_o(writerf_e),
        .writerf_m_o(writerf_m),
        .writerf_w_o(writerf_w));
        
    //Instruction memory.
    imem instructions(.clk_i(clk_i), 
        .a_i(pc_f[7:2]), 
        .rd_o(instr_f));
    
    //Data memory.
    dmem data_memory(.clk_i(clk_i), 
        .we_i(memwrite_m), 
        .a_i(aluout_m), 
        .wd_i(writedata_m), 
        .rd_o(readdata_m));

    //Hazard control unit.    
    hazard mips_hcu(.branch_d_i(branch_d),
        .jump_d_i(jump_d),
        .memtorf_e_i(memtorf_e),
        .rfwrite_e_i(rfwrite_e),
        .memtorf_m_i(memtorf_m),
        .rfwrite_m_i(rfwrite_m),
        .rfwrite_w_i(rfwrite_w),
        .rs_d_i(rs_d),
        .rt_d_i(rt_d),
        .rs_e_i(rs_e),
        .rt_e_i(rt_e),
        .writerf_e_i(writerf_e),
        .writerf_m_i(writerf_m),
        .writerf_w_i(writerf_w),
        .stall_f_o(stall_f),
        .stall_d_o(stall_d),
        .forwardad_o(forwardad),
        .forwardbd_o(forwardbd),
        .flush_e_o(flush_e),
        .forwardae_o(forwardae),
        .forwardbe_o(forwardbe));
    
    assign writedata_o = writedata_m;
    assign dataadr_o = aluout_m;
    assign memwrite_o = memwrite_m;
    
    //Controller unit.
    controller mips_controller(.opcode_i(instr_d[31:26]), 
        .funct_i(instr_d[5:0]), 
        .rfwrite_o(rfwrite_d), 
        .memtorf_o(memtorf_d), 
        .memwrite_o(memwrite_d), 
        .alusrc_o(alusrc_d), 
        .rfdst_o(rfdst_d), 
        .branch_o(branch_d), 
        .jump_o(jump_d), 
        .alucontrol_o(alucontrol_d));
    
endmodule
