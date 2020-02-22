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


Design verification is the current focus.
