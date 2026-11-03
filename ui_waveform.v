// Dual-clock banks keep PCM capture separate from the displayed frame.
module ui_waveform(input wire sclk,srst_n,pclk,prst_n,frame_start,
 input wire sample_tick,input wire signed [15:0] pcm,
 input wire [8:0] read_addr,output wire [31:0] read_data,
 output reg [2:0] scale,output reg valid);
reg [31:0] bank0[0:383];
reg [31:0] bank1[0:383];
reg [31:0] q0,q1;
reg capture_bank,front_bank,waiting;
reg [8:0] col;
reg [2:0] sample_count;
reg signed [15:0] low_s,high_s,last_s;
reg [15:0] peak;
(* syn_preserve=1,syn_keep=1 *) reg [2:0] bank_scale0,bank_scale1;
(* syn_preserve=1,syn_keep=1 *) reg publish_toggle,ack_toggle;
(* syn_preserve=1,syn_keep=1 *) reg req_meta,req_sync,ack_meta,ack_sync;
wire [15:0] magnitude=pcm[15]?(~pcm+16'd1):pcm;
wire first_sample=(col==0 && sample_count==0);
wire signed [15:0] cur_low=first_sample?pcm:((pcm<low_s)?pcm:low_s);
wire signed [15:0] cur_high=first_sample?pcm:((pcm>high_s)?pcm:high_s);
wire [15:0] cur_peak=(magnitude>peak)?magnitude:peak;
function [2:0] choose_scale;
 input [15:0] pk;
 begin
  if(pk<256)choose_scale=6;else if(pk<512)choose_scale=5;
  else if(pk<1024)choose_scale=4;else if(pk<2048)choose_scale=3;
  else if(pk<4096)choose_scale=2;else if(pk<8192)choose_scale=1;
  else choose_scale=0;
 end
endfunction
always @(posedge sclk or negedge srst_n) begin
 if(!srst_n)begin ack_meta<=0;ack_sync<=0;end
 else begin ack_meta<=ack_toggle;ack_sync<=ack_meta;end
end
wire write_en=!waiting && sample_tick && sample_count==7 && srst_n;
always @(posedge sclk) begin
 if(write_en) begin
  if(capture_bank)bank1[col]<={cur_low,cur_high};
  else bank0[col]<={cur_low,cur_high};
 end
end
always @(posedge sclk or negedge srst_n) begin
 if(!srst_n) begin
  capture_bank<=1;waiting<=0;col<=0;sample_count<=0;
  low_s<=0;high_s<=0;last_s<=0;peak<=0;
  publish_toggle<=0;bank_scale0<=0;bank_scale1<=0;
 end else if(waiting) begin
  if(ack_sync==publish_toggle)begin
   capture_bank<=~capture_bank;waiting<=0;col<=0;sample_count<=0;
   low_s<=last_s;high_s<=last_s;peak<=0;
  end
 end else if(sample_tick) begin
  last_s<=pcm;peak<=cur_peak;
  if(sample_count==7)begin
   sample_count<=0;low_s<=pcm;high_s<=pcm;
   if(col==383)begin
    if(capture_bank)bank_scale1<=choose_scale(cur_peak);
    else bank_scale0<=choose_scale(cur_peak);
    publish_toggle<=~publish_toggle;waiting<=1;
   end else col<=col+1'b1;
  end else begin sample_count<=sample_count+1'b1;low_s<=cur_low;high_s<=cur_high;end
 end
end
always @(posedge pclk)begin
 q0<=bank0[read_addr];q1<=bank1[read_addr];
end
assign read_data=front_bank?q1:q0;
always @(posedge pclk or negedge prst_n) begin
 if(!prst_n)begin req_meta<=0;req_sync<=0;end
 else begin req_meta<=publish_toggle;req_sync<=req_meta;end
end
always @(posedge pclk or negedge prst_n) begin
 if(!prst_n)begin front_bank<=0;ack_toggle<=0;valid<=0;scale<=0;end
 else if(frame_start && req_sync!=ack_toggle)begin
  front_bank<=req_sync;ack_toggle<=req_sync;valid<=1;
  scale<=req_sync?bank_scale1:bank_scale0;
 end
end
endmodule
