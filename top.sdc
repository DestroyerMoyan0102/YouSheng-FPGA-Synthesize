# LCD output delays are engineering budgets, pending panel timing measurement.
# CDC exceptions apply only to synchronizer first stages.
create_clock -name sys_clk -period 20 -waveform {0 10} [get_ports {sys_clk}]
create_generated_clock -name pixel_clk -source [get_ports {sys_clk}] -multiply_by 333 -divide_by 500 [get_pins {u_pll/*/PLLA_inst/CLKOUT0}]
create_generated_clock -name lcd_dclk -source [get_pins {u_pll/*/PLLA_inst/CLKOUT0}] -divide_by 1 -invert [get_ports {lcd_clk}]
set_output_delay -clock lcd_dclk -max 4 [get_ports {lcd_r[7:2] lcd_g[7:2] lcd_b[7:2] lcd_de lcd_hs lcd_vs}]
set_output_delay -clock lcd_dclk -min -2 [get_ports {lcd_r[7:2] lcd_g[7:2] lcd_b[7:2] lcd_de lcd_hs lcd_vs}]
set_false_path -from [get_regs {*u_ui/u_status/publish_toggle*}] -to [get_regs {*u_ui/u_status/req_meta*}]
set_false_path -from [get_regs {*u_ui/u_status/ack_toggle*}] -to [get_regs {*u_ui/u_status/ack_meta*}]
set_false_path -from [get_regs {*u_ui/u_status/payload_hold*}] -to [get_regs {*u_ui/u_status/frame_data*}]
set_false_path -from [get_regs {*u_ui/u_wave/publish_toggle*}] -to [get_regs {*u_ui/u_wave/req_meta*}]
set_false_path -from [get_regs {*u_ui/u_wave/ack_toggle*}] -to [get_regs {*u_ui/u_wave/ack_meta*}]
set_false_path -from [get_regs {*u_ui/u_wave/bank_scale0* *u_ui/u_wave/bank_scale1*}] -to [get_regs {*u_ui/u_wave/scale*}]
set_false_path -to [get_regs {*u_ui_reset/sys_release_0* *u_ui_reset/pix_release_0*}]
