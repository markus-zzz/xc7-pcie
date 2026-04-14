`default_nettype none

module top (
  input  wire       sysclk_p,
  input  wire       sysclk_n,
  input  wire       pcie_clkin_clk_p, pcie_clkin_clk_n,
  input  wire[0:0]  pcie_mgt_rxn, pcie_mgt_rxp,
  output logic[0:0] pcie_mgt_txn, pcie_mgt_txp,
  input  wire       pcie_reset,
  output logic      pcie_clkreq_l,
  output logic[3:0] ledn
);

  assign pcie_clkreq_l = 1'b0; // Always request clock
  assign ledn = ~pl_ltssm_state[3:0];


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

  IBUFDS #(.DIFF_TERM("TRUE"), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("DEFAULT")) u_ibufds (.O(clk), .I(sysclk_p), .IB(sysclk_n));

  //
  // System
  //

  logic user_clk_out;
  logic user_reset_out;
  logic [5:0]pl_ltssm_state;

pcie_7x_0 pcie_7x_0_i
(
  .pci_exp_txp(pcie_mgt_txp),                // output wire [0 : 0] pci_exp_txp
  .pci_exp_txn(pcie_mgt_txn),                // output wire [0 : 0] pci_exp_txn
  .pci_exp_rxp(pcie_mgt_rxp),                // input wire [0 : 0] pci_exp_rxp
  .pci_exp_rxn(pcie_mgt_rxn),                // input wire [0 : 0] pci_exp_rxn
  .user_clk_out(),                           // output wire user_clk_out
  .user_reset_out(),                         // output wire user_reset_out
  .user_lnk_up(),                            // output wire user_lnk_up
  .user_app_rdy(),                           // output wire user_app_rdy
  .s_axis_tx_tready(),                       // output wire s_axis_tx_tready
  .s_axis_tx_tdata(0),                       // input wire [63 : 0] s_axis_tx_tdata
  .s_axis_tx_tkeep(0),                       // input wire [7 : 0] s_axis_tx_tkeep
  .s_axis_tx_tlast(0),                       // input wire s_axis_tx_tlast
  .s_axis_tx_tvalid(0),                      // input wire s_axis_tx_tvalid
  .s_axis_tx_tuser(0),                       // input wire [3 : 0] s_axis_tx_tuser
  .m_axis_rx_tdata(),                        // output wire [63 : 0] m_axis_rx_tdata
  .m_axis_rx_tkeep(),                        // output wire [7 : 0] m_axis_rx_tkeep
  .m_axis_rx_tlast(),                        // output wire m_axis_rx_tlast
  .m_axis_rx_tvalid(),                       // output wire m_axis_rx_tvalid
  .m_axis_rx_tready(1'b1),                   // input wire m_axis_rx_tready
  .m_axis_rx_tuser(),                        // output wire [21 : 0] m_axis_rx_tuser
  .cfg_interrupt(0),                         // input wire cfg_interrupt
  .cfg_interrupt_rdy(),                      // output wire cfg_interrupt_rdy
  .cfg_interrupt_assert(0),                  // input wire cfg_interrupt_assert
  .cfg_interrupt_di(0),                      // input wire [7 : 0] cfg_interrupt_di
  .cfg_interrupt_do(),                       // output wire [7 : 0] cfg_interrupt_do
  .cfg_interrupt_mmenable(),                 // output wire [2 : 0] cfg_interrupt_mmenable
  .cfg_interrupt_msienable(),                // output wire cfg_interrupt_msienable
  .cfg_interrupt_msixenable(),               // output wire cfg_interrupt_msixenable
  .cfg_interrupt_msixfm(),                   // output wire cfg_interrupt_msixfm
  .cfg_interrupt_stat(0),                    // input wire cfg_interrupt_stat
  .cfg_pciecap_interrupt_msgnum(0),          // input wire [4 : 0] cfg_pciecap_interrupt_msgnum
  .sys_clk(pcie_clkin),                      // input wire sys_clk
  .sys_rst_n(pcie_reset),                    // input wire sys_rst_n
  .pcie_drp_clk(0),                          // input wire pcie_drp_clk
  .pcie_drp_en(0),                           // input wire pcie_drp_en
  .pcie_drp_we(0),                           // input wire pcie_drp_we
  .pcie_drp_addr(0),                         // input wire [8 : 0] pcie_drp_addr
  .pcie_drp_di(0),                           // input wire [15 : 0] pcie_drp_di
  .pcie_drp_do(),                            // output wire [15 : 0] pcie_drp_do
  .pcie_drp_rdy()                            // output wire pcie_drp_rdy
  );

  logic [31:0] cntr;
  always_ff @(posedge clk) begin
    cntr <= cntr + 1;
  end

  ila #(
    .WIDTH(40)
  ) u_ila(
    .clk(clk),
    .trigger_in(cntr == 32'h8000_0000),
    .sample_in({cntr[0], pcie_reset, pl_ltssm_state, cntr})
  );

endmodule

