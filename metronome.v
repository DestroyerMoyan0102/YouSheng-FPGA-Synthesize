`timescale 1ns/1ps
module metronome #(parameter integer CLK_HZ=50_000_000)(
 input wire clk,rst_n,tick,input wire [1:0] mode,input wire mix_ready,
 output wire signed [15:0] pcm,output wire quiet,
 output reg [1:0] active_mode,beat_index,output reg beat_event);
 localparam integer PERIOD80=(CLK_HZ*3)/4, PERIOD120=CLK_HZ/2;
 reg [31:0] beat_count;reg [1:0] timer_mode;
 reg pending,accent;reg [31:0] phase;
 reg [15:0] envelope;reg attacking;
 wire changing=(active_mode!=mode);
 wire [31:0] period=(active_mode==1)?PERIOD80:PERIOD120;
 assign quiet=(envelope==0 && !pending);
 always @(posedge clk or negedge rst_n)
  if(!rst_n) active_mode<=0;
  else if(tick && changing && envelope==0 && (mode==0 || mix_ready)) active_mode<=mode;
 always @(posedge clk or negedge rst_n)
  if(!rst_n) begin timer_mode<=0;beat_count<=0;beat_index<=0;beat_event<=0;end
  else begin
   beat_event<=0;
   if(changing || active_mode==0) begin beat_count<=0;timer_mode<=0;beat_index<=0;end
   else if(timer_mode!=active_mode) begin
    timer_mode<=active_mode;beat_count<=period-1;beat_index<=0;beat_event<=1;
   end else if(beat_count==0) begin
    beat_count<=period-1;beat_index<=beat_index+1'b1;beat_event<=1;
   end else beat_count<=beat_count-1'b1;
  end
 always @(posedge clk or negedge rst_n)
  if(!rst_n) begin pending<=0;accent<=0;phase<=0;envelope<=0;attacking<=0;end
  else begin
   if(beat_event && !changing) pending<=1;
   if(changing) pending<=0;
   if(tick) begin
    if(changing) begin
     attacking<=0;
     envelope<=(envelope>256)?envelope-16'd256:16'd0;
    end else if(pending) begin
     pending<=0;accent<=(beat_index==0);phase<=0;envelope<=0;attacking<=1;
    end else begin
     phase<=phase+(accent?32'd77405619:32'd46179488);
     if(attacking) begin
      if(envelope>=32256) begin envelope<=32768;attacking<=0;end
      else envelope<=envelope+16'd512;
     end else if(envelope!=0)
      envelope<=envelope-(accent?(envelope>>9):(envelope>>8))-16'd1;
    end
   end
  end
 wire signed [15:0] fundamental,harmonic;
 metro_sine s1(phase[31:24],fundamental);
 metro_sine s2(phase[30:23],harmonic);
 wire signed [16:0] tone=accent?
  (($signed(fundamental)>>>3)+($signed(harmonic)>>>5)):
  (($signed(fundamental)>>>4)+($signed(harmonic)>>>7));
 reg signed [32:0] env_product;
 always @(posedge clk or negedge rst_n)
  if(!rst_n)env_product<=0;
  else env_product<=tone*$signed({1'b0,envelope});
 assign pcm=env_product>>>15;
endmodule
