#Recompile the sv code files and set up environment.
do top_run_msim_rtl_verilog.do


#Add waves for the hcu signals into the proc

#Stall signals. Binary.
add wave -position insertpoint  \
sim:/internal_testbench/dut/proc/stall_d_i \
sim:/internal_testbench/dut/proc/stall_f_i

#Forward signals and flush signals. Binary since max is 2 bits.
add wave -position insertpoint  \
sim:/internal_testbench/dut/proc/flush_e_i \
sim:/internal_testbench/dut/proc/forwardad_i \
sim:/internal_testbench/dut/proc/forwardae_i \
sim:/internal_testbench/dut/proc/forwardbd_i \
sim:/internal_testbench/dut/proc/forwardbe_i

#Add waves for the processor itself.

#Result line going to WE3 on the RF.
add wave -radix dec -position insertpoint  \
sim:/internal_testbench/dut/proc/result_w

#Instruction when it's fetched (thus input to proc module).
add wave -radix hex -position insertpoint  \
sim:/internal_testbench/dut/proc/instr_d_o \
sim:/internal_testbench/dut/proc/instr_f_i

#todo: add a block for branch and jump logic signals.
add wave -position insertpoint  \
sim:/internal_testbench/dut/proc/pcsrc_d

add wave -radix hex -position insertpoint  \
sim:/internal_testbench/dut/proc/rd1muxed_d \
sim:/internal_testbench/dut/proc/rd2muxed_d

add wave -radix hex -position insertpoint  \
sim:/internal_testbench/dut/proc/pcsrc_d \

add wave -radix dec -position insertpoint  \
sim:/internal_testbench/dut/proc/aluout_m_o \
sim:/internal_testbench/dut/proc/writedata_m_o \
sim:/internal_testbench/dut/proc/writerf_w_o

add wave -radix hex -position insertpoint \
sim:/internal_testbench/dut/proc/readdata_m_o

#These are the branch, jump, and regular addresses for the instruction
#memory.
add wave -radix hex -position insertpoint  \
sim:/internal_testbench/dut/proc/bj_result_f \
sim:/internal_testbench/dut/proc/pcbranch_d \
sim:/internal_testbench/dut/proc/pcjump_d \
sim:/internal_testbench/dut/proc/pcplus4_f

#Instruction memory address that is read.
add wave -radix hex -position insertpoint  \
sim:/internal_testbench/dut/proc/pc_f_o

#Rerun the simulationw with the new waves.
restart -force;
run -all;
