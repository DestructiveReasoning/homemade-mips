proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
    add wave -position end sim:/if_stage_tb/clock
    add wave -position end sim:/if_stage_tb/new_addr
    add wave -position end sim:/if_stage_tb/pc_en
    add wave -position end sim:/if_stage_tb/q_new_addr
    add wave -position end sim:/if_stage_tb/q_instr
    add wave -position end sim:/if_stage_tb/finished
}

vlib work

;# compile components
vcom if_stage.vhd
vcom if_stage_tb.vhd
vcom memory.vhd

;# Start simulation
vsim if_stage_tb

;# Generate a clock with 1ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 100ns
run 100ns