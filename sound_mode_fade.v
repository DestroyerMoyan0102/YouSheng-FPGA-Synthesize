`timescale 1ns/1ps
module sound_mode_fade(input wire clk,rst_n,tick,
 input wire timbre_select, vibrato_select, input wire [1:0] octave_select,
 output reg active_timbre, active_vibrato, output reg [1:0] active_octave,
 output reg [15:0] gain);
 reg fading;
 reg [1:0] settle;
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
   active_timbre<=0; active_vibrato<=0; active_octave<=1; gain<=0; fading<=0; settle<=0;
  end else if(tick) begin
   if(settle!=0) begin
    gain<=0; settle<=settle-1'b1;
   end else if(fading || active_timbre!=timbre_select || active_vibrato!=vibrato_select || active_octave!=octave_select) begin
    if(gain>128) begin gain<=gain-16'd128; fading<=1; end
    else if(gain!=0) begin gain<=0; fading<=1; end
    else begin
     active_timbre<=timbre_select; active_vibrato<=vibrato_select; active_octave<=octave_select; fading<=0;
     settle<=2;
    end
   end else if(gain<16'd65407) gain<=gain+16'd128;
   else gain<=16'hffff;
  end
 end
endmodule

