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
    logic [31:0] exp_q[$];
    int count_rep = 0;
    int count = 0;
    fork
      forever begin
      cache_transaction local_tr;
        logic[31:0] expect_data;
        logic[31:0] save_addr;
        @(clk_ev);
        if(cr_inf.core_valid && cr_inf.ready_core) begin
          addr_fifo.get(local_tr);
          save_addr = local_tr.addr;
          expect_data = mem.get_data(local_tr.addr);
          if(expect_data[1:0] != 2'b11 && (local_tr.addr[3:1] % 2 == 0)) begin
            expect_data = {16'h0000, expect_data[15:0]};
          end else if(local_tr.addr[3:1] % 2 == 1) begin
            if(expect_data[17:16] != 2'b11) expect_data = {16'h0000, expect_data[31:16]};
            else begin
              expect_data[15:0] = expect_data[31:16];
              if(local_tr.addr[3:1] < 6) save_addr = {save_addr[31:4], save_addr[3:2] + 1'b1, save_addr[1:0]};
              else save_addr = {save_addr[31:4] + 1'b1, 4'b0000};
              expect_data[31:16] = mem.get_data(save_addr);
            end
          end
          exp_q.push_back(expect_data);
          count = count + 1;
        end
      end
      forever begin
        @(clk_ev);
        if (cr_inf.data_out_valid) begin
          if (exp_q.size() > 0) begin
            logic [31:0] expected = exp_q.pop_front();
            if(cr_inf.core_rdata == expected) begin
              $display("[CHECKER_OK] {%0d} Match! Data: %h", count_rep + 1, cr_inf.core_rdata);
            end else begin
              $error("[CHECKER_FAIL] {%0d} MISMATCH! Exp: %h | Got: %h", count_rep + 1, expected, cr_inf.core_rdata);
            end
            count_rep = count_rep + 1;
          end
        end
      end
    join
  endtask
endclass
