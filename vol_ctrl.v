// Active-low buttons select a clamped 3 dB ladder; the audio core slews the gain.
`timescale 1ns / 1ps

module vol_ctrl #(
    parameter CLK_HZ      = 50_000_000,
    parameter KEY_ACT_LOW = 1,
    parameter DEB_MS      = 20,
    parameter HOLD_MS     = 300,
    parameter REP_MS      = 150,
    parameter [3:0] CODE_RST = 4'd15,
    parameter [3:0] CODE_MAX = 4'd15
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        key_up,
    input  wire        key_dn,
    output reg  [3:0]  vol_code,
    output wire [15:0] vol_coef
);

    localparam [19:0] DEB_MAX  = (CLK_HZ / 1000) * DEB_MS;
    localparam [23:0] HOLD_MAX = (CLK_HZ / 1000) * HOLD_MS;
    localparam [22:0] REP_MAX  = (CLK_HZ / 1000) * REP_MS;

    reg up_s1, up_s2, dn_s1, dn_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            up_s1 <= 1'b0; up_s2 <= 1'b0;
            dn_s1 <= 1'b0; dn_s2 <= 1'b0;
        end else begin
            up_s1 <= key_up;  up_s2 <= up_s1;
            dn_s1 <= key_dn;  dn_s2 <= dn_s1;
        end
    end

    reg       up_raw, dn_raw;
    reg [19:0] up_dcnt, dn_dcnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            up_raw <= 1'b0; up_dcnt <= 20'd0;
        end else if (up_s2 != up_raw) begin
            if (up_dcnt == DEB_MAX - 20'd1) begin
                up_raw  <= up_s2;
                up_dcnt <= 20'd0;
            end else begin
                up_dcnt <= up_dcnt + 20'd1;
            end
        end else begin
            up_dcnt <= 20'd0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dn_raw <= 1'b0; dn_dcnt <= 20'd0;
        end else if (dn_s2 != dn_raw) begin
            if (dn_dcnt == DEB_MAX - 20'd1) begin
                dn_raw  <= dn_s2;
                dn_dcnt <= 20'd0;
            end else begin
                dn_dcnt <= dn_dcnt + 20'd1;
            end
        end else begin
            dn_dcnt <= 20'd0;
        end
    end

    wire up_act = KEY_ACT_LOW ? ~up_raw : up_raw;
    wire dn_act = KEY_ACT_LOW ? ~dn_raw : dn_raw;

    reg up_d, dn_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            up_d <= 1'b0; dn_d <= 1'b0;
        end else begin
            up_d <= up_act; dn_d <= dn_act;
        end
    end
    wire up_press = up_act & ~up_d;
    wire dn_press = dn_act & ~dn_d;

    reg [23:0] up_hold, dn_hold;
    reg [22:0] up_rep,  dn_rep;
    reg        up_step, dn_step;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            up_hold <= 24'd0; up_rep <= 23'd0; up_step <= 1'b0;
        end else if (!up_act) begin
            up_hold <= 24'd0; up_rep <= 23'd0; up_step <= 1'b0;
        end else begin
            if (up_hold != HOLD_MAX) up_hold <= up_hold + 24'd1;

            if (up_hold == HOLD_MAX) begin
                if (up_rep == REP_MAX) begin
                    up_rep  <= 23'd0;
                    up_step <= 1'b1;
                end else begin
                    up_rep  <= up_rep + 23'd1;
                    up_step <= 1'b0;
                end
            end else begin
                up_rep  <= 23'd0;
                up_step <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dn_hold <= 24'd0; dn_rep <= 23'd0; dn_step <= 1'b0;
        end else if (!dn_act) begin
            dn_hold <= 24'd0; dn_rep <= 23'd0; dn_step <= 1'b0;
        end else begin
            if (dn_hold != HOLD_MAX) dn_hold <= dn_hold + 24'd1;

            if (dn_hold == HOLD_MAX) begin
                if (dn_rep == REP_MAX) begin
                    dn_rep  <= 23'd0;
                    dn_step <= 1'b1;
                end else begin
                    dn_rep  <= dn_rep + 23'd1;
                    dn_step <= 1'b0;
                end
            end else begin
                dn_rep  <= 23'd0;
                dn_step <= 1'b0;
            end
        end
    end

    wire inc_req = up_press | up_step;
    wire dec_req = dn_press | dn_step;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vol_code <= CODE_RST;
        end else if (inc_req && !dn_act && !dec_req) begin
            if (vol_code != CODE_MAX) vol_code <= vol_code + 4'd1;
        end else if (dec_req && !up_act && !inc_req) begin
            if (vol_code != 4'd0) vol_code <= vol_code - 4'd1;
        end
    end

    reg [15:0] coef_c;
    always @(*) begin
        case (vol_code)
            4'd15:   coef_c = 16'd32767;
            4'd14:   coef_c = 16'd23197;
            4'd13:   coef_c = 16'd16423;
            4'd12:   coef_c = 16'd11625;
            4'd11:   coef_c = 16'd8231;
            4'd10:   coef_c = 16'd5828;
            4'd9:    coef_c = 16'd4125;
            4'd8:    coef_c = 16'd2921;
            4'd7:    coef_c = 16'd2068;
            4'd6:    coef_c = 16'd1464;
            4'd5:    coef_c = 16'd1036;
            4'd4:    coef_c = 16'd734;
            4'd3:    coef_c = 16'd519;
            4'd2:    coef_c = 16'd368;
            4'd1:    coef_c = 16'd260;
            4'd0:    coef_c = 16'd0;
            default: coef_c = 16'd32767;
        endcase
    end

    assign vol_coef = coef_c;

endmodule
