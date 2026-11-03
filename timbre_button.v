`timescale 1ns/1ps
module timbre_button #(
    parameter integer CLK_HZ = 50_000_000,
    parameter integer DEBOUNCE_MS = 10
)(input wire clk, rst_n, key_n,
  output reg selected_nes, output reg release_event);
    localparam integer CYCLES_RAW = (CLK_HZ / 1000) * DEBOUNCE_MS;
    localparam integer CYCLES = CYCLES_RAW < 2 ? 2 : CYCLES_RAW;
    function integer bits_needed;
        input integer n;
        integer v;
        begin
            v=n-1; bits_needed=0;
            while(v>0) begin bits_needed=bits_needed+1; v=v>>1; end
            if(bits_needed<1) bits_needed=1;
        end
    endfunction
    localparam integer CW = bits_needed(CYCLES);
    (* syn_preserve=1, async_reg="true" *) reg [2:0] key_sync;
    reg [CW-1:0] count;
    reg ready, stable_pressed, press_seen;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) key_sync<=3'b111;
        else key_sync<={key_sync[1:0],key_n};
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            count<=0; ready<=0; stable_pressed<=0; press_seen<=0;
            selected_nes<=0; release_event<=0;
        end else begin
            release_event<=0;
            if(!ready) begin
                if(!key_sync[2]) count<=0;
                else if(count==CYCLES-1) begin ready<=1; count<=0; end
                else count<=count+1'b1;
            end else if(key_sync[2]==!stable_pressed) count<=0;
            else if(count==CYCLES-1) begin
                count<=0;
                stable_pressed<=!key_sync[2];
                if(!key_sync[2]) press_seen<=1;
                else begin
                    if(press_seen) begin
                        selected_nes<=!selected_nes;
                        release_event<=1;
                    end
                    press_seen<=0;
                end
            end else count<=count+1'b1;
        end
    end
endmodule
