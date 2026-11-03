// Guide advances only on a fresh matching key press at the judgement line.
`timescale 1ns/1ps
module guide_controller #(
 parameter integer CLK_HZ=50_000_000,
 parameter integer PREPARE_MS=3000, ANIM_MS=16, HIT_MS=96,
 parameter integer NEXT_DELAY_STEPS=20, SONG_LENGTH=14, TRAIL_STEP_MS=48,
 parameter [8:0] SPAWN_Y=9'd184, WAIT_Y=9'd264, NEXT_WAIT_Y=9'd200,
 parameter [8:0] DROP_PIXELS=9'd2, MIN_SEPARATION=9'd64
)(input wire clk,rst_n,input wire [14:0] keys,input wire key16,
 output wire [63:0] display_state);
function integer bits_needed;
 input integer n;integer v;
 begin v=n-1;bits_needed=1;while(v>1)begin bits_needed=bits_needed+1;v=v>>1;end end
endfunction
localparam integer MS_CYCLES=(CLK_HZ/1000<1)?1:CLK_HZ/1000;
localparam integer MW=bits_needed(MS_CYCLES),PW=bits_needed(PREPARE_MS),
 AW=bits_needed(ANIM_MS),HW=bits_needed(HIT_MS),NW=bits_needed(NEXT_DELAY_STEPS+1),
 TW=bits_needed(TRAIL_STEP_MS);
localparam [2:0] NORMAL=0,PREPARE=1,FALLING=2,WAIT_KEY=3,HIT=4,COMPLETE=5;
reg [MW-1:0] ms_div;
wire ms_tick=(ms_div==MS_CYCLES-1);
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)ms_div<=0;
 else if(ms_tick || toggle_mode)ms_div<=0;
 else ms_div<=ms_div+1'b1;
end
reg [2:0] phase;
reg [3:0] index;
reg [PW-1:0] prepare_count;
reg [AW-1:0] anim_count;
reg [HW-1:0] hit_count;
reg [NW-1:0] next_delay;
reg [8:0] current_y,next_y;
reg current_valid,next_valid;
reg [2:0] current_trail_age,next_trail_age;
reg [TW-1:0] current_trail_timer,next_trail_timer;
reg key16_previous,key16_ready,key16_armed;
reg [14:0] keys_previous;
wire [14:0] presses=keys & ~keys_previous;
wire toggle_mode=key16_ready && key16_armed && key16_previous && !key16;
wire [3:0] current_key,next_key;
wire current_rom_valid,next_rom_valid;
wire [3:0] next_address=index+4'd1;
guide_song_rom u_current(index,current_key,current_rom_valid);
guide_song_rom u_next(next_address,next_key,next_rom_valid);
wire have_next=next_address<SONG_LENGTH && next_rom_valid;
wire animation_tick=ms_tick && anim_count==ANIM_MS-1;
function [9:0] key_center;
 input [3:0] k;
 begin case(k)
  0:key_center=57;1:key_center=147;2:key_center=236;
  3:key_center=314;4:key_center=400;5:key_center=487;
  6:key_center=564;7:key_center=652;8:key_center=742;
  9:key_center=98;10:key_center=197;11:key_center=352;
  12:key_center=449;13:key_center=602;14:key_center=701;
  default:key_center=57;
 endcase end
endfunction
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin
  key16_previous<=0;key16_ready<=0;key16_armed<=0;keys_previous<=0;
 end else begin
  key16_previous<=key16;keys_previous<=keys;
  if(!key16)key16_ready<=1;
  if(key16_ready && key16 && !key16_previous)key16_armed<=1;
  else if(toggle_mode)key16_armed<=0;
 end
end
always @(posedge clk or negedge rst_n)begin
 if(!rst_n)begin
  phase<=NORMAL;index<=0;prepare_count<=0;anim_count<=0;hit_count<=0;
  next_delay<=0;current_y<=SPAWN_Y;next_y<=SPAWN_Y;
  current_valid<=0;next_valid<=0;
  current_trail_age<=7;next_trail_age<=7;current_trail_timer<=0;next_trail_timer<=0;
 end else if(toggle_mode)begin
  phase<=(phase==NORMAL)?PREPARE:NORMAL;
  index<=0;prepare_count<=0;anim_count<=0;hit_count<=0;next_delay<=0;
  current_y<=SPAWN_Y;next_y<=SPAWN_Y;current_valid<=0;next_valid<=0;
  current_trail_age<=7;next_trail_age<=7;current_trail_timer<=0;next_trail_timer<=0;
 end else begin
  if(ms_tick)begin
   if(current_trail_age!=7)begin
    if(current_trail_timer==TRAIL_STEP_MS-1)begin
     current_trail_age<=current_trail_age+1'b1;current_trail_timer<=0;
    end else current_trail_timer<=current_trail_timer+1'b1;
   end
   if(next_trail_age!=7)begin
    if(next_trail_timer==TRAIL_STEP_MS-1)begin
     next_trail_age<=next_trail_age+1'b1;next_trail_timer<=0;
    end else next_trail_timer<=next_trail_timer+1'b1;
   end
  end
  if(phase==FALLING || phase==WAIT_KEY)begin
   if(ms_tick)begin
    if(animation_tick)anim_count<=0;
    else anim_count<=anim_count+1'b1;
   end
  end else anim_count<=0;
  case(phase)
   PREPARE:if(ms_tick)begin
    if(prepare_count==PREPARE_MS-1)begin
     phase<=FALLING;current_valid<=1;prepare_count<=0;
    end else prepare_count<=prepare_count+1'b1;
   end
   FALLING,WAIT_KEY:begin
    if(animation_tick)begin
     if(current_y>=WAIT_Y-DROP_PIXELS)begin current_y<=WAIT_Y;phase<=WAIT_KEY;end
     else current_y<=current_y+DROP_PIXELS;
     if(current_y<WAIT_Y)begin current_trail_age<=0;current_trail_timer<=0;end
     if(have_next)begin
      if(next_delay<NEXT_DELAY_STEPS)next_delay<=next_delay+1'b1;
      if(!next_valid)begin
       if(next_delay>=NEXT_DELAY_STEPS-1 && current_y>=SPAWN_Y+MIN_SEPARATION)begin
        next_valid<=1;next_y<=SPAWN_Y;
       end
      end else if(next_y<NEXT_WAIT_Y && next_y+DROP_PIXELS+MIN_SEPARATION<=current_y)begin
       if(next_y>=NEXT_WAIT_Y-DROP_PIXELS)next_y<=NEXT_WAIT_Y;
       else next_y<=next_y+DROP_PIXELS;
       next_trail_age<=0;next_trail_timer<=0;
      end
     end
    end
    if(phase==WAIT_KEY && current_rom_valid && presses[current_key])begin
     phase<=HIT;hit_count<=0;
    end
   end
   HIT:if(ms_tick)begin
    if(hit_count==HIT_MS-1)begin
     hit_count<=0;
     if(index==SONG_LENGTH-1)begin
      phase<=COMPLETE;current_valid<=0;next_valid<=0;
      current_trail_age<=7;next_trail_age<=7;
     end else begin
      index<=index+4'd1;phase<=FALLING;current_y<=next_y;
      current_valid<=1;next_y<=SPAWN_Y;next_valid<=0;next_delay<=0;
      current_trail_age<=next_trail_age;current_trail_timer<=next_trail_timer;
      next_trail_age<=7;next_trail_timer<=0;
     end
    end else hit_count<=hit_count+1'b1;
   end
   default:begin end
  endcase
 end
end
reg [1:0] countdown;
always @* begin
 if(phase==HIT)begin
  if(hit_count<HIT_MS/4)countdown=0;
  else if(hit_count<HIT_MS/2)countdown=1;
  else if(hit_count<(HIT_MS*3)/4)countdown=2;
  else countdown=3;
 end
 else if(prepare_count<1000)countdown=3;
 else if(prepare_count<2000)countdown=2;
 else countdown=1;
end
assign display_state={next_trail_age,current_trail_age,key_center(next_key),key_center(current_key),countdown,
 next_valid,current_valid,next_y,current_y,next_key,current_key,index,phase,(phase!=NORMAL)};
// synthesis translate_off
initial begin
 if(SONG_LENGTH<1 || SONG_LENGTH>14 || NEXT_DELAY_STEPS<1 || ANIM_MS<1 || HIT_MS<4 || PREPARE_MS<1 || TRAIL_STEP_MS<1)
  $fatal(1,"Unsupported Guided Play parameters");
end
// synthesis translate_on
endmodule
