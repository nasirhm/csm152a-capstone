`timescale 1ns/1ps

module flappy_renderer #(
    parameter SCREEN_W   = 640,
    parameter SCREEN_H   = 480,
    parameter GROUND_H   = 40,
    parameter BIRD_SIZE  = 16,
    parameter PIPE_W     = 64,
    parameter PIPE_GAP_H = 120
) (
    input  wire       video_on,
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,

    input  wire [1:0] game_state,
    input  wire [9:0] bird_x,
    input  wire [9:0] bird_y,
    input  wire [9:0] pipe0_x,
    input  wire [9:0] pipe1_x,
    input  wire [8:0] pipe0_gap_y,
    input  wire [8:0] pipe1_gap_y,

    output reg  [3:0] vga_r,
    output reg  [3:0] vga_g,
    output reg  [3:0] vga_b
);
    localparam STATE_START    = 2'd0;
    localparam STATE_PLAYING  = 2'd1;
    localparam STATE_GAMEOVER = 2'd2;

    wire in_ground = (pixel_y >= (SCREEN_H - GROUND_H));
    wire in_bird = (pixel_x >= bird_x) && (pixel_x < (bird_x + BIRD_SIZE)) &&
                   (pixel_y >= bird_y) && (pixel_y < (bird_y + BIRD_SIZE));

    // Pixel offset within the bird's 16x16 bounding box (valid only when in_bird).
    wire [9:0] bird_rel_x = pixel_x - bird_x;
    wire [9:0] bird_rel_y = pixel_y - bird_y;

    // 2-bit sprite color index for the current bird-local pixel.
    //   0 = transparent (show background)   2 = beak (orange)
    //   1 = body (yellow)                   3 = eye  (dark)
    wire [1:0] bird_color = bird_sprite(bird_rel_y[3:0], bird_rel_x[3:0]);
    wire       in_bird_px = in_bird && (bird_color != 2'd0);

    wire in_pipe0_x = (pixel_x >= pipe0_x) && (pixel_x < (pipe0_x + PIPE_W));
    wire in_pipe1_x = (pixel_x >= pipe1_x) && (pixel_x < (pipe1_x + PIPE_W));

    wire in_pipe0 = in_pipe0_x && ((pixel_y < pipe0_gap_y) || (pixel_y > (pipe0_gap_y + PIPE_GAP_H)));
    wire in_pipe1 = in_pipe1_x && ((pixel_y < pipe1_gap_y) || (pixel_y > (pipe1_gap_y + PIPE_GAP_H)));

    wire in_start_banner = (pixel_x > 160) && (pixel_x < 480) && (pixel_y > 200) && (pixel_y < 280);
    wire in_over_banner  = (pixel_x > 170) && (pixel_x < 470) && (pixel_y > 180) && (pixel_y < 300);

    // 16x16 bird sprite, one 2-bit color per pixel. Each row is packed
    // {col15 .. col0}, so column `c` lives at bits [c*2 +: 2]. The shape is a
    // rounded yellow body with a dark eye (top-right) and an orange beak.
    function [1:0] bird_sprite;
        input [3:0] row;
        input [3:0] col;
        reg [31:0] bits;
        begin
            case (row)
                4'd2:  bits = {2'd0,2'd0,2'd0,2'd0,2'd0,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0,2'd0,2'd0,2'd0};
                4'd3:  bits = {2'd0,2'd0,2'd0,2'd0,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0,2'd0,2'd0};
                4'd4:  bits = {2'd0,2'd0,2'd0,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0,2'd0};
                4'd5:  bits = {2'd0,2'd0,2'd1,2'd1,2'd3,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0};
                4'd6:  bits = {2'd0,2'd0,2'd1,2'd3,2'd3,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0};
                4'd7:  bits = {2'd2,2'd2,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0};
                4'd8:  bits = {2'd2,2'd2,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0};
                4'd9:  bits = {2'd0,2'd0,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0};
                4'd10: bits = {2'd0,2'd0,2'd0,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0,2'd0};
                4'd11: bits = {2'd0,2'd0,2'd0,2'd0,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0,2'd0,2'd0};
                4'd12: bits = {2'd0,2'd0,2'd0,2'd0,2'd0,2'd1,2'd1,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0,2'd0,2'd0,2'd0};
                4'd13: bits = {2'd0,2'd0,2'd0,2'd0,2'd0,2'd0,2'd1,2'd1,2'd1,2'd1,2'd0,2'd0,2'd0,2'd0,2'd0,2'd0};
                default: bits = 32'd0;
            endcase
            bird_sprite = bits[col*2 +: 2];
        end
    endfunction

    always @(*) begin
        if (!video_on) begin
            vga_r = 4'h0;
            vga_g = 4'h0;
            vga_b = 4'h0;
        end else begin
            vga_r = 4'h8;
            vga_g = 4'hC;
            vga_b = 4'hF;

            if (in_ground) begin
                vga_r = 4'h5;
                vga_g = 4'h3;
                vga_b = 4'h1;
            end

            if (in_pipe0 || in_pipe1) begin
                vga_r = 4'h0;
                vga_g = 4'hB;
                vga_b = 4'h2;
            end

            if (in_bird_px) begin
                case (bird_color)
                    2'd1: begin            // body: yellow
                        vga_r = 4'hF;
                        vga_g = 4'hE;
                        vga_b = 4'h0;
                    end
                    2'd2: begin            // beak: orange
                        vga_r = 4'hF;
                        vga_g = 4'h8;
                        vga_b = 4'h0;
                    end
                    default: begin         // eye: dark
                        vga_r = 4'h1;
                        vga_g = 4'h1;
                        vga_b = 4'h1;
                    end
                endcase
            end

            if (game_state == STATE_START && in_start_banner) begin
                vga_r = 4'hF;
                vga_g = 4'hF;
                vga_b = 4'hF;
            end

            if (game_state == STATE_GAMEOVER && in_over_banner) begin
                vga_r = 4'hF;
                vga_g = 4'h2;
                vga_b = 4'h2;
            end
        end
    end
endmodule
