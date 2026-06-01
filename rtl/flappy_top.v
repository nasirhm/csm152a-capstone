`timescale 1ns/1ps

module flappy_top (
    input  wire       clk,
    input  wire       btn_reset,
    input  wire       btn_jump,

    output wire       vga_hsync,
    output wire       vga_vsync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,

    output wire [6:0] seg,
    output wire [3:0] an,
    output wire       dp,
    output wire [2:0] led
);
    reg [1:0] pix_div;
    wire pixel_tick;

    reg jump_meta;
    reg jump_sync;
    reg jump_prev;
    wire jump_pulse;

    reg jump_latched;
    wire jump_cmd;

    wire [1:0] game_state;
    wire [7:0] score;
    wire game_over;

    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire video_on;
    wire frame_tick;

    wire [9:0] bird_x;
    wire [9:0] bird_y;
    wire [9:0] pipe0_x;
    wire [9:0] pipe1_x;
    wire [8:0] pipe0_gap_y;
    wire [8:0] pipe1_gap_y;

    always @(posedge clk) begin
        if (btn_reset) begin
            pix_div <= 2'd0;
        end else begin
            pix_div <= pix_div + 2'd1;
        end
    end

    assign pixel_tick = (pix_div == 2'b00);

    always @(posedge clk) begin
        if (btn_reset) begin
            jump_meta <= 1'b0;
            jump_sync <= 1'b0;
            jump_prev <= 1'b0;
        end else begin
            jump_meta <= btn_jump;
            jump_sync <= jump_meta;
            jump_prev <= jump_sync;
        end
    end

    assign jump_pulse = jump_sync & ~jump_prev;

    always @(posedge clk) begin
        if (btn_reset) begin
            jump_latched <= 1'b0;
        end else begin
            if (jump_pulse) begin
                jump_latched <= 1'b1;
            end
            if (frame_tick && jump_latched) begin
                jump_latched <= 1'b0;
            end
        end
    end

    assign jump_cmd = frame_tick && jump_latched;

    vga_timing u_vga_timing (
        .clk(clk),
        .rst(btn_reset),
        .pixel_tick(pixel_tick),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .frame_tick(frame_tick)
    );

    flappy_game_core u_game_core (
        .clk(clk),
        .rst(btn_reset),
        .frame_tick(frame_tick),
        .jump_btn(jump_cmd),
        .game_state(game_state),
        .score(score),
        .game_over(game_over),
        .bird_x(bird_x),
        .bird_y(bird_y),
        .pipe0_x(pipe0_x),
        .pipe1_x(pipe1_x),
        .pipe0_gap_y(pipe0_gap_y),
        .pipe1_gap_y(pipe1_gap_y)
    );

    flappy_renderer u_renderer (
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .game_state(game_state),
        .bird_x(bird_x),
        .bird_y(bird_y),
        .pipe0_x(pipe0_x),
        .pipe1_x(pipe1_x),
        .pipe0_gap_y(pipe0_gap_y),
        .pipe1_gap_y(pipe1_gap_y),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

    score_display u_score_display (
        .clk(clk),
        .rst(btn_reset),
        .score(score),
        .an(an),
        .seg(seg),
        .dp(dp)
    );

    assign led[0] = (game_state == 2'd0);
    assign led[1] = (game_state == 2'd1);
    assign led[2] = game_over;
endmodule
