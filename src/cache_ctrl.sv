module cache_ctrl(
  input wire clk, rst,
  core_intf.cache_controller intf_core;
  cache_intf.cache_controller intf_cache_w0;
  cache_intf.cache_controller intf_cache_w1;
  memory_intf.cache_controller intf_memory;
);
  //Сохраненный адрес и состояние
  logic[31:0] addr_reg;
  typedef enum logic[3:0]{IDLE, CACHE_WAIT, CACHE_CHECK, AHB_ADDR, AHB_DATA} state_t;
  state_t state;

  //Массив последних обращений
  logic last_access[64];
  
  //FSM
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
    end else begin
      case(state)
        IDLE: begin
          intf_cache_w0.storage_we <= 0;
          intf_cache_w1.storage_we <= 0;
          intf_memory.h_trans <= 2'b00;
          intf_core.ready_core <= 1;
          if(intf_core.core_valid) begin
            addr_reg <= intf_core.core_addr;
            intf_cache_w0.storage_rindex <= intf_core.core_addr[7:2];
            intf_cache_w1.storage_rindex <= intf_core.core_addr[7:2];
            state <= CACHE_WAIT;
          end
        end
        CACHE_WAIT: begin
          intf_core.ready_core <= 0;
          state <= CACHE_CHECK;
        end
        CACHE_CHECK: begin
          if((intf_cache_w0.storage_rtag[24:1] == addr_reg[31:8] && intf_cache_w0.storage_rtag[0] == 1) || (intf_cache_w1.storage_rtag[24:1] == addr_reg[31:8] && intf_cache_w1.storage_rtag[0] == 1)) begin
            if(intf_cache_w0.storage_rtag[24:1] == addr_reg[31:8]) begin
              intf_core.core_rdata <= intf_cache_w0.storage_rdata;
              last_access[addr_reg[7:2]] <= 0;
            end else begin
              intf_core.core_rdata <= intf_cache_w1.storage_rdata;
              last_access[addr_reg[7:2]] <= 1;
            end
            intf_core.ready_core <= 1;
            state <= IDLE;
          end else begin
            intf_core.ready_core <= 0;
            state <= AHB_ADDR;
          end
        end
        AHB_ADDR: begin
          intf_memory.h_trans <= 2'b10;
          intf_memory.mem_addr <= addr_reg;
          intf_memory.mem_valid <= 1;
          state <= AHB_DATA;
        end
        AHB_DATA: begin
          if(intf_memory.mem_ready) begin
            intf_memory.h_trans <= 2'b00;
            intf_memory.mem_valid <= 0;

            //Прямое пробрасывание данных процессору
            intf_core.core_rdata <= intf_memory.mem_rdata;
            intf_core.ready_core <= 1;
            
            //Запись корректных данных  по тегу
            if(last_access[addr_reg[7:2]] == 1) begin
              intf_cache_w0.storage_we <= 1;
              intf_cache_w0.storage_windex <= addr_reg[7:2];
              intf_cache_w0.storage_wtag[24:1] <= addr_reg[31:8];
              intf_cache_w0.storage_wtag[0] <= 1;
              intf_cache_w0.storage_wdata <= intf_memory.mem_rdata;
              last_access[addr_reg[7:2]] <= 0;
            end else begin
              intf_cache_w1.storage_we <= 1;
              intf_cache_w1.storage_windex <= addr_reg[7:2];
              intf_cache_w1.storage_wtag[24:1] <= addr_reg[31:8];
              intf_cache_w1.storage_wtag[0] <= 1;
              intf_cache_w1.storage_wdata <= intf_memory.mem_rdata;
              last_access[addr_reg[7:2]] <= 1;
            end
            state <= IDLE;
          end
        end
      endcase
    end
  end
endmodule
