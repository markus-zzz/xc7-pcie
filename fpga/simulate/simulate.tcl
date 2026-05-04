close_project -quiet

open_project sim_proj.xpr

# Add include paths for VIP
set_property include_dirs [list \
  ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/functional \
  ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/tests \
] [get_filesets sim_1]

update_compile_order -fileset sim_1

# Launch simulation in batch mode
launch_simulation -mode behavioral

# Run simulation
run all

# Close
close_sim -force
close_project
