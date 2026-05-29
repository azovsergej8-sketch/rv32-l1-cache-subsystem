//Интерфейс с процессором
interface core_intf();
  logic[31:0] core_addr;
  logic core_valid;
  logic[31:0] core_rdata;
  logic ready_core;

  modport cash_controller(
    input core_addr, core_valid;
    output core_rdata, ready_core;
  );
endinterface

//Интерфейс с процессором
interface cash_intf();
  logic[5:0] storage_index;
  logic storage_we;
  logic[24:0] storage_wtag;
  logic[31:0] storage_wdata;
  logic storage_rvalid;
  logic[24:0] storage_rtag;
  logic[31:0] storage_rdata;
  modport cash_controller(
    input core_addr, core_valid;
    output core_rdata, ready_core;
  );
endinterface
