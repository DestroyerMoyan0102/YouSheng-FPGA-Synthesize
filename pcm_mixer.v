`timescale 1ns/1ps
module pcm_mixer(input wire clk,rst_n,tick,reserve,
 input wire signed [15:0] keys,click,input wire [15:0] volume,
 output wire signed [15:0] pcm,output wire ready);
 reg [15:0] key_gain;
 wire [15:0] target=reserve?16'd24576:16'd32768;
 assign ready=(key_gain==24576);
 always @(posedge clk or negedge rst_n)
  if(!rst_n)key_gain<=32768;
  else if(tick) begin
   if(key_gain>target)key_gain<=key_gain-16'd32;
   else if(key_gain<target)key_gain<=key_gain+16'd32;
  end
 reg signed [32:0] key_product,click_product;
 reg signed [17:0] sum;
 always @(posedge clk or negedge rst_n)
  if(!rst_n)begin key_product<=0;click_product<=0;sum<=0;end
  else begin
   key_product<=keys*$signed({1'b0,key_gain});
   click_product<=click*$signed({1'b0,volume});
   sum<=(key_product>>>15)+(click_product>>>15);
  end
 wire signed [15:0] limited=(sum>32767)?16'sd32767:
                                  (sum< -32768)?-16'sd32768:sum[15:0];
 assign pcm=(key_gain==32768 && !reserve)?keys:limited;
endmodule
