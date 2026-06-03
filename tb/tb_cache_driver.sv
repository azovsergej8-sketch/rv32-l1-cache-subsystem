class cache_driver;
  mailbox #(cache_transaction) tr_fifo;
  
  function new( mailbox #(cache_transaction) addr_fifo);
    this.tr_fifo = addr_fifo;
  endfunction
  
  task drive(virtual core_intf cr_intf, event clk_e);
    forever begin
      cache_transaction tr = new();
      if(!tr.randomize()) $error("Randomization failed!");
      @(clk_e);
      if(cr_intf.ready_core) begin
        cr_intf.core_addr <= tr.addr;
        cr_intf.core_valid <= 1;
        tr_fifo.put(tr);
        tr.take_addr(tr.addr);
      end
      if(cr_intf.core_valid) cr_intf.core_valid <= 0;
    end
  endtask
endclass
