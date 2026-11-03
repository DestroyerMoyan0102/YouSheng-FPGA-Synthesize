`timescale 1ns/1ps
module ec11_octave #(
    parameter integer CLK_HZ=50_000_000,
    parameter integer AB_FILTER_US=100,
    parameter integer SW_DEBOUNCE_MS=10,
    parameter integer EDGES_PER_DETENT=4,
    parameter integer REVERSE=0,
    parameter [1:0] DETENT_AB=2'b11
)(
    input wire clk,rst_n,enc_clk,enc_dt,enc_sw_n,
    output reg [1:0] octave_index,
    output reg step_event,step_up,home_event,invalid_transition
);
    function integer bits_needed;
        input integer value;
        integer v;
        begin
            v=value-1;bits_needed=0;
            while(v>0)begin bits_needed=bits_needed+1;v=v>>1;end
            if(bits_needed<1)bits_needed=1;
        end
    endfunction
    localparam integer AB_RAW=(CLK_HZ/1_000_000)*AB_FILTER_US;
    localparam integer AB_CYCLES=AB_RAW<2 ? 2 : AB_RAW;
    localparam integer SW_RAW=(CLK_HZ/1000)*SW_DEBOUNCE_MS;
    localparam integer SW_CYCLES=SW_RAW<2 ? 2 : SW_RAW;
    localparam integer AW=bits_needed(AB_CYCLES),SW=bits_needed(SW_CYCLES);
    (* syn_preserve=1, async_reg="true" *) reg [2:0] a_sync,b_sync,s_sync;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin a_sync<=3'b111;b_sync<=3'b111;s_sync<=3'b111;end
        else begin
            a_sync<={a_sync[1:0],enc_clk};
            b_sync<={b_sync[1:0],enc_dt};
            s_sync<={s_sync[1:0],enc_sw_n};
        end
    end
    wire [1:0] ab_sync={a_sync[2],b_sync[2]};
    reg [1:0] ab_candidate,ab_filtered;
    reg [AW-1:0] ab_count;
    reg ab_ready;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            ab_candidate<=2'b11;ab_filtered<=2'b11;ab_count<=0;ab_ready<=0;
        end else if(ab_sync!=ab_candidate)begin
            ab_candidate<=ab_sync;ab_count<=0;
        end else if(ab_count==AB_CYCLES-1)begin
            ab_filtered<=ab_candidate;ab_ready<=1;
        end else ab_count<=ab_count+1'b1;
    end
    reg sw_candidate,sw_filtered,sw_ready,sw_previous,sw_armed;
    reg [SW-1:0] sw_count;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            sw_candidate<=1;sw_filtered<=1;sw_count<=0;sw_ready<=0;
        end else if(s_sync[2]!=sw_candidate)begin
            sw_candidate<=s_sync[2];sw_count<=0;
        end else if(sw_count==SW_CYCLES-1)begin
            sw_filtered<=sw_candidate;sw_ready<=1;
        end else sw_count<=sw_count+1'b1;
    end
    wire sw_down=sw_ready && !sw_filtered;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin sw_previous<=1;sw_armed<=0;home_event<=0;end
        else begin
            home_event<=0;sw_previous<=sw_filtered;
            if(sw_ready)begin
                if(sw_filtered)sw_armed<=1;
                else if(sw_previous && sw_armed)begin
                    home_event<=1;sw_armed<=0;
                end
            end
        end
    end
    function at_detent;
        input [1:0] state;
        begin
            at_detent=(state==DETENT_AB) ||
                ((EDGES_PER_DETENT==2) && (state==~DETENT_AB));
        end
    endfunction
    reg [1:0] previous;
    reg started,anchored;
    reg signed [3:0] movement;
    reg signed [4:0] edge_delta,next_movement;
    always @* begin
        edge_delta=0;
        case({previous,ab_filtered})
            4'b1101,4'b0100,4'b0010,4'b1011:edge_delta=5'sd1;
            4'b1110,4'b1000,4'b0001,4'b0111:edge_delta=-5'sd1;
            default:edge_delta=0;
        endcase
        next_movement=$signed({movement[3],movement})+edge_delta;
    end
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            previous<=2'b11;started<=0;anchored<=0;movement<=0;
            step_event<=0;step_up<=0;invalid_transition<=0;
        end else begin
            step_event<=0;invalid_transition<=0;
            if(!ab_ready || !sw_ready)begin started<=0;anchored<=0;movement<=0;end
            else if(!started)begin
                previous<=ab_filtered;started<=1;
                anchored<=at_detent(ab_filtered);movement<=0;
            end else if(sw_down || home_event)begin
                previous<=ab_filtered;movement<=0;anchored<=0;
            end else if(ab_filtered!=previous)begin
                previous<=ab_filtered;
                if((previous^ab_filtered)==2'b11)begin
                    movement<=0;anchored<=0;invalid_transition<=1;
                end else if(!anchored)begin
                    movement<=0;
                    if(at_detent(ab_filtered))anchored<=1;
                end else if(at_detent(ab_filtered))begin
                    movement<=0;
                    if(next_movement==EDGES_PER_DETENT)begin
                        step_event<=1;step_up<=(REVERSE==0);
                    end else if(next_movement==-EDGES_PER_DETENT)begin
                        step_event<=1;step_up<=(REVERSE!=0);
                    end
                end else movement<=next_movement[3:0];
            end else if(!anchored && at_detent(ab_filtered))begin
                anchored<=1;movement<=0;
            end
        end
    end
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)octave_index<=2'd1;
        else if(home_event)octave_index<=2'd1;
        else if(step_event && !sw_down)begin
            if(step_up)begin
                if(octave_index!=2'd3)octave_index<=octave_index+2'd1;
            end else if(octave_index!=2'd0)octave_index<=octave_index-2'd1;
        end
    end
    // synthesis translate_off
    initial begin
        if(EDGES_PER_DETENT!=2 && EDGES_PER_DETENT!=4)begin
            $display("EDGES_PER_DETENT must be 2 or 4");$finish;
        end
    end
    // synthesis translate_on
endmodule
