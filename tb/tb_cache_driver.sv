class cache_driver;
  malibox #(logic[31:0]) tr_fifo;
  
  function new( malibox #(logic[31:0]) addr_fifo);
    this.tr_fifo = addr_fifo;
  endfunction
  
  task drive(virtual core_intf cr_intf, event clk_e);
    always begin
      cache_transaction tr = new();
      if(!tr.randomize()) $error("Randomization failed!");
      @(clk_e);
      if(ready_core) begin
        cr_intf.core_addr = tr.addr;
        core_valid <= 1;
        addr_fifo.put(tr.addr);
      end
      if(core_valid) core_valid <= 0;
    end
  endtask
endclass
