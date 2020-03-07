module dmem(input logic clk_i, we_i,
                 input logic [31:0] a_i, wd_i,
                 output logic [31:0] rd_o);

logic [31:0] ram [63:0]; //make it, for now, 64 words deep.

assign rd_o = ram[a_i[31:2]]; // word aligned

always_ff @(posedge clk_i)
    if (we_i) ram[a_i[31:2]] <= wd_i;

//initialize it.
//only for debugging purposes.
initial $readmemh("dmem_init_increasing.dat", ram);
    
endmodule
