
interface instr_d_if(input [4:0] rd_d, rs_d_o, rt_d_o);
   
   //For now, this is just a dummy interface. It instantiates
   //inside dut.proc and automatically connects its inputs to
   //rd_d, rs_d_o, and rt_d_o. 

endinterface


module internal_testbench();

    //Try setting this up to learn bind to internal DUT signals.
    logic clk, reset, memwrite;
    logic [31:0] writedata, dataadr, clock_count;
    logic [4:0] rd_d_bound; 
    logic [4:0] rs_d_o_bound; 
    logic [4:0] rt_d_o_bound;

    assign rd_d_o_bound = dut.proc.rd_d;
    assign rs_d_o_bound = dut.proc.rs_d_o;
    assign rt_d_o_bound = dut.proc.rt_d_o;

    mips dut(.clk_i(clk), .reset_i(reset),
        .writedata_o(writedata),
        .dataadr_o(dataadr),
        .memwrite_o(memwrite));

    //Bind instantiation is here.
//    bind dut.proc instr_d_if rd_connect(.*);

    initial
        begin
            clock_count = 0;
        
        #5; reset <= 1; #22; reset <= 0;
        end

    //Clock
    always begin
        clk <= 1; #5; clk <= 0; #5;
    end

    //Check the simulation when it writes to data memory.
    always @(posedge clk)
    begin
       
        if (memwrite) begin 
            if (dataadr === 84 & writedata ===7) begin
                $display("simulation succeeded!");
                $stop;
            end else if (dataadr !== 80) begin
                $display("simulation failed!");
                $stop;
            end
        end
        clock_count++;
    end


endmodule
