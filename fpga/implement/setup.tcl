close_project -quiet
file delete -force proj.xpr *.os *.jou *.log proj.srcs proj.cache proj.runs pcie_7x_0.gen/ pcie_7x_0.cache/

create_project -part xc7a100tfgg484-2 -force proj
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]
load_features ipintegrator

add_files ../source/pcie_7x_0.xci
update_ip_catalog

reset_target all [get_ips pcie_7x_0]
generate_target {instantiation_template synthesis} [get_ips pcie_7x_0]

add_files ../source/spram.v
add_files ../source/ila.sv
add_files ../source/top.sv

add_files -fileset constrs_1 ../source/top.xdc

set_property used_in_synthesis true  [get_files */synth/pcie_7x_0.v]

update_compile_order -fileset sources_1

close_project
