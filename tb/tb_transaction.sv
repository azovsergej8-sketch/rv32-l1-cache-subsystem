class cache_transaction;
  rand logic[31:0] addr;
  rand logic inj_split;
  rand logic is_16_bit;

  constraint addr_cons{
    if(inj_split) addr[3:0] inside {[4'hE : 4'hF]};
    else addr[3:0] dist {[0:9] :/ 80, [10:15] :/ 20};
  };

  constraint split_inj_c{
    inject_split_err dist { 1 := 10, 0 := 90 };
  };
endclass
