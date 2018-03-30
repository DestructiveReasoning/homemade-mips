proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
    add wave -position end sim:/id_tb/*
}

vlib work

;# compile components
vcom id_stage.vhd
vcom id_tb.vhd
vcom registerfile.vhd
vcom alufunct_encoder.vhd

;# Start simulation
vsim id_tb

;# Generate a clock with 1ns period
force -deposit clock 1 0 ns, 0 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 100ns
run 10ns
