// UI bit offsets must match ui_renderer.v.
module ui_state(input wire clk,rst_n,input wire [14:0] keys,
 input wire [3:0] vol_code,input wire [9:0] lat,input wire [2:0] pan,
 input wire [1:0] octave,input wire timbre,
 output wire [175:0] live_state);
reg [14:0] prev_keys;reg [1:0] prev_octave;
reg [3:0] last_idx;reg [6:0] last_midi;
reg [23:0] note_text;reg [79:0] freq_text;
reg [6:0] volume_pct;
reg [9:0] slider_center;
reg [5:0] active_count;
wire [14:0] rising=keys & ~prev_keys;
reg [3:0] chosen;integer k;
always @* begin
 chosen=last_idx;
 for(k=0;k<15;k=k+1)if(rising[k])chosen=k;
end
wire [6:0] candidate_midi;
keyboard_pitch u_note(.idx(chosen),.octave_select(octave),.step(),.region(),.midi(candidate_midi));
wire [23:0] candidate_note;wire [79:0] candidate_freq;
ui_note_lut u_label(candidate_midi,candidate_note,candidate_freq);
function [6:0] pct_of_code;input [3:0] c;begin case(c)
 4'd0 :pct_of_code=7'd0;   4'd1 :pct_of_code=7'd7;   4'd2 :pct_of_code=7'd13;
 4'd3 :pct_of_code=7'd20;  4'd4 :pct_of_code=7'd27;  4'd5 :pct_of_code=7'd33;
 4'd6 :pct_of_code=7'd40;  4'd7 :pct_of_code=7'd47;  4'd8 :pct_of_code=7'd53;
 4'd9 :pct_of_code=7'd60;  4'd10:pct_of_code=7'd67;  4'd11:pct_of_code=7'd73;
 4'd12:pct_of_code=7'd80;  4'd13:pct_of_code=7'd87;  4'd14:pct_of_code=7'd93;
 default:pct_of_code=7'd100;endcase end endfunction
function [9:0] slider_of_code;input [3:0] c;begin case(c)
 4'd0 :slider_of_code=10'd186;  4'd1 :slider_of_code=10'd199;
 4'd2 :slider_of_code=10'd211;  4'd3 :slider_of_code=10'd224;
 4'd4 :slider_of_code=10'd237;  4'd5 :slider_of_code=10'd249;
 4'd6 :slider_of_code=10'd262;  4'd7 :slider_of_code=10'd275;
 4'd8 :slider_of_code=10'd287;  4'd9 :slider_of_code=10'd300;
 4'd10:slider_of_code=10'd313;  4'd11:slider_of_code=10'd325;
 4'd12:slider_of_code=10'd338;  4'd13:slider_of_code=10'd351;
 4'd14:slider_of_code=10'd363;  default:slider_of_code=10'd376;
endcase end endfunction
integer j;reg [4:0] count_comb;
always @* begin count_comb=0;for(j=0;j<15;j=j+1)count_comb=count_comb+keys[j];end
wire [6:0] pct_w=pct_of_code(vol_code);
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin
  prev_keys<=0;prev_octave<=1;last_idx<=0;last_midi<=60;
  note_text<=24'h433420;freq_text<=80'h3236312E363320487A20;
  volume_pct<=0;active_count<=0;slider_center<=186;
 end else begin
  prev_keys<=keys;prev_octave<=octave;
  active_count<={1'b0,count_comb};
  volume_pct<=pct_w;
  slider_center<=slider_of_code(vol_code);
  if(rising!=0 || (keys!=0 && octave!=prev_octave))begin
   last_idx<=chosen;last_midi<=candidate_midi;
   note_text<=candidate_note;freq_text<=candidate_freq;
  end
 end
end
assign live_state={11'd0,pan,lat,slider_center,last_midi,freq_text,note_text,
                   active_count,volume_pct,timbre,octave,keys};
endmodule
