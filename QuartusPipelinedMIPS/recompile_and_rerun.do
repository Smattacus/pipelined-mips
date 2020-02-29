#Run the Altera generated .do file.
do top_run_msim_rtl_verilog.do

#Add waves of interest on the top level.
add wave -position insertpoint -radix hex \
sim:/addi_testbench/dut/instructions/a \
sim:/addi_testbench/dut/instructions/rd \

#Add waves for the Fetch pipeline stage.

add wave -position insertpoint -radix hex \
sim:/addi_testbench/dut/proc/InstrF

#Add waves for the Decode pipeline stage.

add wave -position insertpoint -radix hex \
sim:/addi_testbench/dut/proc/InstrD


#Add waves for the Execute pipeline stage.

add wave -position insertpoint -radix dec \
sim:/addi_testbench/dut/proc/SignImmE

add wave -position insertpoint sim:/addi_testbench/dut/proc/mux2_RD2_toALU/*

#ALU Inputs
add wave -position insertpoint -radix dec \
sim:/addi_testbench/dut/proc/SrcAE \
sim:/addi_testbench/dut/proc/SrcBE

#Add waves for the Memory pipeline stage.
add wave -position insertpoint -radix dec \
sim:/addi_testbench/dut/proc/ALUOutM \
sim:/addi_testbench/dut/proc/ALUOutW \
sim:/addi_testbench/dut/proc/ALUOutE 

add wave -position insertpoint -radix dec \
sim:/addi_testbench/dut/proc/ResultW

#Add waves for the Writeback pipeline stage.



#Restart and run again with the new waves
restart -force
run