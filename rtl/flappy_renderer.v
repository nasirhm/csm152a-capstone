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

    wire in_pipe0_x = (pixel_x >= pipe0_x) && (pixel_x < (pipe0_x + PIPE_W));
    wire in_pipe1_x = (pixel_x >= pipe1_x) && (pixel_x < (pipe1_x + PIPE_W));

    wire in_pipe0 = in_pipe0_x && ((pixel_y < pipe0_gap_y) || (pixel_y > (pipe0_gap_y + PIPE_GAP_H)));
    wire in_pipe1 = in_pipe1_x && ((pixel_y < pipe1_gap_y) || (pixel_y > (pipe1_gap_y + PIPE_GAP_H)));

    wire in_start_banner = (pixel_x > 160) && (pixel_x < 480) && (pixel_y > 200) && (pixel_y < 280);
    wire in_over_banner  = (pixel_x > 170) && (pixel_x < 470) && (pixel_y > 180) && (pixel_y < 300);

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

            if (in_bird) begin
                vga_r = 4'hF;
                vga_g = 4'hE;
                vga_b = 4'h0;
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
