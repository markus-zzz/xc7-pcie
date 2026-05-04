`timescale 1ns/1ns
`include "board_common.vh"

module board;

  localparam REF_CLK_HALF_CYCLE = 5000;

  logic sys_rst_n;
  logic ep_sys_clk_p;
  logic ep_sys_clk_n;
  logic rp_sys_clk;

  logic [0:0] ep_pci_exp_txn;
  logic [0:0] ep_pci_exp_txp;
  logic [0:0] rp_pci_exp_txn;
  logic [0:0] rp_pci_exp_txp;

  // Your design as endpoint
  top EP (
    .sysclk_p(ep_sys_clk_p),
    .sysclk_n(ep_sys_clk_n),
    .pcie_clkin_clk_p(ep_sys_clk_p),
    .pcie_clkin_clk_n(ep_sys_clk_n),
    .pcie_mgt_rxn(rp_pci_exp_txn),
    .pcie_mgt_rxp(rp_pci_exp_txp),
    .pcie_mgt_txn(ep_pci_exp_txn),
    .pcie_mgt_txp(ep_pci_exp_txp),
    .pcie_reset(sys_rst_n),
    .pcie_clkreq_l(),
    .ledn()
  );

  // Root Port VIP
  xilinx_pcie_2_1_rport_7x #(
    .REF_CLK_FREQ(0),
    .PL_FAST_TRAIN("TRUE"),
    .LINK_CAP_MAX_LINK_WIDTH(1),
    .DEVICE_ID(16'h7100),
    .LINK_CAP_MAX_LINK_SPEED(1),
    .LINK_CTRL2_TARGET_LINK_SPEED(4'h1),
    .DEV_CAP_MAX_PAYLOAD_SUPPORTED(2),
    .VC0_TX_LASTPACKET(29),
    .VC0_RX_RAM_LIMIT(13'h7FF),
    .VC0_CPL_INFINITE("TRUE"),
    .VC0_TOTAL_CREDITS_PD(437),
    .VC0_TOTAL_CREDITS_CD(461)
  ) RP (
    .sys_clk(rp_sys_clk),
    .sys_rst_n(sys_rst_n),
    .pci_exp_txn(rp_pci_exp_txn),
    .pci_exp_txp(rp_pci_exp_txp),
    .pci_exp_rxn(ep_pci_exp_txn),
    .pci_exp_rxp(ep_pci_exp_txp)
  );

  // Clock generation
  sys_clk_gen_ds #(.halfcycle(REF_CLK_HALF_CYCLE), .offset(0)) CLK_GEN_RP (.sys_clk_p(rp_sys_clk), .sys_clk_n());
  sys_clk_gen_ds #(.halfcycle(REF_CLK_HALF_CYCLE), .offset(0)) CLK_GEN_EP (.sys_clk_p(ep_sys_clk_p), .sys_clk_n(ep_sys_clk_n));

  logic [31:0] bar0_addr;

  // Reset and test sequence
  initial begin
    $dumpfile("pcie_sim.vcd");
    $dumpvars(0, EP);
    $dumpvars(0, RP);

    $display("[%t] : System Reset Asserted...", $realtime);
    sys_rst_n = 1'b0;

    repeat (500) @(posedge rp_sys_clk);

    $display("[%t] : System Reset De-asserted...", $realtime);
    sys_rst_n = 1'b1;

    // Wait for link up
    wait(EP.pcie_7x_0_i.inst.inst.user_lnk_up == 1'b1);
    $display("[%t] : PCIe Link Up!", $realtime);

    repeat (1000) @(posedge rp_sys_clk);

    // Now you can call VIP tasks
    $display("[%t] : Starting Enumeration", $realtime);

    // Read Device/Vendor ID
    RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_READ(8'h00, 12'h000, 4'hF);
    RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
    $display("Config Read VendorID: 0x%04x DeviceID: 0x%04x", RP.tx_usrapp.P_READ_DATA[15:0], RP.tx_usrapp.P_READ_DATA[31:16]);

    // Read BARs to determine size
    RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_WRITE(8'h02, 12'h010, 32'hFFFFFFFF, 4'hF); // Write all-ones
    RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_READ(8'h01, 12'h010, 4'hF); // BAR0
    RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
    $display("Probing BAR0 size: 0x%08x", ~{RP.tx_usrapp.P_READ_DATA[31:4], 4'h0} + 1);

    // Write BAR0 address
    bar0_addr = 32'h1000_0000;
    RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_WRITE(8'h02, 12'h010, bar0_addr, 4'hF);
    repeat (100) @(posedge rp_sys_clk);

    // Enable Memory Space and Bus Master
    RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_WRITE(8'h03, 12'h004, 32'h00000006, 4'h1); // Command register
    repeat (100) @(posedge rp_sys_clk);

    $display("[%t] : Enumeration Complete", $realtime);

    // Now memory transactions should work
    $display("[%t] : Sending Memory Write", $realtime);
    RP.tx_usrapp.DATA_STORE[0] = 8'hbe;
    RP.tx_usrapp.DATA_STORE[1] = 8'hba;
    RP.tx_usrapp.DATA_STORE[2] = 8'hfe;
    RP.tx_usrapp.DATA_STORE[3] = 8'hca;
    RP.tx_usrapp.TSK_TX_MEMORY_WRITE_32(8'h10, 3'h0, 10'h4, bar0_addr + 16'h1230, 4'hF, 4'hF, 1'b0);

    repeat (100) @(posedge rp_sys_clk);

    $display("[%t] : Sending Memory Read", $realtime);
    RP.tx_usrapp.TSK_TX_MEMORY_READ_32(8'h11, 3'h0, 10'h1, bar0_addr + 16'h2340, 4'hF, 4'hF);

    repeat (1000) @(posedge rp_sys_clk);

    $display("[%t] : Test Complete", $realtime);
    $finish;
  end
endmodule
