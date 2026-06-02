`include "uvm_macros.svh"
import uvm_pkg::*;

// 1. Класс транзакции
class cache_req_item extends uvm_sequence_item;
  rand logic [31:0] addr;
  rand bit inject_split_err;   // Флаг генерации адреса для проверки разрыва
  rand bit inject_replace_err; // Флаг генерации адреса для проверки замещения

  `uvm_object_utils_begin(cache_req_item)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(inject_split_err, UVM_ALL_ON)
    `uvm_field_int(inject_replace_err, UVM_ALL_ON)
  `uvm_object_utils_end

  //Конструктор
  function new(string name = "cache_req_item");
    super.new(name);
  endfunction
  
  //Ограничение по флагу
  constraint addr_c {
    if (inject_split_err) {
      addr[3:1] == 3'b111; // Адрес на границе строки для склейки
    } else{
      addr[3:1] != 3'b111;
    }
  }
  //Ограничение по области памяти
  constraint legal_ram_space {
    adrr[31:12] inside {[0:15]};
  }    
endclass

// 2. Класс ответа
class cache_rsp_item extends uvm_sequence_item;
  logic [31:0] rdata;
  int cycle_count;
  bit is_16_bit;

  `uvm_object_utils_begin(cache_rsp_item)
    `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_field_int(cycle_count, UVM_DEC)
    `uvm_field_int(is_16_bit, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "cache_rsp_item");
    super.new(name);
  endfunction
endclass

// 3. Модель памяти
class cache_mem_model extends uvm_object;
  `uvm_object_utils(cache_mem_model)

  logic [7:0] ram [0:4095];

  function new(string name = "cache_mem_model");
    super.new(name);
  endfunction

  function void init_mem();
    logic [15:0] instr;
    for (int i = 0; i < 4096; i += 2) begin
      instr = $urandom;
      if ($urandom_range(0,1)) 
        instr[1:0] = 2'b11; 
      else if (instr[1:0] == 2'b11) 
        instr[1:0] = 2'b00;

      ram[i]   = instr[7:0];
      ram[i+1] = instr[15:8];
    end
  endfunction

  function logic [15:0] read_16(logic [31:0] addr);
    logic [15:0] data;
    int offset = addr[11:0];
    data[7:0]  = ram[offset];
    data[15:8] = ram[(offset + 1) % 4096];
    return data;
  endfunction

  function logic [31:0] read_32(logic [31:0] addr);
    logic [31:0] data;
    int offset = addr[11:0];
    data[7:0]   = ram[offset];
    data[15:8]  = ram[(offset + 1) % 4096];
    data[23:16] = ram[(offset + 2) % 4096];
    data[31:24] = ram[(offset + 3) % 4096];
    return data;
  endfunction
endclass

// 4. Драйвер
class cache_driver extends uvm_driver #(cache_req_item);
  `uvm_component_utils(cache_driver)
  virtual core_intf vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge tb_top.clk iff vif.ready_core === 1'b1);
      vif.core_addr <= req.addr;
      vif.core_valid <= 1'b1;
      @(posedge tb_top.clk);
      vif.core_valid <= 1'b0;
      seq_item_port.item_done();
    end
  endtask
endclass

// 5. Монитор
lass cache_monitor extends uvm_monitor;
  `uvm_component_utils(cache_monitor)
  
  virtual core_intf vif_core;
  virtual memory_intf vif_mem;

  uvm_analysis_port #(cache_req_item) req_ap;
  uvm_analysis_port #(cache_rsp_item) rsp_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_ap = new("req_ap", this);
    rsp_ap = new("rsp_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual core_intf)::get(this, "", "vif_core", vif_core))
      `uvm_fatal("MON", "Could not get vif_core")
    if(!uvm_config_db#(virtual memory_intf)::get(this, "", "vif_mem", vif_mem))
      `uvm_fatal("MON", "Could not get vif_mem")
  endfunction

  task run_phase(uvm_phase phase);
    cache_req_item req;
    cache_rsp_item rsp;
    int cycles;
    forever begin
      @(posedge tb_top.clk);
      if (vif_core.core_valid && vif_core.ready_core) begin
        req = cache_req_item::type_id::create("req");
        req.addr = vif_core.core_addr;
        req_ap.write(req);
        cycles = 1;
        @(posedge tb_top.clk);
        while (vif_core.ready_core !== 1'b1) begin
          cycles++;
          @(posedge tb_top.clk);
        end
        cycles++; 
        rsp = cache_rsp_item::type_id::create("rsp");
        rsp.rdata = vif_core.core_rdata;
        rsp.cycle_count = cycles; 
        // Проверка на 16-битную инструкцию
        rsp.is_16_bit = (req.addr[1:0] != 3'b111); // 16-бит если не на границе строки
        rsp_ap.write(rsp);
      end
    end
  endtask
endclass

// 6. Скоребоард
class cache_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cache_scoreboard)

  uvm_tlm_analysis_fifo #(cache_req_item) req_fifo;
  uvm_tlm_analysis_fifo #(cache_rsp_item) rsp_fifo;

  cache_mem_model mem_model;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_fifo = new("req_fifo", this);
    rsp_fifo = new("rsp_fifo", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(cache_mem_model)::get(this, "", "mem_model", mem_model))
      `uvm_fatal("SCBD", "Failed to get mem_model from config_db!")
  endfunction

  task run_phase(uvm_phase phase);
    cache_req_item req;
    cache_rsp_item rsp;
    logic [15:0] f_half, s_half;
    logic [31:0] expected_data;
    int expected_cycles;

    forever begin
      req_fifo.get(req);
      rsp_fifo.get(rsp);

      f_half = mem_model.read_16(req.addr);

      if (f_half[1:0] != 2'b11) begin
        // 16-битная команда
        expected_data = {16'h0000, f_half};
        expected_cycles = 3; 
      end else begin
        s_half = mem_model.read_16(req.addr + 2);
        expected_data = {s_half, f_half};
        
        // Разрыв на границе кэш-линии
        if (req.addr[3:1] == 3'b111) expected_cycles = 4;
        else expected_cycles = 3; 
      end

      // 3. Проверка
      if (rsp.rdata !== expected_data) begin
        `uvm_error("DATA_ERR", $sformatf("Mismatch! Addr: %0h Exp: %0h Got: %0h", req.addr, expected_data, rsp.rdata))
      end
      
      if (rsp.cycle_count <= 4 && rsp.cycle_count != expected_cycles) begin
        `uvm_error("TIME_ERR", $sformatf("Timing Mismatch at %0h! Exp: %0d Got: %0d", req.addr, expected_cycles, rsp.cycle_count))
      end
    end
  endtask
endclass

//5. Ответчик шины
class cache_mem_responder extends uvm_driver #(uvm_sequence_item);
  `uvm_component_utils(cache_mem_responder)

  virtual memory_intf vif_mem;
  cache_mem_model mem_model;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual memory_intf)::get(this, "", "vif_mem", vif_mem))
      `uvm_fatal("MEM_RSP", "No vif_mem found!")
    if(!uvm_config_db#(cache_mem_model)::get(this, "", "mem_model", mem_model))
      `uvm_fatal("MEM_RSP", "No mem_model found!")
  endfunction
  
  task run_phase(uvm_phase phase);
    vif_mem.mem_ready <= 0;
    forever begin
      @(posedge vif_mem.clk); // Ждем такта
      if (vif_mem.mem_valid && !vif_mem.mem_ready) begin
        // Имитация задержку AHB-памяти
        repeat(2) @(posedge vif_mem.clk);
        vif_mem.mem_ready <= 1;
        vif_mem.mem_rdata <= mem_model.read_32(vif_mem.mem_addr);
        @(posedge vif_mem.clk);
        vif_mem.mem_ready <= 0;
      end
    end
  endtask
endclass

// 7 Генератор транзакций
class cache_base_seq extends uvm_sequence #(cache_req_item);
  `uvm_object_utils(cache_base_seq)

  function new(string name = "cache_base_seq");
    super.new(name);
  endfunction

  task body();
    repeat(500) begin
      req = cache_req_item::type_id::create("req");
      start_item(req);
      if (!req.randomize()) begin
        `uvm_fatal("SEQ", "Randomization failed!")
      end
      
      finish_item(req);
    end
  endtask
endclass

// 8. Драйвер Ядра
class cache_driver extends uvm_driver #(cache_req_item);
  `uvm_component_utils(cache_driver)

  virtual core_intf vif_core;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual core_intf)::get(this, "", "vif_core", vif_core))
      `uvm_fatal("DRV", "Could not get vif_core")
  endfunction

  task run_phase(uvm_phase phase);
    vif_core.core_valid <= 0;
    vif_core.core_addr  <= 0;

    forever begin
      seq_item_port.get_next_item(req);
      
      @(posedge tb_top.clk);
      vif_core.core_valid <= 1'b1;
      vif_core.core_addr  <= req.addr;

      @(posedge tb_top.clk);
      while (vif_core.ready_core !== 1'b1) begin
        @(posedge tb_top.clk);
      end
      
      vif_core.core_valid <= 1'b0;
      seq_item_port.item_done();
    end
  endtask
endclass

//9. Агент
class cache_agent extends uvm_agent;
  `uvm_component_utils(cache_agent)
  cache_driver    driver;
  cache_monitor   monitor;
  uvm_sequencer #(cache_req_item) sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = cache_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = cache_driver::type_id::create("driver", this);
      sequencer = uvm_sequencer#(cache_req_item)::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction
endclass

// 10. Тест
class cache_test extends uvm_test;
  `uvm_component_utils(cache_test)

  cache_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = cache_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    cache_base_seq seq;
    phase.raise_objection(this);
    seq = cache_base_seq::type_id::create("seq");
    seq.start(env.agent_core.sequencer);
    #200ns; 
    
    phase.drop_objection(this);
  endtask
endclass

// 11. Тестбенч
module tb_top;

  bit clk;
  bit rst;

  always #5 clk = ~clk; // 100 MHz

  initial begin
    clk = 0;
    rst = 0;
    #23 rst = 1;
  end
  core_intf   core_io();
  memory_intf mem_io();
  top_module DUT (
    .clk                  (clk),
    .rst                  (rst),
    .intermediate_core_io (core_io.cache_controller),
    .intermediate_mem_io  (mem_io.cache_controller)
  );

  initial begin
    uvm_config_db#(virtual core_intf)::set(null, "*", "vif_core", core_io);
    uvm_config_db#(virtual memory_intf)::set(null, "*", "vif_mem", mem_io);

    // Запускаем тест
    run_test("cache_test");
  end
