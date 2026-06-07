class cache_driver;
  mailbox #(cache_transaction) tr_fifo;
  
  function new( mailbox #(cache_transaction) addr_fifo);
    this.tr_fifo = addr_fifo;
  endfunction
  
  task drive(virtual core_intf cr_intf, event clk_e);
    cache_transaction tr;
    int transaction_count = 0;
    while(transaction_count < 40) begin
      if(tr == null) begin
        tr = new();
        if(!tr.randomize()) $error("Randomization failed!");
      end
      @(clk_e);
      cr_intf.core_valid <= #1 0;
      if(cr_intf.ready_core) begin
      	cr_intf.core_addr <= #1 tr.addr;
      	cr_intf.core_valid <= #1 1;
      	tr.take_addr(tr.addr);
        $display("[INF_TR] {%0d} Testing TR: Addr: %h | Replace Check: %h | Split Check: %h ", transaction_count + 1, tr.addr, tr.is_replace_check, tr.inj_split);
      	tr_fifo.put(tr);
        @(clk_e);
        cr_intf.core_valid <= #1 0;
        @(clk_e);
      	tr = null;
      	transaction_count = transaction_count + 1;
      end
    end
  endtask
endclass
