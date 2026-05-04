close_project -quiet
file delete -force sim_proj.xpr *.os *.jou *.log sim_proj.srcs sim_proj.cache sim_proj.runs sim_proj.sim pcie_7x_0.gen/ pcie_7x_0.cache/

create_project -part xc7a100tfgg484-2 -force sim_proj
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# Add PCIe IP
add_files ../source/pcie_7x_0.xci
update_ip_catalog

# Generate PCIe example design to get access to the PCIe root port VIP
reset_target all [get_ips pcie_7x_0]
generate_target {simulation example} [get_ips pcie_7x_0]

# Add design sources
add_files ../source/spram.v
add_files ../source/ila.sv
add_files ../source/top.sv

# Add VIP files for simulation
add_files -fileset sim_1 ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/dsport/pcie_2_1_rport_7x.v
add_files -fileset sim_1 ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/dsport/xilinx_pcie_2_1_rport_7x.v
add_files -fileset sim_1 ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/dsport/pci_exp_usrapp_cfg.v
add_files -fileset sim_1 ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/dsport/pci_exp_usrapp_com.v
add_files -fileset sim_1 ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/dsport/pci_exp_usrapp_pl.v
add_files -fileset sim_1 ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/dsport/pci_exp_usrapp_rx.v
add_files -fileset sim_1 ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/dsport/pci_exp_usrapp_tx.v
add_files -fileset sim_1 ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/dsport/pcie_axi_trn_bridge.v
add_files -fileset sim_1 ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/functional/sys_clk_gen.v
add_files -fileset sim_1 ../source/pcie_7x_0.gen/sources_1/ip/pcie_7x_0/simulation/functional/sys_clk_gen_ds.v
add_files -fileset sim_1 tb.sv

set_property top board [get_filesets sim_1]
update_compile_order -fileset sim_1

# Disable VIP default test
set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg TESTNAME=none} -objects [get_filesets sim_1]

close_project
