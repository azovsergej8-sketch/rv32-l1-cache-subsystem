class test;
  virtual core_intf cr_if;
  virtual memory_intf mem_if;
  cache_driver    drv;
  cache_checker   chk;
  cache_mem_model mem;
  event clk_ev;

  function new(virtual core_intf c_if, virtual memory_intf m_if,  mailbox #(cache_transaction) addr_fifo, event clk_e);
    this.cr_if = c_if;
    this.mem_if = m_if;
    this.drv = new(addr_fifo);
    this.mem = new();
    this.clk_ev = clk_e;
    this.chk = new(addr_fifo, this.mem, this.clk_ev);
  endfunction

  task run();
  	repeat(2) @(clk_ev);
    fork
      drv.drive(cr_if, clk_ev);
      mem.run_mem_responder(mem_if, clk_ev);
      chk.true_model(cr_if);
    join_any
    disable fork;
    $display("Test finished!");
    $dumpoff;
    #10
    $finish;
  endtask
endclass
