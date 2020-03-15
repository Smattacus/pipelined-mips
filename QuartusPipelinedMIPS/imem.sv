module imem(input logic clk_i,
                input logic [5:0] a_i,
                output logic [31:0] rd_o);

    logic [31:0] ram [17:0]; //again, a 64 word memory of 32 bits per word.
                
    initial
      $readmemh("memfile.dat", ram);
//      $readmemh("memfile_addi.dat", ram);
    
    assign rd_o = ram[a_i];
                
endmodule
