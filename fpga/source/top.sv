`default_nettype none

module top (
  input  wire       sysclk_p,
  input  wire       sysclk_n,
  input  wire       pcie_clkin_clk_p, pcie_clkin_clk_n,
  input  wire[3:0]  pcie_mgt_rxn, pcie_mgt_rxp,
  output logic[3:0] pcie_mgt_txn, pcie_mgt_txp,
  input  wire       pcie_reset,
  output logic      pcie_clkreq_l,
  output logic[3:0] ledn
);

  assign pcie_clkreq_l = 1'b0; // Always request clock
  assign ledn = 4'b0101;

  logic clk;
  IBUFDS #(.DIFF_TERM("TRUE"), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("DEFAULT")) u_ibufds (.O(clk), .I(sysclk_p), .IB(sysclk_n));

  //
  // System
  //
  system u_system(
    .pcie_clkin_clk_n (pcie_clkin_clk_n),
    .pcie_clkin_clk_p (pcie_clkin_clk_p),
    .pcie_mgt_rxn     (pcie_mgt_rxn),
    .pcie_mgt_rxp     (pcie_mgt_rxp),
    .pcie_mgt_txn     (pcie_mgt_txn),
    .pcie_mgt_txp     (pcie_mgt_txp),
    .pcie_reset       (pcie_reset)
  );

  logic [31:0] cntr;
  always_ff @(posedge clk) begin
    cntr <= cntr + 1;
  end

  ila u_ila(
    .clk(clk),
    .trigger_in(cntr == 32'h8000_0000),
    .sample_in(cntr)
  );

endmodule

