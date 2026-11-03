module lcd_ui #(parameter TEST_MODE=0)(
 input wire sclk,srst_n,pclk,prst_n,
 input wire [14:0] keys,input wire [3:0] vol_code,
 input wire [1:0] octave,input wire timbre,input wire signed [15:0] pcm,
 input wire sample_tick,output wire lcd_hs,lcd_vs,lcd_de,
 output wire [7:0] lcd_r,lcd_g,lcd_b,input wire key16,
 input wire [9:0] lat,input wire [2:0] pan);
wire [9:0] x,y;wire hs,vs,de,frame_start;
lcd_scan u_scan(pclk,prst_n,x,y,hs,vs,de,frame_start);
wire [175:0] live_state;wire [239:0] frame_bundle;
wire [175:0] frame_state=frame_bundle[175:0];
wire [63:0] live_guide,frame_guide;
assign frame_guide=frame_bundle[239:176];
guide_controller u_guide(sclk,srst_n,keys,key16,live_guide);
ui_state u_state(sclk,srst_n,keys,vol_code,lat,pan,octave,timbre,live_state);
ui_mailbox #(.WIDTH(240)) u_status(sclk,srst_n,pclk,prst_n,frame_start,{live_guide,live_state},frame_bundle);
wire [8:0] wave_addr;
wire [31:0] wave_data;wire [2:0] wave_scale;wire wave_valid;
ui_waveform u_wave(.sclk(sclk),.srst_n(srst_n),.pclk(pclk),.prst_n(prst_n),
 .frame_start(frame_start),.sample_tick(sample_tick),.pcm(pcm),.read_addr(wave_addr),
 .read_data(wave_data),.scale(wave_scale),.valid(wave_valid));
ui_renderer #(.TEST_MODE(TEST_MODE)) u_render(.pclk(pclk),.rst_n(prst_n),
 .scan_x(x),.scan_y(y),.hs(hs),.vs(vs),.de(de),.state(frame_state),
 .wave_addr(wave_addr),.wave_data(wave_data),.wave_scale(wave_scale),.wave_valid(wave_valid),
 .lcd_hs(lcd_hs),.lcd_vs(lcd_vs),.lcd_de(lcd_de),.lcd_r(lcd_r),.lcd_g(lcd_g),.lcd_b(lcd_b),.guide_data(frame_guide));
endmodule
