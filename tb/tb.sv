module tb_top;
  logic clk = 0;
  logic rst = 1;
  always #5 clk = ~clk;
  event clk_ev;
  always@(posedge clk) -> clk_ev;

  core_intf intermediate_core_io;
  memory_intf intermediate_mem_io;
  malibox #(logic[31:0]) addr_fifo;
  
  top_module(
    .clk                   (clk),
    .rst                   (rst),
    .intermediate_core_io  (intermediate_core_io),
    .intermediate_mem_io   (intermediate_mem_io)
  );

  initial begin
    test actual_test = new(intermediate_core_io, intermediate_mem_io, addr_fifo, clk_ev);
    actual_test.run();
    $finish;
  end
  
endmodule
