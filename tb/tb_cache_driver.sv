class cache_driver;
  mailbox #(cache_transaction) tr_fifo;
  
  function new( mailbox #(cache_transaction) addr_fifo);
    this.tr_fifo = addr_fifo;
  endfunction
  
  task drive(virtual core_intf cr_intf, event clk_e);
    cache_transaction tr;
    repeat(50) begin
      if(tr == null) begin
        tr = new();
        if(!tr.randomize()) $error("Randomization failed!");
      end
      @(clk_e);
      if(cr_intf.ready_core) begin
        cr_intf.core_addr <= #1 tr.addr;
        cr_intf.core_valid <= #1 1;
        tr_fifo.put(tr);
        tr.take_addr(tr.addr);
        tr = null;
      end else cr_intf.core_valid <= 0;
    end
  endtask
endclass
