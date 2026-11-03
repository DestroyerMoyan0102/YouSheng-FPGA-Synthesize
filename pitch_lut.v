`timescale 1ns/1ps
module pitch_lut(input wire [6:0] midi, output reg [31:0] step);
always @* begin
 case (midi)
 7'd48: step=32'd5753207; // C3
 7'd49: step=32'd6095311; // C#3
 7'd50: step=32'd6457757; // D3
 7'd51: step=32'd6841755; // D#3
 7'd52: step=32'd7248587; // E3
 7'd53: step=32'd7679610; // F3
 7'd54: step=32'd8136263; // F#3
 7'd55: step=32'd8620071; // G3
 7'd56: step=32'd9132647; // G#3
 7'd57: step=32'd9675702; // A3
 7'd58: step=32'd10251050; // A#3
 7'd59: step=32'd10860609; // B3
 7'd60: step=32'd11506414; // C4
 7'd61: step=32'd12190621; // C#4
 7'd62: step=32'd12915513; // D4
 7'd63: step=32'd13683509; // D#4
 7'd64: step=32'd14497173; // E4
 7'd65: step=32'd15359220; // F4
 7'd66: step=32'd16272527; // F#4
 7'd67: step=32'd17240142; // G4
 7'd68: step=32'd18265294; // G#4
 7'd69: step=32'd19351405; // A4
 7'd70: step=32'd20502099; // A#4
 7'd71: step=32'd21721217; // B4
 7'd72: step=32'd23012828; // C5
 7'd73: step=32'd24381242; // C#5
 7'd74: step=32'd25831026; // D5
 7'd75: step=32'd27367019; // D#5
 7'd76: step=32'd28994347; // E5
 7'd77: step=32'd30718440; // F5
 7'd78: step=32'd32545054; // F#5
 7'd79: step=32'd34480283; // G5
 7'd80: step=32'd36530588; // G#5
 7'd81: step=32'd38702809; // A5
 7'd82: step=32'd41004198; // A#5
 7'd83: step=32'd43442435; // B5
 7'd84: step=32'd46025656;
 7'd85: step=32'd48762484;
 7'd86: step=32'd51662052;
 7'd87: step=32'd54734038;
 7'd88: step=32'd57988693;
 7'd89: step=32'd61436880;
 7'd90: step=32'd65090107;
 7'd91: step=32'd68960566;
 7'd92: step=32'd73061175;
 7'd93: step=32'd77405619;
 7'd94: step=32'd82008396;
 7'd95: step=32'd86884869;
 7'd96: step=32'd92051312;
 7'd97: step=32'd97524968;
 7'd98: step=32'd103324105;
 default: step=0;
 endcase
end
endmodule
module keyboard_pitch(input wire [3:0] idx, input wire [1:0] octave_select,
 output wire [31:0] step, output wire region, output reg [6:0] midi);
reg [6:0] base;
always @* begin
 case(idx)
 4'd0: base=7'd60;
 4'd1: base=7'd62;
 4'd2: base=7'd64;
 4'd3: base=7'd65;
 4'd4: base=7'd67;
 4'd5: base=7'd69;
 4'd6: base=7'd71;
 4'd7: base=7'd72;
 4'd8: base=7'd74;
 4'd9: base=7'd61;
 4'd10: base=7'd63;
 4'd11: base=7'd66;
 4'd12: base=7'd68;
 4'd13: base=7'd70;
 4'd14: base=7'd73;
 default: base=0;
 endcase
 midi=base;
 if(base!=0) begin
  case(octave_select)
   0: midi=base-7'd12;
   2: midi=base+7'd12;
   3: midi=base+7'd24;
   default: midi=base;
  endcase
 end
 if(midi<48 || midi>98) midi=0;
end
assign region=(midi>=72);
pitch_lut u_pitch(midi,step);
endmodule
