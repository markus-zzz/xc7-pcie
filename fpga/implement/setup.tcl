close_project -quiet
file delete -force proj.xpr *.os *.jou *.log proj.srcs proj.cache proj.runs

create_project -part xc7a100tfgg484-2 -force proj
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]
load_features ipintegrator

source ../source/system.tcl

read_verilog -sv ../source/top.sv
read_verilog -sv ../source/ila.sv
read_verilog     ../source/spram.v

read_xdc ../source/top.xdc

close_project
