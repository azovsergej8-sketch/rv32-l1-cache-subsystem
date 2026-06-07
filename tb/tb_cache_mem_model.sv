class cache_mem_model;
  protected logic[127:0] ram_table[logic[31:4]];
  
  function logic[31:0] get_data(logic[31:0] addr);
    logic[31:0] result;
    if ($isunknown(addr)) addr = 32'h0;
    if(!ram_table.exists(addr[31:4])) ram_table[addr[31:4]] = {$urandom, $urandom, $urandom, $urandom};
    result = ram_table[addr[31:4]][addr[3:2]*32 +: 32];
    return result;
  endfunction

  task run_mem_responder(virtual memory_intf mem_if, event e_clk);
    forever begin
      @(e_clk);
      if(mem_if.mem_valid && !mem_if.mem_ready) begin
        mem_if.mem_rdata <= #1 this.get_data(mem_if.mem_addr);
        mem_if.mem_ready <= #1 1;
      end else begin
      	mem_if.mem_ready <= #1 0;
      end
    end
  endtask
endclass
