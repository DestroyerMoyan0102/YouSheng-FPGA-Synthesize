`timescale 1ns/1ps
module audio_buttons #(parameter integer CLK_HZ=50_000_000, DEBOUNCE_MS=10)(
 input wire clk,rst_n,timbre_n,metro_event,
 output reg [1:0] sound_mode,metro_mode);
 wire sound_event;
 timbre_button #(.CLK_HZ(CLK_HZ),.DEBOUNCE_MS(DEBOUNCE_MS))
  sound_key(clk,rst_n,timbre_n,,sound_event);
 always @(posedge clk or negedge rst_n)
  if(!rst_n) begin sound_mode<=0;metro_mode<=0;end
  else begin
   if(sound_event) sound_mode<=sound_mode+2'd1;
   if(metro_event) metro_mode<=(metro_mode==2)?2'd0:metro_mode+2'd1;
  end
endmodule
