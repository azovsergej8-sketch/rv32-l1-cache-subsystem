module cache_storage(
  input wire clk,  rst,
  cache_intf.storage inf //Экземпляр интерфейса
);

  //Два массива памяти
  reg[24:0] tag[15]; // Теги
  reg[127:0] data[15]; //Инструкции
  
  //FSM
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
    end else begin
      if(!inf.storage_we) begin
        inf.storage_rtag <= tag[inf.storage_rindex];
        inf.storage_rdata <= data[inf.storage_rindex];
      end else begin
        tag[inf.storage_windex] <= inf.storage_wtag;
        data[inf.storage_windex] <= inf.storage_wdata;
      end
    end
  end
endmodule
