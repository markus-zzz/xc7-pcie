module top (
  input  logic      pcie_clkin_clk_p, pcie_clkin_clk_n,
  input  logic      pcie_reset,
  output logic      pcie_clkreq_l,
  output logic[3:0] ledn
);

  assign pcie_clkreq_l = 1'b0; // Always request clock
  assign ledn = 4'b0101;

  logic pcie_clkin, clk;
  IBUFDS_GTE2 #(
    .CLKCM_CFG("TRUE"),
    .CLKRCV_TRST("TRUE"),
    .CLKSWING_CFG(2'b11)
  ) u_ibufds_gte2 (
    .O(pcie_clkin),
    .ODIV2(),
    .CEB(1'b0),
    .I(pcie_clkin_clk_p),
    .IB(pcie_clkin_clk_n)
  );
  BUFG u_bufg (
    .O(clk),
    .I(pcie_clkin)
  );

  //
  // JTAG access
  //
  logic capture, drck, sel, shift, tdi, tdo;
  logic [31:0] sr;

  BSCANE2 #(
    .JTAG_CHAIN(1)
  ) u_bscane2_1 (
    .CAPTURE(capture),
    .DRCK(drck),
    .RESET(),
    .RUNTEST(),
    .SEL(sel),
    .SHIFT(shift),
    .TCK(),
    .TDI(tdi),
    .TMS(),
    .UPDATE(),
    .TDO(tdo)
  );

  assign tdo = sr[0];
  always_ff @(posedge drck) begin
    if (capture) sr <= 32'hcafebabe;
    else if (shift) sr <= {1'b0, sr[31:1]};
  end

endmodule

