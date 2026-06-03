class cache_checker;
  mailbox #(cache_transaction) addr_fifo;
  cache_mem_model mem;
  event clk_ev;
  
  //Конструктор
  function new(mailbox #(cache_transaction) addr_fi, cache_mem_model mem_obj, event clk_e);
    this.addr_fifo = addr_fi;
    this.mem = mem_obj;
    this.clk_ev = clk_e;
  endfunction

  //Сравнение
  task true_model(virtual core_intf cr_inf);
    forever begin
      @(clk_ev);
      if(cr_inf.ready_core) begin
        cache_transaction local_tr;
        logic[31:0] expect_data;
        if(!(addr_fifo.num() == 0)) begin
          addr_fifo.get(local_tr);
          expect_data = mem.get_data(local_tr.addr);
          $display("[INF_TR] Testing transaction. Addr: %h | Checking Cache Replacement: %h | Checking Split Addr: %h", local_tr.addr, local_tr.is_replace_check, local_tr.inj_split);
          if(cr_inf.core_rdata == expect_data) begin
            $display("[CHECKER_OK]  Match! Addr: %h | Data: %h", local_addr, cr_inf.core_rdata);
          end else begin
            $error("[CHECKER_FAIL] MISMATCH! Addr: %h | Exp: %h | Got: %h", local_tr.addr, expect_data, cr_inf.core_rdata);
          end
        end else begin
          $error("[CHECKER_ERR] Empty FIFO! Cache returned data, but no pending request found.");
        end
      end
    end
  endtask
endclass
