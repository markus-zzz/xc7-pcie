create_clock -period  5.000 -name sysclk_p         -waveform {0.000 2.500} [get_ports {sysclk_p}]
create_clock -period 10.000 -name pcie_clkin_clk_p -waveform {0.000 5.000} [get_ports {pcie_clkin_clk_p}]

set_property IOSTANDARD LVDS_25     [get_ports sysclk_*]
set_property PACKAGE_PIN J19        [get_ports sysclk_p]
set_property PACKAGE_PIN H19        [get_ports sysclk_n]

set_property PACKAGE_PIN F6     [get_ports pcie_clkin_clk_p]
set_property PACKAGE_PIN E6     [get_ports pcie_clkin_clk_n]
set_property PACKAGE_PIN G1         [get_ports pcie_clkreq_l]
set_property IOSTANDARD LVCMOS33    [get_ports pcie_clkreq_l]
set_property PACKAGE_PIN J1         [get_ports pcie_reset]
set_property IOSTANDARD LVCMOS33    [get_ports pcie_reset]

set_property IOSTANDARD LVCMOS33 [get_ports {ledn[*]}]
set_property PACKAGE_PIN G3 [get_ports {ledn[0]}]
set_property PACKAGE_PIN H3 [get_ports {ledn[1]}]
set_property PACKAGE_PIN G4 [get_ports {ledn[2]}]
set_property PACKAGE_PIN H4 [get_ports {ledn[3]}]
