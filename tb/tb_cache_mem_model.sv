class cache_mem_model;
  protected logic[7:0] ram_table[logic[31:0]];
  
  function logic[31:0] get_data(logic[31:0] addr);
    logic[31:0] result;
    for(int i = 0; i < 4; i++) begin
      if(!ram_table.exists(addr + i)) ram_table[addr+ i] = $urandom;
    end
    result = {ram_table.exists(addr), ram_table.exists(addr + 1), ram_table.exists(addr + 2), ram_table.exists(addr + 3)};
    return result;
  endfunction

  task run_mem_responder(virtual memory_intf mem_if, event e_clk);
    forever begin
      @(e_clk);
      if(mem_if.mem_valid) begin
        mem_if.mem_rdata <= this.get_data(mem_if.mem_addr);
        mem_if.mem_ready <= 1;
      end
      if(mem_if.mem_ready) mem_if.mem_ready <= 0;
    end
endclass
