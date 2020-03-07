module alu_32bit(input logic [31:0] a, b, 
                      input logic [2:0] f,
                      output logic [31:0] y,
                      output logic cout,
                      output logic zero);
            
    //alu with the following operations (listed by control signal f:)
    //000   - a and b
    //001 - a or b
    //010 - a + b
    //011 - not used
    //100 - a and bbar
    //101 - a or bbar
    //110 - a - b
    //111 - slt ( sign less than; a < b).
    
    always_comb
        case(f)
            3'b000  :   y <= a & b;
            3'b001  :   y <= a | b;
            3'b010  :   y = a + b;
            3'b011  :   y <= 0; //Drive to zero on this input for now.
            3'b100  :   y <= a & ~b;
            3'b101  :   y <= a | ~b;
            3'b110  :   y <= a - b;
            3'b111  :   y <= a < b;
            default     :   y <= 0;
        endcase

    assign zero = (y == 0);
    logic [31:0] dummy;
    assign {cout, dummy} = a + b; //Obvious problem: there is an extra adder now.
    //I want this to be in the always_comb with {y, cout} = a + b;, but I am getting
    //an error that it's inferring non combinational logic. This is my workaround until I figure it out.
    

endmodule
