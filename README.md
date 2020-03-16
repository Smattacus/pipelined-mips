# pipelined-mips
Pipelined MIPS processor based on Harris &amp; Harris Digital Design and Computer Architecture, 2nd Ed.

This processor has external data memory, instruction memory, and hazard unit. The file "MIPS Top Level IOs.png" gives the basic structure of the processor and IOs to memories and the hazard unit. The file "Pipelined MIPS Datapath.png" contains the datapath of the processor itself. The processor is pipelined into five stages: fetch, decode, execute, memory, and writeback. These stages are set apart with flip flops with various capabilities depending on hazard unit requirements.

Currently supported instructions:
  - RTYPE instructions          (000000)
  - Load word (lw)              (100011)
  - Store word (sw)             (101011)
  - Branch when equal to (beq)  (000100)
  - add immediate (addi)        (001000)
  - jump (j)                    (000010)

Hazard Unit support:
  - Data forwarding from memory or writeback stage to execute stage when detected to address certain RAW hazards.
  - Stalls for RAW hazards with specific instruction. lw for example.
  - Branch prediction: The design assumes that the branches are not taken and has clear enabled FFs to flush invalidated data when a branch is taken. This does result in a branch misprediction penalty. RAW hazards introduced by this design choice are also addressed in the hazard unit.

This processor is synthesizable.

This processor works for the following program, which exercises all the available instructions and makes sure to encounter RAW hazards, branch prediction, and RAW hazards within branch prediction. It exercises stalls and flushes to reconfigure the pipeline status.

|Instruction    |     Assembly      |      Description     |      Hazard Considerations |
|---------------|-------------------|----------------------|----------------------------|
|main:   20020005  |  addi $2, $0, 5  |    #$2 = 5          | None                       |
|        2003000c  |  addi $3, $0, 12  |   #$3 = 12         |     None                   |
|       2067fff7  |  addi $7, $3, -9  |   #$7 = 3           |  RAW. Data forwarded.     |
|        00e22025 |   or $4, $7, $2   |    #$4 = 7          |  RAW. Data forwarded.     |
|       00642824  |  and $5, $3, $4   |   #$5 = 4           |   RAW. Forwarded.          |
|       00a42820  |  add $5, $5, $4   |   #$5 = 11          |    RAW. Forwarded.         |
|       10a7000a  |  beq $5, $7, end  |   #Should NOT be taken. | Branch hazard. Stall for data from $5.       |
|       0064202a  |  slt $4, $3, $4   |   #$4 = 0           |      None.                 |
|       10800001  |  beq $4, $0, around | #Taken.           |  Branch hazard. Stall for $4, flush when taken.|
|       20050000  |  addi $5, $0, $0  |   #Shouldn't happen.|  Flushed.                  |
| around: 00e2202a |  slt $4, $7, $2  |    #$4 = 1          |  None.                     |
|       00853820  |  add $7, $4, $5   |   #$7 = 12          |  RAW. Forwarded.           |
|      00e23822  |  sub $7, $7, $2   |   #$7 = 7            |  RAW.                     |
|      ac670044  |  sw $7, 68($3)   |    #\[80\] = 7        |  Stall for $7.              |
|       8c020050 |   lw $2, 80($0)   |    #$2 = \[80\] = 7   | RAW. Forwarded.           |
|       08000011 |   j end           |    # Taken.          |  Stalled to get address.   |
|       20020001 |   addi $2, $0, 1   |   # Skipped.        |  Instruction read but flushed.  |
|end:    ac020054 |   sw $2, 84($0)   |    # write \[84\] = 7 |  None.                          |
