// State bit offsets must match ui_state.v.
module ui_renderer #(parameter TEST_MODE=0)(
 input wire pclk,rst_n,input wire [9:0] scan_x,scan_y,input wire hs,vs,de,
 input wire [175:0] state,output wire [8:0] wave_addr,
 input wire [31:0] wave_data,input wire [2:0] wave_scale,input wire wave_valid,
 output reg lcd_hs,lcd_vs,lcd_de,output reg [7:0] lcd_r,lcd_g,lcd_b,
 input wire [63:0] guide_data);
reg [9:0] x,y;reg hs0,vs0,de0;
always @(posedge pclk or negedge rst_n)begin
 if(!rst_n)begin x<=0;y<=0;hs0<=1;vs0<=1;de0<=0;end
 else begin x<=scan_x;y<=scan_y;hs0<=hs;vs0<=vs;de0<=de;end
end
wire [14:0] keys=state[14:0];wire [1:0] octave=state[16:15];
wire timbre=state[17];wire [6:0] volume_pct=state[24:18];
wire [9:0] slider_x=(state[151:142]>=186)?state[151:142]:10'd186;
wire [5:0] key_count=state[30:25];
wire [23:0] note_text=state[54:31];wire [79:0] freq_text=state[134:55];
wire [9:0] lat_x10=state[161:152];
wire [2:0] pan_mode=state[164:162];
wire guide_mode=guide_data[0];wire [2:0] guide_phase=guide_data[3:1];
wire [3:0] current_key=guide_data[11:8],next_key=guide_data[15:12];
wire [9:0] current_y={1'b0,guide_data[24:16]},next_y={1'b0,guide_data[33:25]};
wire current_valid=guide_data[34],next_valid=guide_data[35];
wire [1:0] countdown=guide_data[37:36];
function [9:0] block_left;
 input [3:0] k;
 begin case(k)
 0:block_left=19;1:block_left=99;2:block_left=198;
 3:block_left=278;4:block_left=354;5:block_left=450;
 6:block_left=528;7:block_left=604;8:block_left=703;
 9:block_left=72;10:block_left=171;11:block_left=326;
 12:block_left=423;13:block_left=576;14:block_left=675;
 default:block_left=19;endcase end
endfunction
function [9:0] block_right;
 input [3:0] k;
 begin case(k)
 0:block_right=95;1:block_right=195;2:block_right=275;
 3:block_right=351;4:block_right=447;5:block_right=525;
 6:block_right=601;7:block_right=700;8:block_right=781;
 9:block_right=125;10:block_right=223;11:block_right=378;
 12:block_right=476;13:block_right=628;14:block_right=728;
 default:block_right=95;endcase end
endfunction
wire [9:0] current_x=guide_data[47:38],next_x=guide_data[57:48];
wire [9:0] current_top=current_y-10'd20,next_top=next_y-10'd20;
wire [9:0] current_left=block_left(current_key),current_right=block_right(current_key);
wire [9:0] next_left=block_left(next_key),next_right=block_right(next_key);
wire [2:0] current_trail_age=guide_data[60:58],next_trail_age=guide_data[63:61];
wire [1:0] hit_stage=countdown;
wire [9:0] current_distance=current_top-y,next_distance=next_top-y;
wire [4:0] current_trail_level={2'd0,current_trail_age}+{1'b0,current_distance[6:3]};
wire [4:0] next_trail_level={2'd0,next_trail_age}+{1'b0,next_distance[6:3]}+5'd1;
wire grid_here=(x>=24 && x<=775 && y>=177 && y<=288) &&
 (x[5:0]==16 || y==184 || y==210 || y==236 || y==262 || y==288);
function [23:0] block_gradient;
 input [9:0] local_y;input preview;
 begin case(local_y[5:0])
 0:block_gradient=preview?24'hBC90EB:24'hD2A8FF;
 1:block_gradient=preview?24'hBB8DEB:24'hD1A4FF;
 2:block_gradient=preview?24'hBA8AEB:24'hD0A0FF;
 3:block_gradient=preview?24'hB987EB:24'hCF9CFF;
 4:block_gradient=preview?24'hB884EA:24'hCE98FE;
 5:block_gradient=preview?24'hB781EA:24'hCD94FE;
 6:block_gradient=preview?24'hB67EEA:24'hCC90FE;
 7:block_gradient=preview?24'hB57BEA:24'hCB8CFE;
 8:block_gradient=preview?24'hB478E9:24'hCA88FD;
 9:block_gradient=preview?24'hB375E9:24'hC984FD;
 10:block_gradient=preview?24'hB272E9:24'hC880FD;
 11:block_gradient=preview?24'hB16FE9:24'hC77CFD;
 12:block_gradient=preview?24'hB06CE8:24'hC678FC;
 13:block_gradient=preview?24'hAF69E8:24'hC574FC;
 14:block_gradient=preview?24'hAE66E8:24'hC470FC;
 15:block_gradient=preview?24'hAD63E8:24'hC36CFC;
 16:block_gradient=preview?24'hAC60E7:24'hC268FB;
 17:block_gradient=preview?24'hAB5DE7:24'hC164FB;
 18:block_gradient=preview?24'hAA5AE7:24'hC060FB;
 19:block_gradient=preview?24'hA957E7:24'hBF5CFB;
 20:block_gradient=preview?24'hA854E6:24'hBE58FA;
 21:block_gradient=preview?24'hA751E6:24'hBD54FA;
 22:block_gradient=preview?24'hA64EE6:24'hBC50FA;
 23:block_gradient=preview?24'hA54BE6:24'hBB4CFA;
 24:block_gradient=preview?24'hA448E5:24'hBA48F9;
 25:block_gradient=preview?24'hA345E5:24'hB944F9;
 26:block_gradient=preview?24'hA242E5:24'hB840F9;
 27:block_gradient=preview?24'hA13FE5:24'hB73CF9;
 28:block_gradient=preview?24'hA03CE4:24'hB638F8;
 29:block_gradient=preview?24'h9F39E4:24'hB534F8;
 30:block_gradient=preview?24'h9E36E4:24'hB430F8;
 31:block_gradient=preview?24'h9D33E4:24'hB32CF8;
 32:block_gradient=preview?24'h9C30E3:24'hB228F7;
 33:block_gradient=preview?24'h9B2DE3:24'hB124F7;
 34:block_gradient=preview?24'h9A2AE3:24'hB020F7;
 35:block_gradient=preview?24'h9927E3:24'hAF1CF7;
 default:block_gradient=preview?24'h9927E3:24'hAF1CF7;
 endcase end
endfunction
function [23:0] trail_color;
 input [4:0] level;
 begin case(level)
 0:trail_color=24'h5C238C;1:trail_color=24'h50207A;
 2:trail_color=24'h421A66;3:trail_color=24'h341551;
 4:trail_color=24'h28103E;5:trail_color=24'h1E0C30;
 6:trail_color=24'h140A22;default:trail_color=24'h021222;
 endcase end
endfunction
function [6:0] guide_letter;
 input [3:0] k;
 begin case(k)
 0,7:guide_letter="C";1,8:guide_letter="D";2:guide_letter="E";
 3:guide_letter="F";4:guide_letter="G";5:guide_letter="A";6:guide_letter="B";
 default:guide_letter="?";endcase end
endfunction
function [23:0] purple;
 input [23:0] c;
 begin case(c)
 24'h073047:purple=24'h28143E;24'h147293:purple=24'h68469A;
 24'h063348:purple=24'h2A183F;24'h08BCD9:purple=24'hAB6DE5;
 24'h075A87:purple=24'h562D83;24'h8FF5FF:purple=24'hE1C0FF;
 24'h18BFEA:purple=24'hB475EC;24'h06304C:purple=24'h321C50;
 24'h15658D:purple=24'h67458C;24'h2EC9F7:purple=24'hB980F0;
 24'h4BE4F7:purple=24'hD0A1FF;24'h075B95:purple=24'h582C8F;
 24'h16BCFA:purple=24'hB26BF0;24'hAEF6FF:purple=24'hE8CAFF;
 24'h147DD6:purple=24'h8A4AD1;24'h1260AD:purple=24'h6937A8;
 24'h073149:purple=24'h251537;24'h49E9FF:purple=24'hD7A5FF;
 24'h78EEFF:purple=24'hD6B0FF;24'h5D91D7:purple=24'hA384C9;
 24'h72B4E8:purple=24'hBE92E5;24'h79A9EE:purple=24'hB998E9;
 24'h699BDD:purple=24'hA78ACC;24'h789DE5:purple=24'hAC8AD5;
 24'h26E7F1:purple=24'hD3A0FF;24'h16558A:purple=24'h593283;
 24'h8BEFFF:purple=24'hDABAFF;24'h68EFFF:purple=24'hD5A8FF;
 24'h0A7EA3:purple=24'h79419F;24'h075570:purple=24'h4D2B70;
 default:begin
  if(c[23:16]==8'h39 && c[15:8]>=8'hB9 && c[15:8]<=8'hC0 && c[7:0]==8'hF8)
   purple={8'hB8,c[15:8]-8'h39,8'hF8};
  else purple=c;
 end
 endcase end
endfunction
function box;
 input [9:0] px,py,l,t,r,b;
 begin box=(px>=l && px<=r && py>=t && py<=b);end
endfunction
function rounded;
 input [9:0] px,py,l,t,r,b;input [3:0] rad;
 begin
 rounded=box(px,py,l,t,r,b) &&
  ((px>=l+rad)||(py>=t+rad)||(px-l+py-t>=rad)) &&
  ((px<=r-rad)||(py>=t+rad)||(r-px+py-t>=rad)) &&
  ((px>=l+rad)||(py<=b-rad)||(px-l+b-py>=rad)) &&
  ((px<=r-rad)||(py<=b-rad)||(r-px+b-py>=rad));
 end
endfunction
reg [23:0] fx_color;reg fx_valid;
always @* begin
 fx_color=0;fx_valid=0;
 if(guide_mode && guide_phase!=1 && guide_phase!=5 &&
    box(x,y,18,158,781,288) && y!=280 && y!=281)begin
  if(next_valid && next_trail_age<7 && y>=164 && y<next_top && y+56>=next_top &&
     x>=next_left && x<=next_right && next_trail_level<7 && !grid_here)begin
   fx_color=trail_color(next_trail_level);fx_valid=1;
   if(x==next_left+3 || x==next_right-3)
    fx_color=trail_color(next_trail_level==0?5'd0:next_trail_level-5'd1);
  end
  if(current_valid && current_trail_age<7 && y>=164 && y<current_top && y+56>=current_top &&
     x>=current_left && x<=current_right && current_trail_level<7 && !grid_here)begin
   fx_color=trail_color(current_trail_level);fx_valid=1;
   if(x==current_left+3 || x==current_right-3)
    fx_color=trail_color(current_trail_level==0?5'd0:current_trail_level-5'd1);
  end
  if(next_valid && rounded(x,y,next_left-3,next_top-3,next_right+3,next_y+18,7))begin fx_color=24'h1D102B;fx_valid=1;end
  if(next_valid && rounded(x,y,next_left-1,next_top-1,next_right+1,next_y+16,5))begin fx_color=24'h4E2368;fx_valid=1;end
  if(next_valid && rounded(x,y,next_left,next_top,next_right,next_y+15,4))begin fx_color=24'hD6B0FA;fx_valid=1;end
  if(next_valid && rounded(x,y,next_left+1,next_top+1,next_right-1,next_y+14,3))begin
   fx_color=block_gradient(y-next_top,1'b1);fx_valid=1;
  end
  if(current_valid)begin
   if(guide_phase!=4 || hit_stage<2)begin
    if(rounded(x,y,current_left-3,current_top-3,current_right+3,current_y+18,7))begin
     fx_color=(guide_phase==4)?((hit_stage==0)?24'h7A38A8:24'h572370):24'h2A133E;fx_valid=1;end
    if(rounded(x,y,current_left-1,current_top-1,current_right+1,current_y+16,5))begin
     fx_color=(guide_phase==4)?((hit_stage==0)?24'hC38AFA:24'hA35FD8):24'h6D2C92;fx_valid=1;end
    if(rounded(x,y,current_left,current_top,current_right,current_y+15,4))begin
     fx_color=(guide_phase==4)?24'hFFFFFF:24'hF5D8FF;fx_valid=1;end
    if(rounded(x,y,current_left+1,current_top+1,current_right-1,current_y+14,3))begin
     fx_color=(guide_phase==4)?((hit_stage==0)?24'hFFF0FF:24'hDBA0FF):block_gradient(y-current_top,1'b0);fx_valid=1;end
   end else begin
    if(hit_stage==2 && rounded(x,y,current_left-7,current_top-7,current_right+7,current_y+22,8) &&
       !rounded(x,y,current_left-5,current_top-5,current_right+5,current_y+20,6))begin
     fx_color=24'hD9A0FF;fx_valid=1;end
    if(hit_stage==3 && rounded(x,y,current_left-11,current_top-11,current_right+11,current_y+26,10) &&
       !rounded(x,y,current_left-9,current_top-9,current_right+9,current_y+24,8))begin
     fx_color=24'h704493;fx_valid=1;end
    if(hit_stage==2 && (box(x,y,current_left-9,current_y-3,current_left-4,current_y-2) ||
       box(x,y,current_right+4,current_y-3,current_right+9,current_y-2)))begin fx_color=24'hF0CBFF;fx_valid=1;end
   end
  end
 end
end
reg [23:0] base,color_text,background,header_base,parameter_base,plot_base,key_base;
reg [6:0] ch;reg [3:0] crow;
reg [2:0] ccol;reg glyph;integer pos;
reg [31:0] volume_chars;reg [47:0] count_chars;
reg [79:0] lat_chars,pan_chars;
reg [9:0] lat_disp;reg [7:0] l_t,l_o,l_d;
always @* begin
 if(volume_pct>=100)volume_chars="100%";
 else if(volume_pct>=10)volume_chars={8'd48+volume_pct/8'd10,8'd48+volume_pct%8'd10,8'h25,8'h20};
 else volume_chars={8'd48+volume_pct,8'h25,16'h2020};
 if(key_count>=10)count_chars={8'h31,8'd48+key_count-8'd10,32'h202F3135};
 else count_chars={8'h20,8'd48+key_count,32'h202F3135};
 lat_disp=(lat_x10>10'd999)?10'd999:lat_x10;
 if(lat_disp>=10'd100)begin
  l_t=8'd48+lat_disp/8'd100;
  l_o=8'd48+(lat_disp/8'd10)%8'd10;
 end else begin
  l_t=8'h20;
  l_o=8'd48+lat_disp/8'd10;
 end
 l_d=8'd48+lat_disp%8'd10;
 lat_chars={8'h4C,8'h41,8'h54,8'h20,l_t,l_o,8'h2E,l_d,8'h4D,8'h53};
 case(pan_mode)
  3'd1:pan_chars={8'h4C,8'h20,8'h35,8'h30,8'h20,8'h52,8'h20,8'h35,8'h30,8'h20};
  3'd2:pan_chars={8'h4C,8'h20,8'h37,8'h35,8'h20,8'h52,8'h20,8'h32,8'h35,8'h20};
  3'd3:pan_chars={8'h4C,8'h20,8'h32,8'h35,8'h20,8'h52,8'h20,8'h37,8'h35,8'h20};
  3'd4:pan_chars={8'h4C,8'h31,8'h30,8'h30,8'h20,8'h52,8'h20,8'h20,8'h30,8'h20};
  3'd5:pan_chars={8'h4C,8'h20,8'h20,8'h30,8'h20,8'h52,8'h31,8'h30,8'h30,8'h20};
  default:pan_chars={8'h4C,8'h31,8'h30,8'h30,8'h20,8'h52,8'h31,8'h30,8'h30,8'h20};
 endcase
end
wire [9:0] wave_rel=x-10'd16;
assign wave_addr=(x>=16 && x<784)?wave_rel[9:1]:9'd0;
reg [15:0] icon;
always @* begin
 icon=0;
 base=24'h010714;
 if(rounded(x,y,9,10,790,462,9))base=24'h073047;
 if(rounded(x,y,10,11,789,461,8))base=24'h147293;
 if(rounded(x,y,11,12,788,460,7))base=24'h020D1C;

 if(rounded(x,y,15,63,784,145,7))base=24'h063348;
 if(rounded(x,y,16,64,783,144,6))base=24'h08BCD9;
 if(rounded(x,y,17,65,782,143,5))base=24'h021222;
 if(rounded(x,y,15,149,784,296,7))base=24'h063348;
 if(rounded(x,y,16,150,783,295,6))base=24'h08BCD9;
 if(rounded(x,y,17,151,782,294,5))base=24'h021222;
 if(rounded(x,y,13,304,786,457,7))base=24'h063348;
 if(rounded(x,y,14,305,785,456,6))base=24'h08BCD9;
 if(rounded(x,y,15,306,784,455,5))base=24'h021222;
 background=base;
 if(rounded(x,y,21,17,155,57,7))base=(!timbre)?24'h075A87:24'h04243A;
 if(rounded(x,y,22,18,154,56,6))base=(!timbre)?24'h8FF5FF:24'h15658D;
 if(rounded(x,y,23,19,153,55,5))base=(!timbre)?24'h18BFEA:24'h020E1D;
 if(rounded(x,y,24,20,152,54,4))base=(!timbre)?24'h06304C:24'h020E1D;
 if(rounded(x,y,160,17,292,57,7))base=(timbre)?24'h075A87:24'h04243A;
 if(rounded(x,y,161,18,291,56,6))base=(timbre)?24'h8FF5FF:24'h15658D;
 if(rounded(x,y,162,19,290,55,5))base=(timbre)?24'h18BFEA:24'h020E1D;
 if(rounded(x,y,163,20,289,54,4))base=(timbre)?24'h06304C:24'h020E1D;
 header_base=base; base=background;
 if((x==152 || x==408 || x==644) && y>=78 && y<=132)base=24'h8AABC8;
 if(rounded(x,y,186,116,378,126,5))base=24'h192E50;
 if(rounded(x,y,186,116,slider_x,126,5))base=24'h2EC9F7;
 if(box(x,y,187,117,slider_x,119))base=24'h4BE4F7;
 if(box(x,y,slider_x-7,115,slider_x+7,128))base=24'h075B95;
 if(rounded(x,y,slider_x-6,114,slider_x+6,129,5))base=24'hD9FFFF;
 if(rounded(x,y,slider_x-5,115,slider_x+5,128,4))base=24'h16BCFA;
 if(rounded(x,y,436,97,622,128,5))base=24'h395886;
 if(rounded(x,y,437,98,621,127,4))base=24'h020D1C;

 if(octave==2'd0 && rounded(x,y,437,97,483,128,4))base=24'hAEF6FF;
 if(octave==2'd0 && rounded(x,y,438,98,482,127,3))base=24'h147DD6;
 if(octave==2'd0 && rounded(x,y,440,100,480,125,2))base=24'h1260AD;
 if(octave==2'd1 && rounded(x,y,483,97,529,128,4))base=24'hAEF6FF;
 if(octave==2'd1 && rounded(x,y,484,98,528,127,3))base=24'h147DD6;
 if(octave==2'd1 && rounded(x,y,486,100,526,125,2))base=24'h1260AD;
 if(octave==2'd2 && rounded(x,y,529,97,575,128,4))base=24'hAEF6FF;
 if(octave==2'd2 && rounded(x,y,530,98,574,127,3))base=24'h147DD6;
 if(octave==2'd2 && rounded(x,y,532,100,572,125,2))base=24'h1260AD;
 if(octave==2'd3 && rounded(x,y,575,97,621,128,4))base=24'hAEF6FF;
 if(octave==2'd3 && rounded(x,y,576,98,620,127,3))base=24'h147DD6;
 if(octave==2'd3 && rounded(x,y,578,100,618,125,2))base=24'h1260AD;
 parameter_base=base; base=background;
 if(box(x,y,24,177,775,288) && (x[5:0]==16 || y==184 || y==210 || y==236 || y==262 || y==288))base=24'h073149;
 if(box(x,y,19,155,27,157)||box(x,y,19,155,21,164)||
    box(x,y,772,155,780,157)||box(x,y,778,155,780,164)||
    box(x,y,19,286,21,292)||box(x,y,19,290,28,292)||
    box(x,y,778,286,780,292)||box(x,y,771,290,780,292))base=24'h49E9FF;
 if(!guide_mode)begin
  if(rounded(x,y,705,158,773,181,9))base=24'h234969;
  if(rounded(x,y,706,159,772,180,8))base=24'h010D1C;
  if(rounded(x,y,717,165,725,173,4))base=wave_valid?24'h30EBF2:24'h375473;
 end
 if(guide_mode && guide_phase!=1 && guide_phase!=5)begin
  if(box(x,y,24,280,775,281))base=24'hAB6DE5;
 end

 plot_base=base; base=background;
 if(rounded(x,y,18,308,96,447,4))base=keys[0]?24'h16558A:24'h223348;
 if(rounded(x,y,19,309,95,446,3))base=keys[0]?24'h8BEFFF:24'hDBDFE9;
 if(rounded(x,y,20,310,94,445,2))base=keys[0]?{8'h39,8'hB9+y[5:3],8'hF8}:{8'hD0+y[5:3],8'hD4+y[5:3],8'hDE+y[5:3]};
 if(box(x,y,21,310,93,311))base=keys[0]?24'hAEFFFF:24'hEFF5FF;
 if(rounded(x,y,98,308,196,447,4))base=keys[1]?24'h16558A:24'h223348;
 if(rounded(x,y,99,309,195,446,3))base=keys[1]?24'h8BEFFF:24'hDBDFE9;
 if(rounded(x,y,100,310,194,445,2))base=keys[1]?{8'h39,8'hB9+y[5:3],8'hF8}:{8'hD0+y[5:3],8'hD4+y[5:3],8'hDE+y[5:3]};
 if(box(x,y,101,310,193,311))base=keys[1]?24'hAEFFFF:24'hEFF5FF;
 if(rounded(x,y,197,308,276,447,4))base=keys[2]?24'h16558A:24'h223348;
 if(rounded(x,y,198,309,275,446,3))base=keys[2]?24'h8BEFFF:24'hDBDFE9;
 if(rounded(x,y,199,310,274,445,2))base=keys[2]?{8'h39,8'hB9+y[5:3],8'hF8}:{8'hD0+y[5:3],8'hD4+y[5:3],8'hDE+y[5:3]};
 if(box(x,y,200,310,273,311))base=keys[2]?24'hAEFFFF:24'hEFF5FF;
 if(rounded(x,y,277,308,352,447,4))base=keys[3]?24'h16558A:24'h223348;
 if(rounded(x,y,278,309,351,446,3))base=keys[3]?24'h8BEFFF:24'hDBDFE9;
 if(rounded(x,y,279,310,350,445,2))base=keys[3]?{8'h39,8'hB9+y[5:3],8'hF8}:{8'hD0+y[5:3],8'hD4+y[5:3],8'hDE+y[5:3]};
 if(box(x,y,280,310,349,311))base=keys[3]?24'hAEFFFF:24'hEFF5FF;
 if(rounded(x,y,353,308,448,447,4))base=keys[4]?24'h16558A:24'h223348;
 if(rounded(x,y,354,309,447,446,3))base=keys[4]?24'h8BEFFF:24'hDBDFE9;
 if(rounded(x,y,355,310,446,445,2))base=keys[4]?{8'h39,8'hB9+y[5:3],8'hF8}:{8'hD0+y[5:3],8'hD4+y[5:3],8'hDE+y[5:3]};
 if(box(x,y,356,310,445,311))base=keys[4]?24'hAEFFFF:24'hEFF5FF;
 if(rounded(x,y,449,308,526,447,4))base=keys[5]?24'h16558A:24'h223348;
 if(rounded(x,y,450,309,525,446,3))base=keys[5]?24'h8BEFFF:24'hDBDFE9;
 if(rounded(x,y,451,310,524,445,2))base=keys[5]?{8'h39,8'hB9+y[5:3],8'hF8}:{8'hD0+y[5:3],8'hD4+y[5:3],8'hDE+y[5:3]};
 if(box(x,y,452,310,523,311))base=keys[5]?24'hAEFFFF:24'hEFF5FF;
 if(rounded(x,y,527,308,602,447,4))base=keys[6]?24'h16558A:24'h223348;
 if(rounded(x,y,528,309,601,446,3))base=keys[6]?24'h8BEFFF:24'hDBDFE9;
 if(rounded(x,y,529,310,600,445,2))base=keys[6]?{8'h39,8'hB9+y[5:3],8'hF8}:{8'hD0+y[5:3],8'hD4+y[5:3],8'hDE+y[5:3]};
 if(box(x,y,530,310,599,311))base=keys[6]?24'hAEFFFF:24'hEFF5FF;
 if(rounded(x,y,603,308,701,447,4))base=keys[7]?24'h16558A:24'h223348;
 if(rounded(x,y,604,309,700,446,3))base=keys[7]?24'h8BEFFF:24'hDBDFE9;
 if(rounded(x,y,605,310,699,445,2))base=keys[7]?{8'h39,8'hB9+y[5:3],8'hF8}:{8'hD0+y[5:3],8'hD4+y[5:3],8'hDE+y[5:3]};
 if(box(x,y,606,310,698,311))base=keys[7]?24'hAEFFFF:24'hEFF5FF;
 if(rounded(x,y,702,308,782,447,4))base=keys[8]?24'h16558A:24'h223348;
 if(rounded(x,y,703,309,781,446,3))base=keys[8]?24'h8BEFFF:24'hDBDFE9;
 if(rounded(x,y,704,310,780,445,2))base=keys[8]?{8'h39,8'hB9+y[5:3],8'hF8}:{8'hD0+y[5:3],8'hD4+y[5:3],8'hDE+y[5:3]};
 if(box(x,y,705,310,779,311))base=keys[8]?24'hAEFFFF:24'hEFF5FF;
 if(rounded(x,y,70,309,127,383,3))base=24'h000307;
 if(rounded(x,y,72,309,125,377,2))base=keys[9]?24'h68EFFF:24'h16466B;
 if(rounded(x,y,73,310,124,376,2))base=keys[9]?24'h0A7EA3:24'h08111F;
 if(rounded(x,y,75,312,122,374,1))base=keys[9]?24'h075570:24'h07101B;
 if(rounded(x,y,169,309,225,383,3))base=24'h000307;
 if(rounded(x,y,171,309,223,377,2))base=keys[10]?24'h68EFFF:24'h16466B;
 if(rounded(x,y,172,310,222,376,2))base=keys[10]?24'h0A7EA3:24'h08111F;
 if(rounded(x,y,174,312,220,374,1))base=keys[10]?24'h075570:24'h07101B;
 if(rounded(x,y,324,309,380,383,3))base=24'h000307;
 if(rounded(x,y,326,309,378,377,2))base=keys[11]?24'h68EFFF:24'h16466B;
 if(rounded(x,y,327,310,377,376,2))base=keys[11]?24'h0A7EA3:24'h08111F;
 if(rounded(x,y,329,312,375,374,1))base=keys[11]?24'h075570:24'h07101B;
 if(rounded(x,y,421,309,478,383,3))base=24'h000307;
 if(rounded(x,y,423,309,476,377,2))base=keys[12]?24'h68EFFF:24'h16466B;
 if(rounded(x,y,424,310,475,376,2))base=keys[12]?24'h0A7EA3:24'h08111F;
 if(rounded(x,y,426,312,473,374,1))base=keys[12]?24'h075570:24'h07101B;
 if(rounded(x,y,574,309,630,383,3))base=24'h000307;
 if(rounded(x,y,576,309,628,377,2))base=keys[13]?24'h68EFFF:24'h16466B;
 if(rounded(x,y,577,310,627,376,2))base=keys[13]?24'h0A7EA3:24'h08111F;
 if(rounded(x,y,579,312,625,374,1))base=keys[13]?24'h075570:24'h07101B;
 if(rounded(x,y,673,309,730,383,3))base=24'h000307;
 if(rounded(x,y,675,309,728,377,2))base=keys[14]?24'h68EFFF:24'h16466B;
 if(rounded(x,y,676,310,727,376,2))base=keys[14]?24'h0A7EA3:24'h08111F;
 if(rounded(x,y,678,312,725,374,1))base=keys[14]?24'h075570:24'h07101B;
 key_base=base; base=header_base;
 if(box(x,y,44,27,67,48))begin
 case((y-27)>>0)
 0:icon=16'h1ff8;
 1:icon=16'h3ffc;
 2:icon=16'h3ffc;
 3:icon=16'h399c;
 4:icon=16'h399c;
 5:icon=16'h3ffc;
 6:icon=16'h3ffc;
 7:icon=16'h1ff8;
 8:icon=16'h1248;
 9:icon=16'h1248;
 10:icon=16'h1248;
 11:icon=16'h1248;
 12:icon=16'h1248;
 13:icon=16'h3ffc;
 14:icon=16'h3ffc;
 15:icon=16'h0000;
 default:icon=0;endcase
 if((x-44)<16 && icon[15-(x-44)])base=(!timbre)?24'h78EEFF:24'h5D91D7;
 end
 if(box(x,y,181,32,204,48))begin
 case((y-32)>>0)
 0:icon=16'h1008;
 1:icon=16'h0810;
 2:icon=16'h1ff8;
 3:icon=16'h3ffc;
 4:icon=16'h766e;
 5:icon=16'h7ffe;
 6:icon=16'h6ff6;
 7:icon=16'h6996;
 8:icon=16'h6006;
 9:icon=16'h1008;
 10:icon=16'h0c30;
 11:icon=16'h0000;
 12:icon=16'h0000;
 13:icon=16'h0000;
 14:icon=16'h0000;
 15:icon=16'h0000;
 default:icon=0;endcase
 if((x-181)<16 && icon[15-(x-181)])base=(timbre)?24'h78EEFF:24'h5D91D7;
 end
 if(box(x,y,430,39,518,39))base=24'h72B4E8;
 if(box(x,y,468,33,469,41))base=24'h72B4E8;
 if(box(x,y,472,27,473,48))base=24'h72B4E8;
 if(box(x,y,476,36,477,40))base=24'h72B4E8;
 if(box(x,y,479,32,480,45))base=24'h72B4E8;
 if(box(x,y,754,39,781,39))base=24'h72B4E8;
 header_base=base; base=(y<64)?header_base:((y<=144)?parameter_base:((y<296)?plot_base:key_base));
 ch=7'h20;crow=0;ccol=0;glyph=0;color_text=24'h79A9EE;pos=0;
 if(box(x,y,86,30,125,41))begin
 pos=(x-86)>>3;ch=(40'h5049414e4f)>>((5-1-pos)*8);
 crow=(y-30)>>0;ccol=((x-86)>>0)&7;
 glyph=(((x-86)&7)<8);color_text=(!timbre)?24'hC8F8FF:24'h699BDD;end
 if(box(x,y,228,30,267,41))begin
 pos=(x-228)>>3;ch=(40'h382d424954)>>((5-1-pos)*8);
 crow=(y-30)>>0;ccol=((x-228)>>0)&7;
 glyph=(((x-228)&7)<8);color_text=timbre?24'hC8F8FF:24'h699BDD;end
 if(box(x,y,524,33,531,44))begin
 pos=(x-524)>>3;ch=(8'h46)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-524)>>0)&7;
 glyph=(((x-524)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,536,33,543,44))begin
 pos=(x-536)>>3;ch=(8'h50)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-536)>>0)&7;
 glyph=(((x-536)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,548,33,555,44))begin
 pos=(x-548)>>3;ch=(8'h47)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-548)>>0)&7;
 glyph=(((x-548)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,560,33,567,44))begin
 pos=(x-560)>>3;ch=(8'h41)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-560)>>0)&7;
 glyph=(((x-560)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,572,33,579,44))begin
 pos=(x-572)>>3;ch=(8'h20)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-572)>>0)&7;
 glyph=(((x-572)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,584,33,591,44))begin
 pos=(x-584)>>3;ch=(8'h53)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-584)>>0)&7;
 glyph=(((x-584)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,596,33,603,44))begin
 pos=(x-596)>>3;ch=(8'h59)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-596)>>0)&7;
 glyph=(((x-596)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,608,33,615,44))begin
 pos=(x-608)>>3;ch=(8'h4e)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-608)>>0)&7;
 glyph=(((x-608)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,620,33,627,44))begin
 pos=(x-620)>>3;ch=(8'h54)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-620)>>0)&7;
 glyph=(((x-620)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,632,33,639,44))begin
 pos=(x-632)>>3;ch=(8'h48)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-632)>>0)&7;
 glyph=(((x-632)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,644,33,651,44))begin
 pos=(x-644)>>3;ch=(8'h45)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-644)>>0)&7;
 glyph=(((x-644)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,656,33,663,44))begin
 pos=(x-656)>>3;ch=(8'h53)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-656)>>0)&7;
 glyph=(((x-656)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,668,33,675,44))begin
 pos=(x-668)>>3;ch=(8'h49)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-668)>>0)&7;
 glyph=(((x-668)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,680,33,687,44))begin
 pos=(x-680)>>3;ch=(8'h5a)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-680)>>0)&7;
 glyph=(((x-680)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,692,33,699,44))begin
 pos=(x-692)>>3;ch=(8'h45)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-692)>>0)&7;
 glyph=(((x-692)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,704,33,711,44))begin
 pos=(x-704)>>3;ch=(8'h52)>>((1-1-pos)*8);
 crow=(y-33)>>0;ccol=((x-704)>>0)&7;
 glyph=(((x-704)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,50,78,81,89))begin
 pos=(x-50)>>3;ch=(32'h4e4f5445)>>((4-1-pos)*8);
 crow=(y-78)>>0;ccol=((x-50)>>0)&7;
 glyph=(((x-50)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,184,78,231,89))begin
 pos=(x-184)>>3;ch=(48'h564f4c554d45)>>((6-1-pos)*8);
 crow=(y-78)>>0;ccol=((x-184)>>0)&7;
 glyph=(((x-184)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,436,78,483,89))begin
 pos=(x-436)>>3;ch=(48'h4f4354415645)>>((6-1-pos)*8);
 crow=(y-78)>>0;ccol=((x-436)>>0)&7;
 glyph=(((x-436)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,670,78,757,89))begin
  pos=(x-670)>>3;ch=(88'h414354495645204b455953)>>((11-1-pos)*8);
  crow=(y-78)>>0;ccol=((x-670)>>0)&7;
  glyph=(((x-670)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,49,94,96,117))begin
 pos=(x-49)>>4;ch=(note_text)>>((3-1-pos)*8);
 crow=(y-94)>>1;ccol=((x-49)>>1)&7;
 glyph=(((x-49)&15)<16);color_text=24'hF4F7FF;end
 if(box(x,y,50,125,129,136))begin
 pos=(x-50)>>3;ch=(freq_text)>>((10-1-pos)*8);
 crow=(y-125)>>0;ccol=((x-50)>>0)&7;
 glyph=(((x-50)&7)<8);color_text=24'hBBC2DA;end
 if(box(x,y,184,94,215,105))begin
  pos=(x-184)>>3;ch=(volume_chars)>>((4-1-pos)*8);
  crow=(y-94)>>0;ccol=((x-184)>>0)&7;
  glyph=(((x-184)&7)<8);color_text=24'hF5F8FF;end
 if(box(x,y,248,94,327,105))begin
  pos=(x-248)>>3;ch=(pan_chars)>>((10-1-pos)*8);
  crow=(y-94)>>0;ccol=((x-248)>>0)&7;
  glyph=(((x-248)&7)<8);color_text=24'h8FB6DE;end
 if(box(x,y,453,106,468,117))begin
 pos=(x-453)>>3;ch=(16'h2d31)>>((2-1-pos)*8);
 crow=(y-106)>>0;ccol=((x-453)>>0)&7;
 glyph=(((x-453)&7)<8);color_text=octave==0?24'hF0FFFF:24'h789DE5;end
 if(box(x,y,499,106,506,117))begin
 pos=(x-499)>>3;ch=(8'h30)>>((1-1-pos)*8);
 crow=(y-106)>>0;ccol=((x-499)>>0)&7;
 glyph=(((x-499)&7)<8);color_text=octave==1?24'hF0FFFF:24'h789DE5;end
 if(box(x,y,545,106,560,117))begin
 pos=(x-545)>>3;ch=(16'h2b31)>>((2-1-pos)*8);
 crow=(y-106)>>0;ccol=((x-545)>>0)&7;
 glyph=(((x-545)&7)<8);color_text=octave==2?24'hF0FFFF:24'h789DE5;end
 if(box(x,y,591,106,606,117))begin
 pos=(x-591)>>3;ch=(16'h2b32)>>((2-1-pos)*8);
 crow=(y-106)>>0;ccol=((x-591)>>0)&7;
 glyph=(((x-591)&7)<8);color_text=octave==3?24'hF0FFFF:24'h789DE5;end
 if(box(x,y,672,104,767,127))begin
  pos=(x-672)>>4;ch=(count_chars)>>((6-1-pos)*8);
  crow=(y-104)>>1;ccol=((x-672)>>1)&7;
  glyph=(((x-672)&15)<16);color_text=(pos<3)?24'h26E7F1:24'h46629A;end
 if(!guide_mode)begin
 if(box(x,y,41,163,104,174))begin
 pos=(x-41)>>3;ch=(64'h57415645464f524d)>>((8-1-pos)*8);
 crow=(y-163)>>0;ccol=((x-41)>>0)&7;
 glyph=(((x-41)&7)<8);color_text=24'h79A9EE;end
 if(box(x,y,735,164,766,175))begin
  pos=(x-735)>>3;ch=(32'h4c495645)>>((4-1-pos)*8);
  crow=(y-164)>>0;ccol=((x-735)>>0)&7;
  glyph=(((x-735)&7)<8);color_text=24'h27E4EE;end
 if(box(x,y,620,164,699,175))begin
  pos=(x-620)>>3;ch=(lat_chars)>>((10-1-pos)*8);
  crow=(y-164)>>0;ccol=((x-620)>>0)&7;
  glyph=(((x-620)&7)<8);color_text=24'h1FA8C4;end
 end else begin
 if(guide_phase==1)begin
 if(box(x,y,348,216,419,227))begin
 pos=(x-348)>>3;ch=(72'h474554205245414459)>>((9-1-pos)*8);
 crow=(y-216)>>0;ccol=((x-348)>>0)&7;
 glyph=(((x-348)&7)<8);color_text=24'hDAB9FF;end
 if(box(x,y,392,237,407,260))begin
 pos=(x-392)>>4;ch=({8'd48+{6'd0,countdown}})>>((1-1-pos)*8);
 crow=(y-237)>>1;ccol=((x-392)>>1)&7;
 glyph=(((x-392)&15)<16);color_text=24'hF4F7FF;end
 end else if(guide_phase==5)begin
 if(box(x,y,336,222,463,245))begin
 pos=(x-336)>>4;ch=(64'h434f4d504c455445)>>((8-1-pos)*8);
 crow=(y-222)>>1;ccol=((x-336)>>1)&7;
 glyph=(((x-336)&15)<16);color_text=24'hE8CAFF;end
 end else begin
 end end
 if(TEST_MODE!=0)begin
  glyph=0;
  if(TEST_MODE==2)base=0;
  else if(x<4||x>=796||y<4||y>=476)base=24'hFFFFFF;
  else if(x<100)base=24'h000000;
  else if(x<200)base=24'hFFFFFF;
  else if(x<300)base=24'hFF0000;
  else if(x<400)base=24'h00FF00;
  else if(x<500)base=24'h0000FF;
  else if(x<600)base=24'h00FFFF;
  else if(x<700)base=24'hFF00FF;
  else base=24'hFFFF00;
 end
end
wire [7:0] font_bits;
ui_font_rom u_font(pclk,ch,crow,font_bits);
reg [23:0] base1,text1,fx_color1;reg glyph1,fx_valid1;reg [2:0] col1;
reg [9:0] y1;reg wave1,hs1,vs1,de1,guide1,guide2;
reg [23:0] base2,text2;reg font2,wave2;reg [9:0] y2,top2,bottom2;
reg hs2,vs2,de2;
reg signed [16:0] amp_low,amp_high;
reg signed [17:0] ytop,ybottom;
always @* begin
 amp_low=$signed(wave_data[31:16]) >>> (4'd9-{1'b0,wave_scale});
 amp_high=$signed(wave_data[15:0]) >>> (4'd9-{1'b0,wave_scale});
 ytop=18'sd237-amp_high;ybottom=18'sd237-amp_low;
 if(ytop<183)ytop=183;else if(ytop>287)ytop=287;
 if(ybottom<183)ybottom=183;else if(ybottom>287)ybottom=287;
end
always @(posedge pclk or negedge rst_n)begin
 if(!rst_n)begin
  base1<=0;text1<=0;glyph1<=0;col1<=0;y1<=0;wave1<=0;hs1<=1;vs1<=1;de1<=0;guide1<=0;guide2<=0;fx_color1<=0;fx_valid1<=0;
  base2<=0;text2<=0;font2<=0;wave2<=0;y2<=0;top2<=237;bottom2<=237;hs2<=1;vs2<=1;de2<=0;
 end else begin
  base1<=base;text1<=color_text;glyph1<=glyph;col1<=ccol;y1<=y;
  fx_color1<=fx_color;fx_valid1<=fx_valid && TEST_MODE==0;
  guide1<=guide_mode && TEST_MODE==0;guide2<=guide1;
  wave1<=TEST_MODE==0 && !guide_mode && wave_valid && x>=16 && x<784 && y>=183 && y<=287;
  hs1<=hs0;vs1<=vs0;de1<=de0;
  base2<=fx_valid1?fx_color1:base1;text2<=text1;font2<=glyph1 && font_bits[7-col1];
  wave2<=wave1;y2<=y1;top2<=ytop[9:0];bottom2<=ybottom[9:0];
  hs2<=hs1;vs2<=vs1;de2<=de1;
 end
end
reg [23:0] composed;
always @* begin
 composed=base2;
 if(wave2)begin
  if(y2>=top2 && y2<=bottom2)composed=24'hECFFFF;
  else if(y2+1>=top2 && y2<=bottom2+1)composed=24'h2FE8FF;
  else if(y2+3>=top2 && y2<=bottom2+3)composed=24'h0672AF;
  else if((y2>=bottom2 && y2<=237)||(y2>=237 && y2<=top2))composed=24'h042440;
 end
 if(font2)composed=text2;
 if(guide2)composed=purple(composed);
 if(!de2)composed=0;
end
always @(posedge pclk or negedge rst_n)begin
 if(!rst_n)begin lcd_hs<=1;lcd_vs<=1;lcd_de<=0;lcd_r<=0;lcd_g<=0;lcd_b<=0;end
 else begin
  lcd_hs<=hs2;lcd_vs<=vs2;lcd_de<=de2;
  lcd_r<=composed[23:16];lcd_g<=composed[15:8];lcd_b<=composed[7:0];
 end
end
endmodule
