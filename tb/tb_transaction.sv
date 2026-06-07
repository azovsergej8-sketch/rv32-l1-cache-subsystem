class cache_transaction;
  rand logic[31:0] addr;
  rand logic inj_split;
  rand logic is_replace_check;
  static logic [31:0] address_history[$]; 
  static int max_history_size = 16;
  
  constraint addr_cons{
    if(inj_split) addr[3:0] inside {[4'hE : 4'hF]};
    else addr[3:0] dist {[0:9] :/ 80, [10:15] :/ 20};
  };
  
  constraint half_word_align {
    addr[0] == 1'b0; 
  };
  
  constraint split_inj_c{
    inj_split dist { 1 := 15, 0 := 85 };
  };

  constraint check_replace_c{
    is_replace_check dist {1 := 30, 0 := 70};
  };

  function void post_randomize();
    if(address_history.size() > 0 && is_replace_check) begin
      logic[3:0] rand_index = $urandom_range(0, address_history.size() - 1);
      addr = {address_history[rand_index][31:4], addr[3:0]};
    end
  endfunction

  function void take_addr(logic[31:0] a);
    if(address_history.size() == max_history_size) void'(address_history.pop_front());
    address_history.push_back(a);
  endfunction
endclass
