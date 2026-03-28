Generate FPGA bitstream
=======================

```
$ source ~/tools/Xilinx/2025.2/Vivado/settings64.sh # Use correct PATH to your Vivado install
$ cd fpga/implement/
$ vivado -mode tcl
Vivado% source setup.tcl # Only required first time
Vivado% source compile.tcl
Vivado% quit
```

Use OpenOCD to program FPGA with bitstream
==========================================

```
openocd -f interface/altera-usb-blaster.cfg -f cpld/xilinx-xc7.cfg -c "adapter speed 1000; init; xc7_program xc7.tap; pld load 0 ./results/top.bit ; exit"
```

Test design with `BSCANE2` primitive to access JTAG chain from within FPGA fabric
=================================================================================

https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/BSCANE2

```
$ openocd -f interface/altera-usb-blaster.cfg -f cpld/xilinx-xc7.cfg
$ telnet localhost 4444
> set USER1 0x02
> set USER1_LEN 32
> irscan xc7.tap $USER1
> drscan xc7.tap $USER1_LEN 0
cafebabe
```

Linux PCIe commands
===================

```
$ export PCIE_RP=0000:00:1b.4
$ export PCIE_EP=0000:03:00.0
$ lspci -s ${PCIE_RP} -vvv
$ lspci -s ${PCIE_EP} -vvv
$ echo 1 | sudo tee /sys/bus/pci/devices/${PCIE_EP}/remove
$ sudo setpci -s ${PCIE_RP} CAP_EXP+0x10.B=0x50
# ---- Configure FPGA ----
$ sudo setpci -s ${PCIE_RP} CAP_EXP+0x10.B=0x40
$ echo 1 | sudo tee /sys/bus/pci/rescan
```

Documentation
=============

- 7 series PCIe controller - https://www.xilinx.com/support/documents/ip_documentation/pcie_7x/v3_3/pg054-7series-pcie.pdf

Credits
=======

- Build system and constraints based on example from - https://github.com/hdlguy/litefury_pcie
