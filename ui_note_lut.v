module ui_note_lut(input wire [6:0] midi, output reg [23:0] note_ascii,output reg [79:0] freq_ascii);
always @* begin
note_ascii=24'h433420;freq_ascii=80'h3236312E363320487A20;
case(midi)
7'd48:begin note_ascii=24'h433320;freq_ascii=80'h3133302E383120487A20;end
7'd49:begin note_ascii=24'h432333;freq_ascii=80'h3133382E353920487A20;end
7'd50:begin note_ascii=24'h443320;freq_ascii=80'h3134362E383320487A20;end
7'd51:begin note_ascii=24'h442333;freq_ascii=80'h3135352E353620487A20;end
7'd52:begin note_ascii=24'h453320;freq_ascii=80'h3136342E383120487A20;end
7'd53:begin note_ascii=24'h463320;freq_ascii=80'h3137342E363120487A20;end
7'd54:begin note_ascii=24'h462333;freq_ascii=80'h3138352E303020487A20;end
7'd55:begin note_ascii=24'h473320;freq_ascii=80'h3139362E303020487A20;end
7'd56:begin note_ascii=24'h472333;freq_ascii=80'h3230372E363520487A20;end
7'd57:begin note_ascii=24'h413320;freq_ascii=80'h3232302E303020487A20;end
7'd58:begin note_ascii=24'h412333;freq_ascii=80'h3233332E303820487A20;end
7'd59:begin note_ascii=24'h423320;freq_ascii=80'h3234362E393420487A20;end
7'd60:begin note_ascii=24'h433420;freq_ascii=80'h3236312E363320487A20;end
7'd61:begin note_ascii=24'h432334;freq_ascii=80'h3237372E313820487A20;end
7'd62:begin note_ascii=24'h443420;freq_ascii=80'h3239332E363620487A20;end
7'd63:begin note_ascii=24'h442334;freq_ascii=80'h3331312E313320487A20;end
7'd64:begin note_ascii=24'h453420;freq_ascii=80'h3332392E363320487A20;end
7'd65:begin note_ascii=24'h463420;freq_ascii=80'h3334392E323320487A20;end
7'd66:begin note_ascii=24'h462334;freq_ascii=80'h3336392E393920487A20;end
7'd67:begin note_ascii=24'h473420;freq_ascii=80'h3339322E303020487A20;end
7'd68:begin note_ascii=24'h472334;freq_ascii=80'h3431352E333020487A20;end
7'd69:begin note_ascii=24'h413420;freq_ascii=80'h3434302E303020487A20;end
7'd70:begin note_ascii=24'h412334;freq_ascii=80'h3436362E313620487A20;end
7'd71:begin note_ascii=24'h423420;freq_ascii=80'h3439332E383820487A20;end
7'd72:begin note_ascii=24'h433520;freq_ascii=80'h3532332E323520487A20;end
7'd73:begin note_ascii=24'h432335;freq_ascii=80'h3535342E333720487A20;end
7'd74:begin note_ascii=24'h443520;freq_ascii=80'h3538372E333320487A20;end
7'd75:begin note_ascii=24'h442335;freq_ascii=80'h3632322E323520487A20;end
7'd76:begin note_ascii=24'h453520;freq_ascii=80'h3635392E323620487A20;end
7'd77:begin note_ascii=24'h463520;freq_ascii=80'h3639382E343620487A20;end
7'd78:begin note_ascii=24'h462335;freq_ascii=80'h3733392E393920487A20;end
7'd79:begin note_ascii=24'h473520;freq_ascii=80'h3738332E393920487A20;end
7'd80:begin note_ascii=24'h472335;freq_ascii=80'h3833302E363120487A20;end
7'd81:begin note_ascii=24'h413520;freq_ascii=80'h3838302E303020487A20;end
7'd82:begin note_ascii=24'h412335;freq_ascii=80'h3933322E333320487A20;end
7'd83:begin note_ascii=24'h423520;freq_ascii=80'h3938372E373720487A20;end
7'd84:begin note_ascii=24'h433620;freq_ascii=80'h313034362E353020487A;end
7'd85:begin note_ascii=24'h432336;freq_ascii=80'h313130382E373320487A;end
7'd86:begin note_ascii=24'h443620;freq_ascii=80'h313137342E363620487A;end
7'd87:begin note_ascii=24'h442336;freq_ascii=80'h313234342E353120487A;end
7'd88:begin note_ascii=24'h453620;freq_ascii=80'h313331382E353120487A;end
7'd89:begin note_ascii=24'h463620;freq_ascii=80'h313339362E393120487A;end
7'd90:begin note_ascii=24'h462336;freq_ascii=80'h313437392E393820487A;end
7'd91:begin note_ascii=24'h473620;freq_ascii=80'h313536372E393820487A;end
7'd92:begin note_ascii=24'h472336;freq_ascii=80'h313636312E323220487A;end
7'd93:begin note_ascii=24'h413620;freq_ascii=80'h313736302E303020487A;end
7'd94:begin note_ascii=24'h412336;freq_ascii=80'h313836342E363620487A;end
7'd95:begin note_ascii=24'h423620;freq_ascii=80'h313937352E353320487A;end
7'd96:begin note_ascii=24'h433720;freq_ascii=80'h323039332E303020487A;end
7'd97:begin note_ascii=24'h432337;freq_ascii=80'h323231372E343620487A;end
7'd98:begin note_ascii=24'h443720;freq_ascii=80'h323334392E333220487A;end
endcase
end
endmodule
