// TTP229 serial words are published after the 16th bit, before the inter-frame gap.
// Keep the scan timing and keyboard debounce thresholds consistent.
`timescale 1ns / 1ps

module ttp229_reader #(
    parameter integer CLK_HZ      = 50_000_000,
    parameter integer T_START_US  = 10,
    parameter integer T_HALF_US   = 10,
    parameter integer T_SAMPLE_US = 3,
    parameter integer T_GAP_US    = 400,
    parameter integer ACTIVE_LOW  = 1
)(
    input  wire        clk,
    input  wire        rst_n,
    output reg         scl,
    input  wire        sdo,
    output reg  [15:0] key_data,
    output reg  [15:0] raw_data,
    output reg         key_valid
);

    localparam integer US       = CLK_HZ / 1_000_000;
    localparam integer C_START  = T_START_US  * US;
    localparam integer C_HALF   = T_HALF_US   * US;
    localparam integer C_SAMPLE = T_SAMPLE_US * US;
    localparam integer C_GAP    = T_GAP_US    * US;

    localparam [1:0] S_START = 2'd0,
                     S_HIGH  = 2'd1,
                     S_LOW   = 2'd2,
                     S_GAP   = 2'd3;

    reg [1:0]  state;
    reg [31:0] cnt;
    reg [3:0]  bit_idx;
    reg [15:0] sh_norm;
    reg [15:0] sh_raw;

    reg sdo_meta, sdo_sync;
    always @(posedge clk) begin
        sdo_meta <= sdo;
        sdo_sync <= sdo_meta;
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            state     <= S_START;
            cnt       <= 32'd0;
            bit_idx   <= 4'd0;
            sh_norm   <= 16'd0;
            sh_raw    <= 16'd0;
            scl       <= 1'b1;
            key_data  <= 16'd0;
            raw_data  <= 16'd0;
            key_valid <= 1'b0;
        end else begin
            key_valid <= 1'b0;

            case (state)

            S_START: begin
                scl <= 1'b0;
                if (cnt == C_START - 1) begin
                    cnt     <= 32'd0;
                    bit_idx <= 4'd0;
                    state   <= S_HIGH;
                end else begin
                    cnt <= cnt + 32'd1;
                end
            end

            S_HIGH: begin
                scl <= 1'b1;
                if (cnt == C_SAMPLE - 1) begin
                    sh_raw [bit_idx] <= sdo_sync;
                    sh_norm[bit_idx] <= ACTIVE_LOW ? ~sdo_sync : sdo_sync;
                end
                if (cnt == C_HALF - 1) begin
                    cnt   <= 32'd0;
                    state <= S_LOW;
                end else begin
                    cnt <= cnt + 32'd1;
                end
            end

            S_LOW: begin
                scl <= 1'b0;
                if (cnt == C_HALF - 1) begin
                    cnt <= 32'd0;
                    if (bit_idx == 4'd15) begin
                        key_data  <= sh_norm;
                        raw_data  <= sh_raw;
                        key_valid <= 1'b1;
                        state     <= S_GAP;
                    end else begin
                        bit_idx <= bit_idx + 4'd1;
                        state   <= S_HIGH;
                    end
                end else begin
                    cnt <= cnt + 32'd1;
                end
            end

            S_GAP: begin
                scl <= 1'b1;
                if (cnt == C_GAP - 1) begin
                    cnt   <= 32'd0;
                    state <= S_START;
                end else begin
                    cnt <= cnt + 32'd1;
                end
            end

            default: state <= S_START;

            endcase
        end
    end

endmodule
