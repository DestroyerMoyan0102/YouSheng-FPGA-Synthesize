// TTP229 frame timing and debounce thresholds must be tuned together.
// KEY16 is reserved for Guided Play; the second slot of each playable key is detuned.
// Keep the per-sample gain ramps and mixer pipeline to avoid clicks and timing regressions.
`timescale 1ns / 1ps

module instrument_core #(parameter [25:0] POR_END=26'd33_554_431,
    parameter SELFTEST=0, parameter [6:0] VEL_DEF=7'd100,
    parameter [4:0] KB_PRESS_TH=5'd0, KB_REL_TH=5'd3,
    parameter KEY16_E5=0) (
    input wire [1:0] octave_select,
    input wire timbre_select,
    input wire vibrato_select,
    input wire [1:0] metronome_mode,
    input  wire sys_clk,
    output wire touch_scl,
    input  wire touch_sdo,
    output wire hp_bck,
    output wire hp_ws,
    output wire hp_din,
    output wire pa_en,
    input  wire key_vol_up,
    input  wire key_vol_dn,
    input  wire metro_key_n,
    output wire metro_step,
    output wire core_rst_n,
    output wire [14:0] ui_keys,
    output wire [3:0]  ui_vol_code,
    output wire [9:0]  ui_lat,
    output wire [2:0]  ui_pan,
    output wire [1:0] ui_octave,
    output wire ui_timbre,ui_sample_tick,
    output wire signed [15:0] ui_pcm,
    output wire ui_key16
);

    wire active_timbre, active_vibrato;
    wire [1:0] active_octave;
    wire [15:0] transition_gain;
    localparam NV     = 32;
    localparam [4:0] DET_SH = 5'd9;








    localparam [19:0] ENV_MAX = 20'hFFFFF;
    localparam [19:0] ATT_INC = 20'd1790;
    localparam [19:0] SUS_LVL = 20'hA0000;
    localparam [4:0]  DEC_SH  = 5'd16;
    localparam [4:0]  SUS_SH  = 5'd19;
    localparam [4:0]  REL_SH  = 5'd14;

    localparam [19:0] NES_ATTACK = 20'd2048;
    localparam [19:0] NES_DECAY = 20'd128;
    localparam [19:0] NES_SUSTAIN = 20'hC0000;
    localparam [19:0] NES_RELEASE = 20'd1024;

    localparam [23:0] LFO_BASE = 24'd310;
    localparam [23:0] LFO_STEP = 24'd11;
    localparam [4:0]  TREM_SH  = 5'd13;

    localparam [4:0]  TRIM_SH  = 5'd1;

    localparam [2:0] ST_IDLE = 3'd0;
    localparam [2:0] ST_ATK  = 3'd1;
    localparam [2:0] ST_DEC  = 3'd2;
    localparam [2:0] ST_SUS  = 3'd3;
    localparam [2:0] ST_REL  = 3'd4;

    reg [25:0] por   = 26'd0;
    reg        rst_n = 1'b0;
    assign core_rst_n = rst_n;
    always @(posedge sys_clk) begin
        if (por != POR_END) begin
            por   <= por + 26'd1;
            rst_n <= 1'b0;
        end else begin
            rst_n <= 1'b1;
        end
    end

    wire [15:0] key_data;
    wire [15:0] key_raw;
    wire        key_valid;

    ttp229_reader #(
        .CLK_HZ      (50_000_000),
        .T_START_US  (10),
        .T_HALF_US   (10),
        .T_SAMPLE_US (3),
        .T_GAP_US    (3000),
        .ACTIVE_LOW  (1)
    ) u_kb (
        .clk       (sys_clk),
        .rst_n     (rst_n),
        .scl       (touch_scl),
        .sdo       (touch_sdo),
        .key_data  (key_data),
        .raw_data  (key_raw),
        .key_valid (key_valid)
    );

    reg [15:0] key_stable;
    reg [4:0]  hit [0:15];
    reg [4:0]  miss[0:15];
    integer    d;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stable <= 16'd0;
            for (d = 0; d < 16; d = d + 1) begin
                hit[d]  <= 5'd0;
                miss[d] <= 5'd0;
            end
        end else if (key_valid) begin
            for (d = 0; d < 16; d = d + 1) begin
                if (key_data[d]) begin
                    miss[d] <= 5'd0;
                    if (hit[d] != KB_PRESS_TH) hit[d] <= hit[d] + 5'd1;
                    if (hit[d] >= KB_PRESS_TH) key_stable[d] <= 1'b1;
                end else begin
                    hit[d] <= 5'd0;
                    if (miss[d] != KB_REL_TH) miss[d] <= miss[d] + 5'd1;
                    if (miss[d] >= KB_REL_TH) key_stable[d] <= 1'b0;
                end
            end
        end
    end

    wire engine_test = (SELFTEST == 3) || (SELFTEST == 4);
    wire [15:0] kbd = (KEY16_E5 != 0) ? key_stable : {1'b0, key_stable[14:0]};
    wire [15:0] note_v_en;
    wire [15:0] gate = (SELFTEST == 1) ? 16'hFFFF
                     : engine_test     ? 16'h0001
                                       : (kbd & note_v_en);

    wire [31:0] step_tbl  [0:15];
    wire [0:0]  region_tbl[0:15];
    genvar gs;
    generate
        for (gs = 0; gs < 16; gs = gs + 1) begin : GEN_NOTE
            keyboard_pitch u_note (
                .idx    (gs[3:0]),
                .octave_select(active_octave),
                .midi(),
                .step   (step_tbl[gs]),
                .region (region_tbl[gs])
            );
        end
    endgenerate

    wire [31:0] step_v  [0:15];
    wire [0:0]  region_v[0:15];
    genvar gv;
    generate
        for (gv = 0; gv < 16; gv = gv + 1) begin : GEN_SV
            if (gv == 15) begin : G_TEST
                assign step_v[gv]   = (SELFTEST == 1)            ? 32'd28994347 :
                                      ((KEY16_E5 != 0) ? 32'd28994347 : step_tbl[gv]);
                assign region_v[gv] = (SELFTEST == 1)            ? 1'd1 :
                                      ((KEY16_E5 != 0) ? 1'd1         : region_tbl[gv]);
            end else begin : G_PLAIN
                assign step_v[gv]   = step_tbl[gv];
                assign region_v[gv] = region_tbl[gv];
            end
        end
    endgenerate

    genvar gx;
    generate
        for (gx = 0; gx < 16; gx = gx + 1) begin : GEN_VEN
            assign note_v_en[gx] = (step_v[gx] != 32'd0);
        end
    endgenerate

    wire [31:0] osc_gate;
    wire [31:0] note_step [0:15];
    wire [31:0] osc_step  [0:31];
    wire [0:0]  osc_region[0:31];
    wire        osc_en    [0:31];
    wire [23:0] lfo_step  [0:31];
    genvar gk, gu;
    generate
        for (gk = 0; gk < 16; gk = gk + 1) begin : GEN_KEYSLOT
            for (gu = 0; gu < 2; gu = gu + 1) begin : GEN_UNI
                assign osc_gate[gk*2+gu]   = gate[gk] &
                                             ((engine_test && (gu != 0)) ? 1'b0 : 1'b1);
                assign osc_step[gk*2+gu]   = note_step[gk] +
                                             ((gu != 0) ? (note_step[gk] >>> DET_SH) : 32'd0);
                assign osc_region[gk*2+gu] = region_v[gk];
                assign osc_en[gk*2+gu]     = (note_step[gk] != 32'd0);
                assign lfo_step[gk*2+gu]   = 24'd310 + (gk*2+gu)*24'd11;
            end
        end
    endgenerate

    wire        sample_tick;
    wire [15:0] idata;
    sound_mode_fade u_control(sys_clk,rst_n,sample_tick,timbre_select,vibrato_select,
        octave_select,active_timbre,active_vibrato,active_octave,transition_gain);

    wire [511:0] base_steps,mod_steps;
    dds_vibrato u_vibrato(sys_clk,rst_n,sample_tick,base_steps,mod_steps);
    genvar vm;
    generate for(vm=0;vm<16;vm=vm+1) begin:VIB_STEPS
      assign base_steps[vm*32 +:32]=step_v[vm];
      assign note_step[vm]=active_vibrato?mod_steps[vm*32 +:32]:step_v[vm];
    end endgenerate

    reg signed [15:0] voice_raw [0:31];
    reg signed [15:0] voice_lp  [0:31];
    reg [3:0]         lp_sh;
    function signed [15:0] smooth_sample;
        input signed [15:0] target, current;
        input [3:0] sh;
        reg signed [16:0] delta, magnitude, movement, result;
        begin
            delta=$signed({target[15],target})-$signed({current[15],current});
            magnitude=delta<0 ? -delta : delta;
            movement=magnitude>>>sh;
            if(movement==0 && magnitude!=0) movement=1;
            result=$signed({current[15],current})+(delta<0 ? -movement : movement);
            smooth_sample=result[15:0];
        end
    endfunction

    reg [31:0] phase [0:31];
    reg [19:0] env   [0:31];
    reg [23:0] lfo   [0:31];
    reg [2:0]  st    [0:31];
    reg [31:0] gate_d;
    reg timbre_d;

    reg        note_on_i, note_off_i;
    reg [20:0] att_next;
    integer    k;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < 32; k = k + 1) begin
                phase[k]    <= 32'd0;
                env[k]      <= 20'd0;
                lfo[k]      <= 24'd0;
                st[k]       <= ST_IDLE;
                voice_lp[k] <= 16'd0;
            end
            gate_d <= 32'd0;
            timbre_d <= 0;
        end else if (sample_tick) begin
            for (k = 0; k < 32; k = k + 1) begin
                note_on_i  =  osc_gate[k] && !gate_d[k];
                note_off_i = !osc_gate[k] &&  gate_d[k];

                if (!osc_en[k]) begin
                    env[k]<=0; st[k]<=ST_IDLE;
                end else if (note_on_i) begin
                    phase[k] <= phase[k] + osc_step[k];
                    st[k]    <= ST_ATK;
                end else if (note_off_i) begin
                    phase[k] <= phase[k] + osc_step[k];
                    st[k]    <= ST_REL;
                end else if (active_timbre != timbre_d && osc_gate[k]) begin
                    phase[k] <= phase[k] + osc_step[k];
                    st[k] <= active_timbre ? ST_ATK : ST_DEC;
                end else begin
                    case (st[k])
                        ST_ATK: begin
                            phase[k] <= phase[k] + osc_step[k];
                            att_next = {1'b0, env[k]} + {1'b0, (active_timbre ? NES_ATTACK : ATT_INC)};
                            if (att_next >= {1'b0, ENV_MAX}) begin
                                env[k] <= ENV_MAX;
                                st[k]  <= ST_DEC;
                            end else begin
                                env[k] <= att_next[19:0];
                            end
                        end
                        ST_DEC: begin
                            phase[k] <= phase[k] + osc_step[k];
                            lfo[k]   <= lfo[k] + lfo_step[k];
                            if (active_timbre) begin
                                if(env[k] <= NES_SUSTAIN + NES_DECAY) begin
                                    env[k] <= NES_SUSTAIN;
                                    st[k] <= ST_SUS;
                                end else env[k] <= env[k] - NES_DECAY;
                            end else if (env[k] <= SUS_LVL + (env[k] >> DEC_SH)) begin
                                env[k] <= SUS_LVL;
                                st[k]  <= ST_SUS;
                            end else begin
                                env[k] <= env[k] - (env[k] >> DEC_SH);
                            end
                        end
                        ST_SUS: begin
                            phase[k] <= phase[k] + osc_step[k];
                            lfo[k]   <= lfo[k] + lfo_step[k];
                            if (active_timbre) begin
                                env[k] <= NES_SUSTAIN;
                            end else if (env[k] <= (env[k] >> SUS_SH) + 20'd1) begin
                                env[k] <= 20'd0;
                                st[k]  <= ST_IDLE;
                            end else begin
                                env[k] <= env[k] - (env[k] >> SUS_SH) - 20'd1;
                            end
                        end
                        ST_REL: begin
                            phase[k] <= phase[k] + osc_step[k];
                            if(active_timbre) begin
                                if(env[k] <= NES_RELEASE) begin
                                    env[k] <= 0; st[k] <= ST_IDLE;
                                end else env[k] <= env[k] - NES_RELEASE;
                            end else if (env[k] <= (env[k] >> REL_SH) + 20'd1) begin
                                env[k] <= 20'd0;
                                st[k]  <= ST_IDLE;
                            end else begin
                                env[k] <= env[k] - (env[k] >> REL_SH) - 20'd1;
                            end
                        end
                        default: begin
                            st[k] <= ST_IDLE;
                        end
                    endcase
                end

                if (!note_on_i) begin
                    case (env[k][19:17])
                        3'd7, 3'd6: lp_sh = 4'd1;
                        3'd5, 3'd4: lp_sh = 4'd2;
                        3'd3, 3'd2: lp_sh = 4'd3;
                        default:    lp_sh = 4'd4;
                    endcase
                    voice_lp[k] <= active_timbre ? voice_raw[k]
                        : smooth_sample(voice_raw[k],voice_lp[k],lp_sh);
                end
            end
            gate_d <= osc_gate;
            timbre_d <= active_timbre;
        end
    end

    reg [4:0] vsel;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) vsel <= 5'd0;
        else        vsel <= (vsel == 5'd31) ? 5'd0 : vsel + 1'b1;
    end

    wire [7:0] wave_addr = phase[vsel][31:24];

    wire signed [15:0] wave_smp;
    wire signed [15:0] piano_smp, nes_smp;
    nes_pulse #(.DUTY(1)) u_nes(phase[vsel],nes_smp);
    assign wave_smp=active_timbre ? nes_smp : piano_smp;

    piano_wave u_wave (
        .region (osc_region[vsel]),
        .addr   (wave_addr),
        .dout   (piano_smp)
    );

    reg [19:0]         env_s;
    reg [23:0]         lfo_s;
    reg [15:0]         env16_w;
    reg [23:0]         env_vel_full;
    reg [15:0]         env16_v;
    reg [7:0]          tri8_w;
    reg signed [8:0]   dtr;
    reg signed [17:0]  env18;
    reg signed [35:0]  tprod;
    reg signed [35:0]  tmod;
    reg signed [18:0]  gsum;
    reg [15:0]         gain_sel;

    always @(*) begin
        env16_w      = env_s[19:4];
        env_vel_full = env16_w * {17'd0, VEL_DEF};
        env16_v      = env_vel_full[22:7];
        tri8_w       = lfo_s[23] ? (8'd255 - lfo_s[22:15])
                                 : lfo_s[22:15];
        dtr          = $signed({1'b0, tri8_w}) - 9'sd128;
        env18        = {2'b00, env16_v};
        tprod        = env18 * dtr;
        tmod         = ((SELFTEST == 4) || active_timbre) ? 36'sd0
                                       : (tprod >>> TREM_SH);
        gsum         = $signed({env18[17],env18}) + $signed(tmod[18:0]);
        if (gsum < 0)
            gain_sel = 16'd0;
        else if (gsum > 19'sd65535)
            gain_sel = 16'hFFFF;
        else
            gain_sel = gsum[15:0];
    end

    reg [4:0]         vsel_d1;
    reg [4:0]         vsel_d2;
    reg signed [15:0] wave_smp_r;
    reg signed [15:0] wave_2;
    reg [15:0]        gain_r;

    always @(posedge sys_clk) begin
        vsel_d1    <= vsel;
        vsel_d2    <= vsel_d1;
        env_s      <= env[vsel];
        lfo_s      <= lfo[vsel];
        wave_smp_r <= wave_smp;
        wave_2     <= wave_smp_r;
        gain_r     <= vsel_d1[0] ? {1'b0, gain_sel[15:1]} : gain_sel;
    end

    wire signed [33:0] vprod_full = $signed(wave_2) * $signed({1'b0, gain_r});
    wire signed [33:0] vprod_sh   = vprod_full >>> (16 + TRIM_SH);

    integer    m;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            for (m = 0; m < 32; m = m + 1) voice_raw[m] <= 16'd0;
        end else begin
            voice_raw[vsel_d2] <= vprod_sh[15:0];
        end
    end

    localparam [19:0] ACT_ENV_LVL = 20'd32768;

    reg [5:0] act_cnt;
    always @(posedge sys_clk) begin
        act_cnt <= (env[0]  > ACT_ENV_LVL) + (env[2]  > ACT_ENV_LVL)
                 + (env[4]  > ACT_ENV_LVL) + (env[6]  > ACT_ENV_LVL)
                 + (env[8]  > ACT_ENV_LVL) + (env[10] > ACT_ENV_LVL)
                 + (env[12] > ACT_ENV_LVL) + (env[14] > ACT_ENV_LVL)
                 + (env[16] > ACT_ENV_LVL) + (env[18] > ACT_ENV_LVL)
                 + (env[20] > ACT_ENV_LVL) + (env[22] > ACT_ENV_LVL)
                 + (env[24] > ACT_ENV_LVL) + (env[26] > ACT_ENV_LVL)
                 + (env[28] > ACT_ENV_LVL) + (env[30] > ACT_ENV_LVL);
    end

    reg [8:0] recip;
    always @(*) begin
        case (act_cnt)
            6'd1:    recip = 9'd256;
            6'd2:    recip = 9'd128;
            6'd3:    recip = 9'd85;
            6'd4:    recip = 9'd64;
            6'd5:    recip = 9'd51;
            6'd6:    recip = 9'd43;
            6'd7:    recip = 9'd37;
            6'd8:    recip = 9'd32;
            6'd9:    recip = 9'd28;
            6'd10:   recip = 9'd26;
            6'd11:   recip = 9'd23;
            6'd12:   recip = 9'd21;
            6'd13:   recip = 9'd20;
            6'd14:   recip = 9'd18;
            6'd15:   recip = 9'd17;
            6'd16:   recip = 9'd16;
            6'd17:   recip = 9'd15;
            6'd18:   recip = 9'd14;
            6'd19:   recip = 9'd13;
            6'd20:   recip = 9'd13;
            6'd21:   recip = 9'd12;
            6'd22:   recip = 9'd12;
            6'd23:   recip = 9'd11;
            6'd24:   recip = 9'd11;
            6'd25:   recip = 9'd10;
            6'd26:   recip = 9'd10;
            6'd27:   recip = 9'd9;
            6'd28:   recip = 9'd9;
            6'd29:   recip = 9'd9;
            6'd30:   recip = 9'd9;
            6'd31:   recip = 9'd8;
            6'd32:   recip = 9'd8;
            default: recip = 9'd256;
        endcase
    end

    localparam [9:0] SLEW_DIV = 10'd511;

    reg [9:0] slew_cnt;
    reg [8:0] recip_sm;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) slew_cnt <= 10'd0;
        else        slew_cnt <= (slew_cnt == SLEW_DIV) ? 10'd0 : slew_cnt + 10'd1;
    end

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n)                         recip_sm <= 9'd256;
        else if (slew_cnt == 10'd0) begin
            if      (recip_sm < recip)      recip_sm <= recip_sm + 9'd1;
            else if (recip_sm > recip)      recip_sm <= recip_sm - 9'd1;
        end
    end

    reg signed [20:0] mix_sum;
    reg signed [20:0] mix_eff;
    reg [8:0]         recip_eff;
    reg signed [31:0] ms_full;
    reg signed [31:0] ms_sh;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) mix_sum <= 21'sd0;
        else
        mix_sum <= voice_lp[0]  + voice_lp[1]  + voice_lp[2]  + voice_lp[3]
                 + voice_lp[4]  + voice_lp[5]  + voice_lp[6]  + voice_lp[7]
                 + voice_lp[8]  + voice_lp[9]  + voice_lp[10] + voice_lp[11]
                 + voice_lp[12] + voice_lp[13] + voice_lp[14] + voice_lp[15]
                 + voice_lp[16] + voice_lp[17] + voice_lp[18] + voice_lp[19]
                 + voice_lp[20] + voice_lp[21] + voice_lp[22] + voice_lp[23]
                 + voice_lp[24] + voice_lp[25] + voice_lp[26] + voice_lp[27]
                 + voice_lp[28] + voice_lp[29] + voice_lp[30] + voice_lp[31];
    end

    always @(*) begin
        mix_eff   = (SELFTEST == 4) ? {{5{voice_raw[0][15]}}, voice_raw[0]}
                                    : mix_sum;
        recip_eff = (SELFTEST == 4) ? 9'd256 : recip_sm;
        ms_full = $signed(mix_eff) * $signed({23'd0, recip_eff});
        ms_sh   = ms_full >>> 8;
    end

    reg [6:0] sq_div;
    reg       sq;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sq_div <= 7'd0;
            sq     <= 1'b0;
        end else if (sample_tick) begin
            if (sq_div == 7'd109) begin
                sq_div <= 7'd0;
                sq     <= ~sq;
            end else begin
                sq_div <= sq_div + 1'b1;
            end
        end
    end

    wire [3:0]  vol_code;
    wire [15:0] vol_coef;

    vol_ctrl #(
        .CLK_HZ      (50_000_000),
        .KEY_ACT_LOW (1),
        .DEB_MS      (20),
        .HOLD_MS     (300),
        .REP_MS      (150),
        .CODE_RST    (4'd13),
        .CODE_MAX    (4'd15)
    ) u_vol (
        .clk      (sys_clk),
        .rst_n    (rst_n),
        .key_up   (key_vol_up),
        .key_dn   (key_vol_dn),
        .vol_code (vol_code),
        .vol_coef (vol_coef)
    );

    localparam [3:0] VOL_RAMP_DIV = 4'd15;

    reg [3:0]  vol_rdv;
    reg [15:0] vol_sm;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            vol_rdv <= 4'd0;
            vol_sm  <= 16'd0;
        end else if (vol_rdv != VOL_RAMP_DIV) begin
            vol_rdv <= vol_rdv + 4'd1;
        end else begin
            vol_rdv <= 4'd0;
            if (vol_sm < vol_coef)
                vol_sm <= ((vol_coef - vol_sm) <= 16'd1) ? vol_coef
                                                        : vol_sm + 16'd1;
            else if (vol_sm > vol_coef)
                vol_sm <= ((vol_sm - vol_coef) <= 16'd1) ? vol_coef
                                                        : vol_sm - 16'd1;
        end
    end

    reg signed [31:0] ms_sh_r;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) ms_sh_r <= 32'sd0;
        else        ms_sh_r <= ms_sh;
    end

    wire [31:0] fade_product=vol_sm*transition_gain;
    reg signed [15:0] vol_sm_s;
    always @(posedge sys_clk or negedge rst_n) begin
        if(!rst_n) vol_sm_s<=0;
        else vol_sm_s<=fade_product[31:16];
    end
    wire signed [47:0] vol_full  = ms_sh_r * vol_sm_s;
    wire signed [32:0] vol_sh    = vol_full >>> 15;

    reg signed [15:0] idata_c;
    always @(*) begin
        if      (SELFTEST == 2)            idata_c = sq ? 16'sd8000 : -16'sd8000;
        else if (vol_sh >  33'sd32767)     idata_c =  16'sd32767;
        else if (vol_sh < -33'sd32768)     idata_c = -16'sd32768;
        else                               idata_c = vol_sh[15:0];
    end

    wire signed [15:0] metro_pcm,mixed_pcm;
    wire metro_quiet,mix_ready;
    metronome u_metronome(.clk(sys_clk),.rst_n(rst_n),.tick(sample_tick),
      .mode(metronome_mode),.mix_ready(mix_ready),.pcm(metro_pcm),
      .quiet(metro_quiet),.active_mode(),.beat_index(),.beat_event());
    pcm_mixer u_pcm_mix(.clk(sys_clk),.rst_n(rst_n),.tick(sample_tick),
      .reserve((metronome_mode!=0)||!metro_quiet),.keys(idata_c),
      .click(metro_pcm),.volume(vol_sm),.pcm(mixed_pcm),.ready(mix_ready));

    reg signed [15:0] idata_reg;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n)                        idata_reg <= 16'd0;
        else                               idata_reg <= mixed_pcm;
    end
    assign idata = idata_reg;

    wire [2:0]  ui_pan_i;
    wire [15:0] pan_coef_l, pan_coef_r;

    pan_ctrl #(
        .CLK_HZ      (50_000_000),
        .KEY_ACT_LOW (1),
        .DEB_MS      (20),
        .HOLD_MS     (600),
        .PAN_RST     (3'd0)
    ) u_pan (
        .clk       (sys_clk),
        .rst_n     (rst_n),
        .key_metro_n (metro_key_n),
        .pan_mode  (ui_pan_i),
        .coef_l    (pan_coef_l),
        .coef_r    (pan_coef_r),
        .metro_step(metro_step)
    );

    wire signed [32:0] pan_l_full = $signed(idata) * $signed({1'b0, pan_coef_l});
    wire signed [32:0] pan_r_full = $signed(idata) * $signed({1'b0, pan_coef_r});
    wire signed [32:0] pan_l_sh   = pan_l_full >>> 15;
    wire signed [32:0] pan_r_sh   = pan_r_full >>> 15;

    reg signed [15:0] pcm_l, pcm_r;
    always @(*) begin
        if      (pan_l_sh >  33'sd32767) pcm_l =  16'sd32767;
        else if (pan_l_sh < -33'sd32768) pcm_l = -16'sd32768;
        else                             pcm_l = pan_l_sh[15:0];
        if      (pan_r_sh >  33'sd32767) pcm_r =  16'sd32767;
        else if (pan_r_sh < -33'sd32768) pcm_r = -16'sd32768;
        else                             pcm_r = pan_r_sh[15:0];
    end

    pt8211_tx #(
        .BCK_DIV (8)
    ) u_dac (
        .clk         (sys_clk),
        .rst_n       (rst_n),
        .sample_l    (pcm_l),
        .sample_r    (pcm_r),
        .sample_tick (sample_tick),
        .bck         (hp_bck),
        .ws          (hp_ws),
        .din         (hp_din)
    );

    assign pa_en = 1'b0;

    reg [12:0] d100_cnt;
    reg [11:0] frame_100;
    reg [9:0]  lat_us;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            d100_cnt  <= 13'd0;
            frame_100 <= 12'd0;
            lat_us    <= 10'd0;
        end else begin
            if (d100_cnt == 13'd4999) begin
                d100_cnt  <= 13'd0;
                frame_100 <= frame_100 + 12'd1;
            end else begin
                d100_cnt <= d100_cnt + 13'd1;
            end

            if (key_valid) begin
                if ((frame_100 > 12'd10) && (frame_100 < 12'd200))
                    lat_us <= frame_100 * (KB_PRESS_TH + 5'd1);
                frame_100 <= 12'd0;
            end
        end
    end

    reg signed [15:0] ui_pcm_delay;
    always @(posedge sys_clk) ui_pcm_delay <= idata;
    assign ui_keys     = key_stable[14:0];
    assign ui_key16    = key_stable[15];
    assign ui_vol_code = vol_code;
    assign ui_lat      = lat_us;
    assign ui_pan      = ui_pan_i;
    assign ui_octave   = active_octave;
    assign ui_timbre   = active_timbre;
    assign ui_sample_tick = sample_tick;
    assign ui_pcm      = ui_pcm_delay;
endmodule

