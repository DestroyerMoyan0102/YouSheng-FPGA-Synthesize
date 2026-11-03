// Physical key indices for the 14-note Guided Play song.
`timescale 1ns/1ps
module guide_song_rom(input wire [3:0] address,
 output reg [3:0] key_index, output reg valid);
always @* begin
 valid=1'b1;
 case(address)
  0,1,13: key_index=4'd0;
  2,3,6:  key_index=4'd4;
  4,5:    key_index=4'd5;
  7,8:    key_index=4'd3;
  9,10:   key_index=4'd2;
  11,12:  key_index=4'd1;
  default:begin key_index=0;valid=0;end
 endcase
end
endmodule
