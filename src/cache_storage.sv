module cache_storage(
  input wire clk,  rst,
  input wire[5:0] index,
  input wire we,
  input wire[23:0] w_tag,
  input wire[31:0] w_data,
  output reg valid,
  output reg[24:0] tag_out,
  output reg[31:0] data_out
);

  //Два массива памяти
  reg[24:0] tag[64]; // Теги
  reg[31:0] data[64]; //Инструкции
  
  //FSM
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      valid <= 0
    end else begin
      if(!we) begin
        tag_out <= tag[index];
        data_out <= data[index];
        valid <= 1;
      end else begin
        tag[index] <= w_tag;
        data[index] <= w_data;
        valid <= 0;
      end
    end
  end
endmodule
