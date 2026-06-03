module tb_top;
  logic clk = 0;
  logic rst = 1;
  always #5 clk = ~clk;
  event clk_ev;
  always@(posedge clk) -> clk_ev;
  
  initial begin
    rst = 1;
    #20 rst = 0; 
    #20 rst = 1; 
  end
  
  core_intf intermediate_core_io();
  memory_intf intermediate_mem_io();
  mailbox #(cache_transaction) addr_fifo;
  
  top_module dut(
    .clk                   (clk),
    .rst                   (rst),
    .intermediate_core_io  (intermediate_core_io),
    .intermediate_mem_io   (intermediate_mem_io)
  );

  initial begin
    addr_fifo = new();
    test actual_test = new(intermediate_core_io, intermediate_mem_io, addr_fifo, clk_ev);
    actual_test.run();
    $finish;
  end
  
endmodule
