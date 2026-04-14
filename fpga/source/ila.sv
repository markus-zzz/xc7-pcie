`default_nettype none

module ila #(
  parameter logic [15:0] WIDTH = 32,
  parameter logic [15:0] DEPTH = 1024
)
(
  input wire clk,
  // Sampling interface
  input wire trigger_in,
  input wire [WIDTH-1:0] sample_in
);

  logic running;
  logic triggered;
  logic [$clog2(DEPTH)-1:0] sample_widx;
  logic [$clog2(DEPTH)-1:0] post_trig_cntr;
  logic [$clog2(DEPTH)-1:0] trigger_idx;
  logic [$clog2(DEPTH)-1:0] jtag_addr;

  logic [WIDTH-1:0] ram_do;

  spram #(
    .aw($clog2(DEPTH)),
    .dw(WIDTH)
  ) u_ram(
    .clk(running ? clk : drck2),
    .rst(1'b0),
    .ce(1'b1),
    .we(running),
    .oe(1'b1),
    .addr(running ? sample_widx : jtag_addr),
    .din(sample_in),
    .dout(ram_do)
  );

  always_ff @(posedge clk) begin
    if (running) sample_widx <= sample_widx + 1;
  end

  always_ff @(posedge clk) begin
    if (trigger_in & ~triggered) trigger_idx <= sample_widx;
  end

  always_ff @(posedge clk) begin
    if (update1_clk_pulse & sr1_in[0]) post_trig_cntr <= sr1_in[31:16]; // Only on Start command
    else if (running & triggered) post_trig_cntr <= post_trig_cntr - 1;
  end

  always_ff @(posedge clk) begin
    if (update1_clk_pulse & sr1_in[1]) running <= 0; // Stop command
    else if (update1_clk_pulse & sr1_in[0]) running <= 1; // Start command
    else if (triggered && post_trig_cntr == 2) running <= 0; // Compensate for latency
  end

  always_ff @(posedge clk) begin
    if (update1_clk_pulse & sr1_in[0]) triggered <= 0;
    else if (running & trigger_in) triggered <= 1;
  end

  //
  // JTAG access - Control/Status
  //
  // Reads as  {16'(DEPTH), 16'(WIDTH), 16'(trigger_idx), 14'h0, triggered, running}
  // Writes as {post_trig_cntr, stop, start}
  //
  logic tck1, capture_en1, shift_en1, update_en1, tdi1, tdo1;
  logic [63:0] sr1_in, sr1_out;
  logic update1, update1_clk_pulse;
  logic [2:0] update1_clk_sync;

  BSCANE2 #(
    .JTAG_CHAIN(1)
  ) u_bscane2_1 (
    .CAPTURE(capture_en1),
    .DRCK(),
    .RESET(),
    .RUNTEST(),
    .SEL(),
    .SHIFT(shift_en1),
    .TCK(tck1),
    .TDI(tdi1),
    .TMS(),
    .UPDATE(update_en1),
    .TDO(tdo1)
  );

  assign tdo1 = sr1_out[0];
  always_ff @(posedge tck1) begin
    if (capture_en1) begin
      sr1_out <= {16'(DEPTH), 16'(WIDTH), 16'(trigger_idx), 14'h0, triggered, running};
      update1 <= 0;
    end else if (shift_en1) begin
      sr1_in <= {tdi1, sr1_in[63:1]};
      sr1_out <= {1'b0, sr1_out[63:1]};
    end else if (update_en1) begin
      update1 <= 1;
    end
  end

  always_ff @(posedge clk) begin
    update1_clk_sync <= {update1, update1_clk_sync[2:1]};
  end

  assign update1_clk_pulse = ~update1_clk_sync[0] & update1_clk_sync[1];

  //
  // JTAG access - ILA RAM
  //
  logic drck2, capture_en2, shift_en2, tdi2, tdo2;
  logic [WIDTH-1:0] sr2;

  BSCANE2 #(
    .JTAG_CHAIN(2)
  ) u_bscane2_2 (
    .CAPTURE(capture_en2),
    .DRCK(drck2),
    .RESET(),
    .RUNTEST(),
    .SEL(),
    .SHIFT(shift_en2),
    .TCK(),
    .TDI(tdi2),
    .TMS(),
    .UPDATE(),
    .TDO(tdo2)
  );

  logic [$clog2(WIDTH):0] jtag_shft_cntr;
  assign tdo2 = sr2[0];
  always_ff @(posedge drck2) begin
    if (capture_en2) begin
      jtag_addr <= -1;
      jtag_shft_cntr <= 2;
    end else if (shift_en2) begin
      sr2 <= {1'b0, sr2[WIDTH-1:1]};
      jtag_shft_cntr <= jtag_shft_cntr - 1;
      if (jtag_shft_cntr == 2) begin
        jtag_addr <= jtag_addr + 1;
      end else if (jtag_shft_cntr == 0) begin
        jtag_shft_cntr <= WIDTH - 1;
        sr2 <= ram_do;
      end
    end
  end

endmodule
