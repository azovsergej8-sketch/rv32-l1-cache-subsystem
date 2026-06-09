module cache_storage(
  input wire clk,  rst,
  cache_intf.storage inf //Экземпляр интерфейса
);

  //Два массива памяти
  reg[24:0] tag[16]; // Теги
  reg[127:0] data[16]; //Инструкции
  
  //FSM
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      tag[0][0] <= 0; tag[1][0] <= 0; tag[2][0] <= 0; tag[3][0] <= 0;
      tag[4][0] <= 0; tag[5][0] <= 0; tag[6][0] <= 0; tag[7][0] <= 0;
      tag[8][0] <= 0; tag[9][0] <= 0; tag[10][0] <= 0; tag[11][0] <= 0;
      tag[12][0] <= 0; tag[13][0] <= 0; tag[14][0] <= 0; tag[15][0] <= 0;
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
