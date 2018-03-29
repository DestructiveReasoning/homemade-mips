proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
  add wave -position end sim:/cpu_tb/clock
  add wave -position end sim:/cpu_tb/stall
  add wave -position end sim:/cpu_tb/if_instr_in
  add wave -position end sim:/cpu_tb/if_newpc_in
  add wave -position end sim:/cpu_tb/if_instr_out
  add wave -position end sim:/cpu_tb/if_newpc_out
  add wave -position end sim:/cpu_tb/the_new_addr
  add wave -position end sim:/cpu_tb/id_instr_in
  add wave -position end sim:/cpu_tb/id_newpc_in
  add wave -position end sim:/cpu_tb/id_instr_out
  add wave -position end sim:/cpu_tb/id_newpc_out
  add wave -position end sim:/cpu_tb/id_dataa_in
  add wave -position end sim:/cpu_tb/id_datab_in
  add wave -position end sim:/cpu_tb/id_dataa_out
  add wave -position end sim:/cpu_tb/id_datab_out
  add wave -position end sim:/cpu_tb/id_imm_in
  add wave -position end sim:/cpu_tb/id_imm_out
  add wave -position end sim:/cpu_tb/id_ctrlsigs_in
  add wave -position end sim:/cpu_tb/id_ctrlsigs_out
  add wave -position end sim:/cpu_tb/ex_instr_in
  add wave -position end sim:/cpu_tb/ex_instr_out
  add wave -position end sim:/cpu_tb/ex_newpc_out
  add wave -position end sim:/cpu_tb/ex_dataa_in
  add wave -position end sim:/cpu_tb/ex_datab_in
  add wave -position end sim:/cpu_tb/ex_dataa_out
  add wave -position end sim:/cpu_tb/ex_datab_out
  add wave -position end sim:/cpu_tb/ex_imm_out
  add wave -position end sim:/cpu_tb/ex_ctrlsigs_out
  add wave -position end sim:/cpu_tb/ex_alures
  add wave -position end sim:/cpu_tb/mem_instr_out
  add wave -position end sim:/cpu_tb/mem_newpc_out
  add wave -position end sim:/cpu_tb/mem_dataa_in
  add wave -position end sim:/cpu_tb/mem_datab_in
  add wave -position end sim:/cpu_tb/mem_dataa_out
  add wave -position end sim:/cpu_tb/mem_datab_out
  add wave -position end sim:/cpu_tb/mem_imm_out
  add wave -position end sim:/cpu_tb/mem_ctrlsigs_in
  add wave -position end sim:/cpu_tb/mem_ctrlsigs_out
  add wave -position end sim:/cpu_tb/wb_data
}                                           

vlib work

;# Compile components
vcom alu.vhd
vcom alu_tb.vhd
vcom alufunct_encoder.vhd
vcom cpu_tb.vhd
vcom id_stage.vhd
vcom if_stage.vhd
vcom mem_stage.vhd
vcom pipe_reg.vhd
vcom registerfile.vhd
vcom registerfile_tb.vhd

;# Start simulation
vsim cpu_tb

;# Generate a clock with 1ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 100ns
run 100ns

