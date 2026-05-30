module cache_storage(
  input wire clk,  rst,
  cache_intf.storage inf //Экземпляр интерфейса
);

  //Два массива памяти
  reg[23:0] tag[64]; // Теги
  reg[31:0] data[64]; //Инструкции
  
  //FSM
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      inf.storage_rtag[0] <= 0;
    end else begin
      if(!inf.storage_we) begin
        inf.storage_rtag[23:0] <= tag[inf.storage_rindex];
        inf.storage_rdata <= data[inf.storage_rindex];
        inf.storage_rvalid <= 1;
      end else begin
        tag[inf.storage_windex] <= inf.storage_wtag;
        data[inf.storage_windex] <= inf.storage_wdata;
        inf.storage_rtag[0] <= 0;
      end
    end
  end
endmodule
