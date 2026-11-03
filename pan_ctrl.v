// One button: release before 600 ms advances pan; a 600 ms hold steps the metronome.
// Pan gains only attenuate; coefficient changes slew to avoid clicks.
`timescale 1ns / 1ps

module pan_ctrl #(
    parameter CLK_HZ      = 50_000_000,
    parameter KEY_ACT_LOW = 1,
    parameter DEB_MS      = 20,
    parameter HOLD_MS     = 600,
    parameter [2:0] PAN_RST = 3'd0
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        key_metro_n,
    output reg  [2:0]  pan_mode,
    output reg  [15:0] coef_l,
    output reg  [15:0] coef_r,
    output reg         metro_step
);

    localparam [19:0] DEB_MAX  = (CLK_HZ / 1000) * DEB_MS;
    localparam [24:0] HOLD_MAX = (CLK_HZ / 1000) * HOLD_MS;

    reg k_s1, k_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_s1 <= 1'b0; k_s2 <= 1'b0;
        end else begin
            k_s1 <= key_metro_n; k_s2 <= k_s1;
        end
    end

    reg        k_raw;
    reg [19:0] k_dcnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_raw <= 1'b0; k_dcnt <= 20'd0;
        end else if (k_s2 != k_raw) begin
            if (k_dcnt == DEB_MAX - 20'd1) begin k_raw <= k_s2; k_dcnt <= 20'd0; end
            else                                  k_dcnt <= k_dcnt + 20'd1;
        end else k_dcnt <= 20'd0;
    end

    wire k_act = KEY_ACT_LOW ? ~k_raw : k_raw;

    reg        k_act_d;
    reg [24:0] hold_cnt;
    reg        consumed;

    wire k_press =  k_act & ~k_act_d;
    wire k_rel   = ~k_act &  k_act_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_act_d    <= 1'b0;
            hold_cnt   <= 25'd0;
            consumed   <= 1'b0;
            metro_step <= 1'b0;
            pan_mode   <= PAN_RST;
        end else begin
            k_act_d    <= k_act;
            metro_step <= 1'b0;

            if (k_press) begin
                hold_cnt <= 25'd0;
                consumed <= 1'b0;
            end else if (k_act && !consumed) begin
                if (hold_cnt == HOLD_MAX - 25'd1) begin
                    hold_cnt  <= 25'd0;
                    consumed  <= 1'b1;
                    metro_step <= 1'b1;
                end else begin
                    hold_cnt <= hold_cnt + 25'd1;
                end
            end

            if (k_rel) begin
                hold_cnt <= 25'd0;
                if (!consumed) pan_mode <= (pan_mode == 3'd5) ? 3'd0 : pan_mode + 3'd1;
                consumed <= 1'b0;
            end
        end
    end

    reg [15:0] tgt_l, tgt_r;
    always @(*) begin
        case (pan_mode)
            3'd0: begin tgt_l = 16'd32767; tgt_r = 16'd32767; end
            3'd1: begin tgt_l = 16'd16384; tgt_r = 16'd16384; end
            3'd2: begin tgt_l = 16'd24576; tgt_r = 16'd8192;  end
            3'd3: begin tgt_l = 16'd8192;  tgt_r = 16'd24576; end
            3'd4: begin tgt_l = 16'd32767; tgt_r = 16'd0;     end
            3'd5: begin tgt_l = 16'd0;     tgt_r = 16'd32767; end
            default: begin tgt_l = 16'd32767; tgt_r = 16'd32767; end
        endcase
    end

    localparam [3:0] RAMP_DIV = 4'd15;

    reg [3:0] ramp_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ramp_cnt <= 4'd0;
            coef_l   <= 16'd0;
            coef_r   <= 16'd0;
        end else if (ramp_cnt != RAMP_DIV) begin
            ramp_cnt <= ramp_cnt + 4'd1;
        end else begin
            ramp_cnt <= 4'd0;
            if      (coef_l < tgt_l) coef_l <= coef_l + 16'd1;
            else if (coef_l > tgt_l) coef_l <= coef_l - 16'd1;
            if      (coef_r < tgt_r) coef_r <= coef_r + 16'd1;
            else if (coef_r > tgt_r) coef_r <= coef_r - 16'd1;
        end
    end

endmodule
