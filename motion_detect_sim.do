setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# compile 
vlog -work work "motion_detect_top.sv"
vlog -work work "fifo.sv"
vlog -work work "subtract.sv"
vlog -work work "highlight.sv"
vlog -work work "grayscale.sv"
vlog -work work "motion_detect_tb.sv"

# run simulation
vsim -classdebug -voptargs=+acc +notimingchecks -L work work.motion_detect_tb -wlf motion_detect.wlf

# wave
add wave -noupdate -group motion_detect_tb
add wave -noupdate -group motion_detect_tb -radix hexadecimal /motion_detect_tb/*
add wave -noupdate -group motion_detect_tb/dut
add wave -noupdate -group motion_detect_tb/dut -radix hexadecimal /motion_detect_tb/dut/*
run -all