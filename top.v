`timescale 1ns/1ps
module top #(parameter integer EC11_EDGES_PER_DETENT=4,
             parameter integer EC11_REVERSE=0,
             parameter [1:0] EC11_DETENT_AB=2'b11,
             parameter integer EC11_AB_FILTER_US=100,
             parameter integer EC11_SW_DEBOUNCE_MS=10,
             parameter SELFTEST=0,
             parameter [25:0] POR_END=26'd33_554_431,
             parameter integer BUTTON_DEBOUNCE_MS=10,
             parameter [6:0] VEL_DEF=7'd100,
             parameter [4:0] KB_PRESS_TH=5'd0, KB_REL_TH=5'd3)(
 input wire sys_clk, output wire touch_scl, input wire touch_sdo,
 output wire hp_bck,hp_ws,hp_din,pa_en,
 input wire key_vol_up,key_vol_dn,key_timbre_n,key_metronome_n,
 input wire ec11_clk,ec11_dt,ec11_sw_n,
 output wire lcd_hs,lcd_vs,lcd_de,lcd_clk,lcd_bl,
 output wire [7:0] lcd_r,lcd_g,lcd_b);
 wire requested_nes, core_rst_n;
 wire [1:0] sound_mode,metro_mode;
assign requested_nes=sound_mode[1];
wire [14:0] ui_keys; wire [3:0] ui_vol_code; wire [9:0] ui_lat; wire [2:0] ui_pan;
wire [1:0] ui_octave; wire ui_timbre,ui_sample_tick;
wire metro_step;
 wire signed [15:0] ui_pcm;
 wire ui_key16;
 wire [1:0] requested_octave;
 ec11_octave #(.CLK_HZ(50_000_000),.AB_FILTER_US(EC11_AB_FILTER_US),
 .SW_DEBOUNCE_MS(EC11_SW_DEBOUNCE_MS),.EDGES_PER_DETENT(EC11_EDGES_PER_DETENT),
 .REVERSE(EC11_REVERSE),.DETENT_AB(EC11_DETENT_AB))
 u_octave(.clk(sys_clk),.rst_n(core_rst_n),.enc_clk(ec11_clk),.enc_dt(ec11_dt),
 .enc_sw_n(ec11_sw_n),.octave_index(requested_octave),.step_event(),
 .step_up(),.home_event(),.invalid_transition());
audio_buttons #(.CLK_HZ(50_000_000),.DEBOUNCE_MS(BUTTON_DEBOUNCE_MS))
u_audio_buttons(sys_clk,core_rst_n,key_timbre_n,metro_step,sound_mode,metro_mode);
 instrument_core #(.POR_END(POR_END)) u_core(.sys_clk(sys_clk),.touch_scl(touch_scl),
 .touch_sdo(touch_sdo),.hp_bck(hp_bck),.hp_ws(hp_ws),.hp_din(hp_din),
 .pa_en(pa_en),.key_vol_up(key_vol_up),.key_vol_dn(key_vol_dn),
 .metro_key_n(key_metronome_n),.metro_step(metro_step),
 .vibrato_select(sound_mode[0]),.metronome_mode(metro_mode),
 .octave_select(requested_octave),.timbre_select(requested_nes),.core_rst_n(core_rst_n),
 .ui_keys(ui_keys),.ui_vol_code(ui_vol_code),.ui_lat(ui_lat),.ui_pan(ui_pan),
 .ui_octave(ui_octave),.ui_timbre(ui_timbre),
 .ui_sample_tick(ui_sample_tick),.ui_pcm(ui_pcm),.ui_key16(ui_key16));
 defparam u_core.SELFTEST=SELFTEST;
 defparam u_core.VEL_DEF=VEL_DEF;
 defparam u_core.KB_PRESS_TH=KB_PRESS_TH;
 defparam u_core.KB_REL_TH=KB_REL_TH;
 wire pclk,pll_lock,sys_ui_rst_n,pix_rst_n;
 Gowin_PLL u_pll(.clkin(sys_clk),.mdclk(sys_clk),.clkout0(pclk),.lock(pll_lock));
 ui_reset u_ui_reset(sys_clk,pclk,core_rst_n,pll_lock,sys_ui_rst_n,pix_rst_n);
lcd_ui u_ui(.sclk(sys_clk),.srst_n(sys_ui_rst_n),.pclk(pclk),.prst_n(pix_rst_n),
 .keys(ui_keys),.vol_code(ui_vol_code),.lat(ui_lat),.pan(ui_pan),
 .octave(ui_octave),.timbre(ui_timbre),
 .pcm(ui_pcm),.sample_tick(ui_sample_tick),.key16(ui_key16),.lcd_hs(lcd_hs),.lcd_vs(lcd_vs),.lcd_de(lcd_de),
 .lcd_r(lcd_r),.lcd_g(lcd_g),.lcd_b(lcd_b));
 assign lcd_clk=~pclk;
 assign lcd_bl=1'b1;
endmodule

