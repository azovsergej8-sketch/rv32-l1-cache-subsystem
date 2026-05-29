//Интерфейс с процессором
interface core_intf();
  logic[31:0] core_addr;
  logic core_valid;
  logic[31:0] core_rdata;
  logic ready_core;

  modport cache_controller(
    input core_addr, core_valid;
    output core_rdata, ready_core;
  );
endinterface

//Интерфейс с кэшем
interface cache_intf();
  logic[5:0] storage_windex;
  logic storage_we;
  logic[5:0] storage_rindex;
  logic[23:0] storage_wtag;
  logic[31:0] storage_wdata;
  logic storage_rvalid;
  logic[23:0] storage_rtag;
  logic[31:0] storage_rdata;
  modport cache_controller(
    input storage_rtag, storage_rdata, storage_rvalid;
    output storage_windex, storage_we, storage_rindex, storage_wtag, storage_wdata;
  );
  modport storage(
    output storage_rtag, storage_rdata, storage_rvalid;
    input storage_windex, storage_we, storage_rindex, storage_wtag, storage_wdata;
  );
endinterface

//Интерфейс с внешней памятью
interface memory_intf();
  logic[31:0] mem_addr;
  logic mem_valid;
  logic[31:0] mem_rdata;
  logic mem_ready;
  logic[2:0] hsize;
  logic[1:0] h_trans;
  
  modport cache_controller(
    input mem_rdata, mem_ready;
    output mem_addr, mem_valid;
  );
endinterface
