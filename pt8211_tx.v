// PT8211: 16-bit LSB-justified stereo, MSB first; DIN changes on BCK falling edge.
`timescale 1ns / 1ps

module pt8211_tx #(
    parameter integer BCK_DIV      = 8,
    parameter         LEFT_IS_HIGH = 1
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] sample_l,
    input  wire [15:0] sample_r,
    output reg         sample_tick,
    output reg         bck,
    output reg         ws,
    output reg         din
);

    reg [7:0]  div_cnt;
    reg [4:0]  bitpos;
    reg        ch;
    reg [15:0] sr;
    reg [15:0] frame_l;
    reg [15:0] frame_r;

    wire bck_fall = (div_cnt == BCK_DIV - 1) && (bck == 1'b1);
    wire ws_level = LEFT_IS_HIGH ? ch : ~ch;

    always @(posedge clk) begin
        if (!rst_n) begin
            div_cnt      <= 8'd0;
            bck          <= 1'b0;
            bitpos       <= 5'd0;
            ch           <= 1'b0;
            sr           <= 16'd0;
            frame_l      <= 16'd0;
            frame_r      <= 16'd0;
            ws           <= 1'b0;
            din          <= 1'b0;
            sample_tick  <= 1'b0;
        end else begin
            sample_tick <= 1'b0;

            if (div_cnt == BCK_DIV - 1) begin
                div_cnt <= 8'd0;
                bck     <= ~bck;
            end else begin
                div_cnt <= div_cnt + 8'd1;
            end

            if (bck_fall) begin
                if (bitpos == 5'd0) begin
                    if (ch == 1'b0) begin
                        frame_l     <= sample_l;
                        frame_r     <= sample_r;
                        sr          <= LEFT_IS_HIGH ? sample_r : sample_l;
                        din         <= LEFT_IS_HIGH ? sample_r[15] : sample_l[15];
                        sample_tick <= 1'b1;
                    end else begin
                        sr  <= LEFT_IS_HIGH ? frame_l : frame_r;
                        din <= LEFT_IS_HIGH ? frame_l[15] : frame_r[15];
                    end
                    ws     <= ws_level;
                    ch     <= ~ch;
                    bitpos <= 5'd1;
                end else begin
                    din <= sr[14];
                    sr  <= {sr[14:0], 1'b0};
                    if (bitpos == 5'd15) bitpos <= 5'd0;
                    else                 bitpos <= bitpos + 5'd1;
                end
            end
        end
    end

endmodule
