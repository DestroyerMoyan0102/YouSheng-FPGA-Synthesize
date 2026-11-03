// Asynchronous assertion; synchronous release in each UI clock domain.
module ui_reset(input wire sys_clk,pclk,core_rst_n,pll_lock,
 output wire sys_ui_rst_n,pix_rst_n);
wire arst_n=core_rst_n & pll_lock;
(* syn_preserve=1, syn_keep=1 *) reg [2:0] sys_release;
(* syn_preserve=1, syn_keep=1 *) reg [2:0] pix_release;
always @(posedge sys_clk or negedge arst_n)
 if(!arst_n) sys_release<=0; else sys_release<={sys_release[1:0],1'b1};
always @(posedge pclk or negedge arst_n)
 if(!arst_n) pix_release<=0; else pix_release<={pix_release[1:0],1'b1};
assign sys_ui_rst_n=sys_release[2];
assign pix_rst_n=pix_release[2];
endmodule
