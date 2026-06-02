class cache_mem_model;
  protected logic[7:0] ram_table[logic[31:0]];
  function logic[31:0] get_data(logic[31:0] addr);
    logic[31:0] result;
    for(int i = 0; i < 4; i++) begin
      if(!ram_table.exists(addr + i)) ram_table[addr+ i] = #urandom;
    end
    result = {ram_table.exists(addr), ram_table.exists(addr + 1), ram_table.exists(addr + 2), ram_table.exists(addr + 3)};
    return result;
  endfunction
endclass
