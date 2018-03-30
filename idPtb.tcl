proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
    add wave -position end sim:/id_tb/clock
    add wave -position end sim:/id_tb/rs
    add wave -position end sim:/id_tb/rt
    add wave -position end sim:/id_tb/rd
    add wave -position end sim:/id_tb/write_data
    add wave -position end sim:/id_tb/write_en
    add wave -position end sim:/id_tb/q_data_a
    add wave -position end sim:/id_tb/q_data_b
}

vlib work

;# compile components
vcom alufunct_encoder.vhd
vcom registerfile.vhd
vcom id_stage.vhd
vcom id_tb.vhd

;# Start simulation
vsim if_stage_tb

;# Generate a clock with 1ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 100ns
run 20ns
