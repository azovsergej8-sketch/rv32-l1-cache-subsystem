module cache_ctrl(
  input wire clk, rst,
  core_intf.cache_controller intf_core,
  cache_intf.cache_controller intf_cache_w0,
  cache_intf.cache_controller intf_cache_w1,
  memory_intf.cache_controller intf_memory
);
  //Сохраненный адрес и состояние
  logic[31:0] addr_reg;
  typedef enum logic[3:0]{IDLE, CACHE_CHECK, AHB_DATA} state_t;
  state_t state;
  logic is_half;
  //
  logic[127:0] data_line;
  logic[2:0] count;
  logic[3:0] count_bit;
  //Массив последних обращений
  logic last_access[16];
  
  //FSM
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      state <= IDLE;
      last_access[0] <= 0;  last_access[1] <= 0;  last_access[2] <= 0;  last_access[3] <= 0;
      last_access[4] <= 0;  last_access[5] <= 0;  last_access[6] <= 0;  last_access[7] <= 0;
      last_access[8] <= 0;  last_access[9] <= 0;  last_access[10] <= 0; last_access[11] <= 0;
      last_access[12] <= 0; last_access[13] <= 0; last_access[14] <= 0; last_access[15] <= 0;
      intf_core.data_out_valid <= 0;
      intf_memory.h_trans <= 2'b00;
      count <= 3'b000;
      count_bit <= 4'b0000;
      is_half <= 0;
    end else begin
      case(state)
        IDLE: begin
          intf_core.data_out_valid <= 0;
          intf_memory.h_trans <= 2'b00;
          count <= 3'b000;
          count_bit <= 4'b0000;
          is_half <= 0;
          if(intf_core.core_valid) begin
            addr_reg <= intf_core.core_addr;
            state <= CACHE_CHECK;
            intf_core.ready_core <= 0;
          end else intf_core.ready_core <= 1;
        end
        CACHE_CHECK: begin
          intf_cache_w0.storage_we <= 0;
          intf_cache_w1.storage_we <= 0;
          intf_core.ready_core <= 0;
          if(intf_cache_w0.buf_ready && intf_cache_w1.buf_ready) begin
            if((intf_cache_w0.buf_tag[24:1] == addr_reg[31:8] && intf_cache_w0.buf_tag[0] == 1) || (intf_cache_w1.buf_tag[24:1] == addr_reg[31:8] && intf_cache_w1.buf_tag[0] == 1)) begin
              if(intf_cache_w0.buf_tag[24:1] == addr_reg[31:8]) begin
                 intf_core.core_rdata <= intf_cache_w0.buf_data;
                 last_access[addr_reg[7:4]] <= 0;
              end else if(intf_cache_w1.buf_tag[24:1] == addr_reg[31:8]) begin
                 intf_core.core_rdata <= intf_cache_w1.buf_data;
                last_access[addr_reg[7:4]] <= 1;
              end
              intf_core.data_out_valid <= 1;
              state <= IDLE;
            end else begin
              intf_core.ready_core <= 0;
              intf_memory.h_trans <= 2'b10;
              intf_memory.mem_addr[31:4] <= addr_reg[31:4];
              intf_memory.mem_addr[3:2] <= 2'b00;
              intf_memory.mem_addr[1:0] <= 2'b11;
              intf_memory.mem_valid <= 1;
              state <= AHB_DATA;
              count <= count + 1;
              count_bit <= count_bit + 2;
            end
          end
        end
        AHB_DATA: begin
          if(intf_memory.mem_ready) begin
            if(count < 3'b101) begin
              if(intf_core.data_out_valid) intf_core.data_out_valid <= 0;
              //Прямое пробрасывание данных процессору
              //2. Смещение кратно 2
              if(count_bit == addr_reg[3:1] + 2) begin
                if(intf_memory.mem_rdata[1:0] == 2'b11) begin
                  intf_core.core_rdata <= intf_memory.mem_rdata;
                end else begin
                  intf_core.core_rdata <= intf_memory.mem_rdata[15:0];
                end
                intf_core.data_out_valid <= 1;
              //3. Смещение некратное 2
              end else if(count_bit == addr_reg[3:1] + 1) begin
                if(intf_memory.mem_rdata[17:16] == 2'b11) begin
                  intf_core.core_rdata[15:0] <= intf_memory.mem_rdata[31:16];
                  is_half <= 1;
                end else begin
                  intf_core.core_rdata <= intf_memory.mem_rdata[31:16];
                  intf_core.data_out_valid <= 1;
                end
              //3.2 Получение второй половины данных
              end else if(count_bit == addr_reg[3:1] + 3 && is_half) begin
                intf_core.core_rdata[31:16] <= intf_memory.mem_rdata[15:0];
                intf_core.data_out_valid <= 1;
                is_half <= 0;
              end 
              if(count == 4) begin
                //Запись корректных данных  по тегу
                if(last_access[addr_reg[7:4]] == 1) begin
                  intf_cache_w0.storage_we <= 1;
                  intf_cache_w0.storage_windex <= addr_reg[7:4];
                  intf_cache_w0.storage_wtag[24:1] <= addr_reg[31:8];
                  intf_cache_w0.storage_wtag[0] <= 1;
                  intf_cache_w0.storage_wdata[95:0] <= data_line[95:0];
                  intf_cache_w0.storage_wdata[127:96] <= intf_memory.mem_rdata;
                  last_access[addr_reg[7:4]] <= 0;
                end else begin
                  intf_cache_w1.storage_we <= 1;
                  intf_cache_w1.storage_windex <= addr_reg[7:4];
                  intf_cache_w1.storage_wtag[24:1] <= addr_reg[31:8];
                  intf_cache_w1.storage_wtag[0] <= 1;
                  intf_cache_w1.storage_wdata[95:0] <= data_line[95:0];
                  intf_cache_w1.storage_wdata[127:96] <= intf_memory.mem_rdata;
                  last_access[addr_reg[7:4]] <= 1;
                end
                //Изменение адреса
                if(intf_memory.mem_rdata[17:16] == 2'b11 && count_bit == addr_reg[3:1] + 1) begin
                  intf_memory.mem_addr <= {addr_reg[31:4] + 1'b1, 4'b0000};
                  intf_memory.mem_valid <= 1;
            	end
              end else begin
                //Считывание текущих
                data_line[(count-1)*32 +: 32] <= intf_memory.mem_rdata;
                //Запрос последующих данных
                intf_memory.mem_addr[31:4] <= addr_reg[31:4];
                intf_memory.mem_addr[3:2] <= count;
                intf_memory.mem_addr[1:0] <= 2'b11;
                count_bit <= count_bit + 2;
                intf_memory.mem_valid <= 1;
              end
          	count <= count + 1;
          //Запрос половины команды из следующей строки
          end else if(is_half) begin
              intf_memory.mem_valid <= 0;
              intf_memory.h_trans <= 2'b00;
              is_half <= 0;
              intf_core.ready_core <= 1;
              intf_core.core_rdata[31:16] <= intf_memory.mem_rdata[15:0];
              intf_core.data_out_valid <= 1;
              state <= IDLE;
           end else begin
              intf_memory.mem_valid <= 0;
              intf_memory.h_trans <= 2'b00;
              intf_cache_w0.storage_we <= 0;
              intf_cache_w1.storage_we <= 0;
              intf_core.ready_core <= 1;
              state <= IDLE;
              intf_core.data_out_valid <= 0;
           end
          end
        end
      endcase
    end
  end
endmodule
