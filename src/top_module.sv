module top_module(
    input logic clk, rst,
    core_intf intermediate_core_io,
    memory_intf intermediate_mem_io
);

  // 1. Внутренние интерфейсы для Way 0 и Way 1
  cache_intf cache_io_w0();
  cache_intf cache_io_w1();

  // 2. Кэш-контроллер
  cache_ctrl ctrl_inst (
      .clk           (clk),
      .rst           (rst),
      .intf_core     (intermediate_core_io),
      .intf_cache_w0 (cache_io_w0.cache_controller),
      .intf_cache_w1 (cache_io_w1.cache_controller),
      .intf_memory   (intermediate_mem_io)
  );

  // 3. Компоненты для Канала 0
  pre_access_buffer pre_buff_w0 (
      .clk             (clk),
      .rst             (rst),
      .buff_intf_cache (cache_io_w0.pre_buff),
      .buff_intf_core  (intermediate_core_io.pre_buff)
  );

  cache_storage storage_w0 (
      .clk (clk),
      .rst (rst),
      .inf (cache_io_w0.storage)
  );

  // 4. Компоненты для Канала 1
  pre_access_buffer pre_buff_w1 (
      .clk             (clk),
      .rst             (rst),
      .buff_intf_cache (cache_io_w1.pre_buff),
      .buff_intf_core  (intermediate_core_io.pre_buff)
  );

  cache_storage storage_w1 (
      .clk (clk),
      .rst (rst),
      .inf (cache_io_w1.storage)
  );

endmodule
