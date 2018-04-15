proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
  add wave -position end sim:/testbench/cpu/*
  add wave -position end sim:/testbench/cpu/decode/reg/*
  add wave -position end sim:/testbench/cpu/decode/*
  add wave -position end sim:/testbench/cpu/fetch/*
  add wave -position end sim:/testbench/*
  add wave -position end sim:/testbench/cpu/fetch/instr_mem/*
}                                           

vlib work

;# Compile components
vcom testbench.vhd
vcom alu.vhd
vcom alufunct_encoder.vhd
vcom cpu_tb.vhd
vcom id_stage.vhd
vcom if_stage.vhd
vcom mem_stage.vhd
vcom pipe_reg.vhd
vcom registerfile.vhd
vcom memory.vhd
vcom cache.vhd

;# Start simulation
vsim testbench

;# Generate a clock with 1ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 100ns
run 100 ns

