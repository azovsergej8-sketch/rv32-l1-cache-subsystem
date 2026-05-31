module pre_access_buffer(
  input logic clk, rst,
  cache_intf.pre_buff buff_intf_cache,
  core_intf.pre_buff buff_intf_core
);

  typedef enum logic[1:0]{IDLE, CACHE_WAIT, CACHE_CHECK, COMB_DATA} state_t;
  state_t state;
  logic[31:0] register_addr;
  logic[3:0] offset;
  always_ff@(posedge clk or negedge rst) begin
    if(!rst) begin
      buff_intf_cache.buf_data <= 0;
      buff_intf_cache.buf_ready <= 0;
      state <= IDLE;
    end else begin
      case(state)
        IDLE: begin
          buff_intf_cache.buf_data <= 0;
          buff_intf_cache.buf_ready <= 0;
          if(buff_intf_core.core_valid && buff_intf_core.ready_core) begin
            register_addr <= buff_intf_core.core_addr;
            buff_intf_cache.storage_rindex <= buff_intf_core.core_addr[7:4];
            state <= CACHE_WAIT;
            offset <= buff_intf_core.core_addr[3:1];
          end
        end
        CACHE_WAIT: begin
          state <= CACHE_CHECK;
        end
        CACHE_CHECK: begin
          if(buff_intf_cache.storage_rdata[offset*16 +: 2] != 2'b11) begin
            buff_intf_cache.buf_data[15:0] <= buff_intf_cache.storage_rdata[offset*16 +: 16];
            buff_intf_cache.buf_ready <= 1;
            state <= IDLE;
          end else begin
            if(register_addr[3:1] == 3'b111) begin
              buff_intf_cache.buf_data[15:0] <= buff_intf_cache.storage_rdata[112 +: 16];
              buff_intf_cache.storage_rindex <= register_addr[7:4] + 1;
              state <= COMB_DATA;
            end else begin
              buff_intf_cache.buf_data <= buff_intf_cache.storage_rdata[offset*16 +: 32];
              buff_intf_cache.buf_ready <= 1;
              state <= IDLE;
            end
          end
          buff_intf_cache.buf_tag <= buff_intf_cache.storage_rtag;
        end
        COMB_DATA: begin
          buff_intf_cache.buf_data[31:16] <= buff_intf_cache.storage_rdata[15:0];
          buff_intf_cache.buf_ready <= 1;
          state <= IDLE;
        end
      endcase
    end
  end 
endmodule
