module pipeline_proc(input logic clk_i, reset_i, enable_i, 
        //controller inputs
        input logic             rfwrite_d_i, memtorf_d_i,  memwrite_d_i, alusrc_d_i, 
        input logic             regdst_d_i,  branch_d_i, jump_d_i,
        input logic     [2:0]   alucontrol_d_i,
        //instruction input
        input logic     [31:0]  instr_f_i, 
        //word read from data mem
        input logic     [31:0]  readdata_m_o,
        //hazard inputs.
        input logic             stall_f_i, stall_d_i,
        input logic             forwardad_i, forwardbd_i,
        input logic             flush_e_i,
        input logic     [1:0]   forwardae_i, forwardbe_i,
        //output to external controller
        output logic    [31:0]  instr_d_o, 
        //output to instr mem
        output logic    [31:0]  pc_f_o, 
        //output to data mem
        output logic    [31:0]  aluout_m_o, writedata_m_o, 
        output logic            memwrite_m_o,
        //HAZARD OUTPUTS:
        output logic            memtorf_e_o, rfwrite_e_o, memtorf_m_o, rfwrite_m_o, rfwrite_w_o,
        output logic    [4:0]   rs_d_o, rt_d_o, rs_e_o, rt_e_o, writerf_e_o,
        output logic    [4:0]   writerf_m_o, writerf_w_o);
    
    //Internal signals have a suffix denoting the pipeline stage it originates in:
    //_f = fetch; _d = decode; _e = execute; _m = memory; _w = writeback
    
    //Fetch: Datapath signals
    logic [31:0] pc, bj_result_f, pcplus4_f;

    //Decode: Datapath signals
    logic [4:0] rd_d;
    logic [31:0] rd1_d, rd1muxed_d, rd2_d, rd2muxed_d, signimm_d, pcplus4_d;
    logic [31:0] pcbranch_d, pcjump_d;

    //Decode: Controller signals
    logic [1:0] pcsrc_d;
    
    //Execute: Datapath Signals
    logic [31:0] srca_e, srcb_e, writedata_e, signimm_e, aluout_e, rd1_e, rd2_e;
    logic [4:0] rd_e;
    
    //Execute: Controller Signals
    logic memwrite_e, alusrc_e, regdst_e;
    logic [2:0] alucontrol_e;
    
    //Writeback: Datapath signals
    logic [31:0] readdata_w, aluout_w, result_w;
    
    //Writeback: Controller Signals
    logic memtorf_w;
    
    //Fetch Pipeline Stage
    
    always_ff @(posedge clk_i, posedge reset_i)
        if (reset_i) pc_f_o <= 0;
        else if (~stall_f_i) pc_f_o <= bj_result_f; 
    

    //mux the signal according to branch or jump.
    //00 -> pcplus4_f; 01 -> pcbranch_d_i; 10 -> pcjump_d
    assign bj_result_f = pcsrc_d[1] ?  pcjump_d : (pcsrc_d[0] ? pcbranch_d : pcplus4_f);
    
    //create the normal pc step: mips memory is word aligned,
    //so increment by 4 bytes.
    assign pcplus4_f = pc_f_o + 4;
    
    //Decode Pipeline Stage

    
    //asynch reset_i FF with synch clear / enable_i for pipelining.
    //datapath ffs:
    //Todo: verify this one liner does actually do (a OR (b[1]OR b[2]))
    
    always_ff @(posedge clk_i, posedge reset_i)
        if (reset_i) begin
            //Data signals
            instr_d_o <= 0;
            pcplus4_d <= 0;
        end
        else if (|pcsrc_d) begin //TODO: Again, I want to merge this above. Make a testbench and toy module.
            instr_d_o <= 0;
            pcplus4_d <= 0;
        end
        else if (~stall_d_i) begin
            //Data signals
            instr_d_o <= instr_f_i;
            pcplus4_d <= pcplus4_f;
        end
    
    //register file
    regfile rf(.clk_i(~clk_i), .reset_i(reset_i), 
        .we3_i(rfwrite_w_o),
        .ra1_i(instr_d_o[25:21]),
        .ra2_i(instr_d_o[20:16]),
        .wa3_i(writerf_w_o),
        .wd3_i(result_w),
        .rd1_o(rd1_d),
        .rd2_o(rd2_d));
                              
    //RF read word output muxes
    //todo: adjust s signal to be from hazard unit.
    assign rd1muxed_d = forwardad_i ? aluout_m_o : rd1_d;
    assign rd2muxed_d = forwardbd_i ? aluout_m_o : rd2_d;
    
    //Calculate whether we are branching.    
    assign pcsrc_d[0] = branch_d_i & (rd1muxed_d == rd2muxed_d);
    assign pcsrc_d[1] = jump_d_i;

    //sign immediate extension.
    assign signimm_d[31:0] = {{16{instr_d_o[15]}}, instr_d_o[15:0]};
    
    //ls by two and add
    assign pcbranch_d = {signimm_d[29:0], 2'b00} + pcplus4_d;
    
    //calculate jta for jump instructions.
    assign pcjump_d[31:0] = {pcplus4_d[31:28], instr_d_o[25:0], 2'b00};
    
    //assign rs_d_o, rt_d_o, rd_d from instr_d_o.
    assign rs_d_o = instr_d_o[25:21];
    assign rt_d_o = instr_d_o[20:16];
    assign rd_d = instr_d_o[15:11];
    
    //Execute Pipeline stage

    //Execute Stage FF with asynch reset_i and synch clear.
    always_ff @(posedge clk_i, posedge reset_i)
    if (reset_i) begin
        //Data signals
        rd1_e <= 0;
        rd2_e <= 0;
        rs_e_o <= 0;
        rt_e_o <= 0;
        rd_e <= 0;
        signimm_e <= 0;
        //Control signals
        rfwrite_e_o <= 0;
        memtorf_e_o <= 0;
        memwrite_e <= 0;
        alucontrol_e <= 0;
        alusrc_e <= 0;
        regdst_e <= 0;          
    end
    else if (flush_e_i) begin //can I just write (reset_i | flush_e_i) above and get rid of this?
        //Data signals
        rd1_e <= 0;
        rd2_e <= 0;
        rs_e_o <= 0;
        rt_e_o <= 0;
        rd_e <= 0;
        signimm_e <= 0;
        //Control signals
        rfwrite_e_o <= 0;
        memtorf_e_o <= 0;
        memwrite_e <= 0;
        alucontrol_e <= 0;
        alusrc_e <= 0;
        regdst_e <= 0;  
    end
    else begin
        //Data signals
        rd1_e <= rd1_d;
        rd2_e <= rd2_d;
        rs_e_o <= rs_d_o;
        rt_e_o <= rt_d_o;
        rd_e <= rd_d;
        signimm_e <= signimm_d;
        //Control signals
        rfwrite_e_o <= rfwrite_d_i;
        memtorf_e_o <= memtorf_d_i;
        memwrite_e <= memwrite_d_i;
        alucontrol_e <= alucontrol_d_i;
        alusrc_e <= alusrc_d_i;
        regdst_e <= regdst_d_i;
    end
    
    
    //rt vs rd mux.
    assign writerf_e_o = regdst_e ? rd_e : rt_e_o;
    
    //00 -> rd1_e; 01 -> result_w; 1x -> aluout_m_o;
    assign srca_e = forwardae_i[1] ? aluout_m_o : (forwardae_i[0] ? result_w : rd1_e);
    
    //00 -> rd2_e; 01 -> result_w; 1x -> aluout_m_o;
    assign writedata_e = forwardbe_i[1] ? aluout_m_o : (forwardbe_i[0] ? result_w : rd2_e);
    
    //0 -> signimm_e; 1 -> alusrc_e
    assign srcb_e = alusrc_e ? signimm_e : writedata_e;
    
    //alu unit
    //leave "cout" and "zero" disconnected for now.
    alu_32bit alu(.a(srca_e), .b(srcb_e), .f(alucontrol_e), .y(aluout_e), .cout(), .zero());
    
    // Memory Pipeline Stage.

    //Memory FF from Execute stage. Asynch reset_i.
    always_ff @(posedge clk_i, posedge reset_i)
    if (reset_i) begin
        //Data signals.
        aluout_m_o <= 0;
        writedata_m_o <= 0;
        writerf_m_o <= 0;
        //Control Signals.
        rfwrite_m_o <= 0;
        memtorf_m_o <= 0;
        memwrite_m_o <= 0;
    end
    else begin
        //Data signals
        aluout_m_o <= aluout_e;
        writedata_m_o <= writedata_e;
        writerf_m_o <= writerf_e_o;
        //Control Signals
        rfwrite_m_o <= rfwrite_e_o;
        memtorf_m_o <= memtorf_e_o;
        memwrite_m_o <= memwrite_e;
            
    end
    
    //Writeback pipeline stage.

    always_ff @(posedge clk_i, posedge reset_i)
    if (reset_i) begin
        //Data signals
        readdata_w <= 0;
        aluout_w <= 0;
        writerf_w_o <= 0;
        //Control Signals
        rfwrite_w_o <= 0;
        memtorf_w <= 0;
    end
    else begin
        //Data Signals
        readdata_w <= readdata_m_o;
        aluout_w <= aluout_m_o;
        writerf_w_o <= writerf_m_o;
        //Control Signals
        rfwrite_w_o <= rfwrite_m_o;
        memtorf_w <= memtorf_m_o;
    end
    
    //0 -> aluout_w; 1 -> readdata_w
    assign result_w = memtorf_w ? readdata_w : aluout_w;
    

endmodule
