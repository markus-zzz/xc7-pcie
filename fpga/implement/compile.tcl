close_project -quiet

open_project proj.xpr

update_compile_order -fileset sources_1
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

#
# Deal with non-standard lane ordering https://github.com/hdlguy/litefury_pcie/blob/main/x4_pcie/implement/compile.tcl
#
open_run synth_1

puts "PACKAGE_PINs before remap"
foreach port [get_ports] {
  set package_pin [get_property PACKAGE_PIN [get_ports $port]]
  puts "$package_pin\t$port"
}
reset_property LOC [get_cells {u_system/pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
reset_property LOC [get_cells {u_system/pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
reset_property LOC [get_cells {u_system/pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
reset_property LOC [get_cells {u_system/pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]

set_property LOC GTPE2_CHANNEL_X0Y7 [get_cells {u_system/pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property LOC GTPE2_CHANNEL_X0Y6 [get_cells {u_system/pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property LOC GTPE2_CHANNEL_X0Y5 [get_cells {u_system/pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property LOC GTPE2_CHANNEL_X0Y4 [get_cells {u_system/pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]

puts "PACKAGE_PINs after remap"
foreach port [get_ports] {
  set package_pin [get_property PACKAGE_PIN [get_ports $port]]
  puts "$package_pin\t$port"
}

launch_runs impl_1 -jobs 8
wait_on_run impl_1

set resdir ./results
file mkdir $resdir

open_run impl_1
report_timing_summary   -file $resdir/timing.rpt
report_utilization      -file $resdir/utilization.rpt
report_io               -file $resdir/io.rpt

set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN Div-1 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

write_bitstream -verbose -force $resdir/top.bit

close_project
