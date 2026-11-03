// Frame-boundary commit keeps the pixel-domain UI snapshot coherent.
module ui_mailbox #(parameter WIDTH=160)(
 input wire sclk,srst_n,pclk,prst_n,frame_start,
 input wire [WIDTH-1:0] live_data,
 output reg [WIDTH-1:0] frame_data);
(* syn_preserve=1, syn_keep=1 *) reg [WIDTH-1:0] payload_hold;
(* syn_preserve=1, syn_keep=1 *) reg publish_toggle,ack_toggle;
(* syn_preserve=1, syn_keep=1 *) reg req_meta,req_sync,ack_meta,ack_sync;
reg sent_once;
always @(posedge sclk or negedge srst_n) begin
 if(!srst_n) begin ack_meta<=0;ack_sync<=0;end
 else begin ack_meta<=ack_toggle;ack_sync<=ack_meta;end
end
always @(posedge sclk or negedge srst_n) begin
 if(!srst_n) begin payload_hold<=0;publish_toggle<=0;sent_once<=0;end
 else if(ack_sync==publish_toggle && (!sent_once || live_data!=payload_hold)) begin
  payload_hold<=live_data;publish_toggle<=~publish_toggle;sent_once<=1;
 end
end
always @(posedge pclk or negedge prst_n) begin
 if(!prst_n) begin req_meta<=0;req_sync<=0;end
 else begin req_meta<=publish_toggle;req_sync<=req_meta;end
end
always @(posedge pclk or negedge prst_n) begin
 if(!prst_n) begin frame_data<=0;ack_toggle<=0;end
 else if(frame_start && req_sync!=ack_toggle) begin
  frame_data<=payload_hold;ack_toggle<=req_sync;
 end
end
endmodule
