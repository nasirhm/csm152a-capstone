`timescale 1ns/1ps

module flappy_game_core #(
    parameter SCREEN_W     = 640,
    parameter SCREEN_H     = 480,
    parameter GROUND_H     = 40,
    parameter BIRD_X       = 120,
    parameter BIRD_SIZE    = 16,
    parameter PIPE_W       = 64,
    parameter PIPE_GAP_H   = 120,
    parameter PIPE_SPEED   = 3,
    parameter PIPE_SPACING = 260,
    parameter INIT_GAP_Y   = 180,
    parameter JUMP_VEL     = -8,
    parameter GRAVITY      = 1,
    parameter MAX_FALL     = 12
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        frame_tick,
    input  wire        jump_btn,

    output reg  [1:0]  game_state,
    output reg  [7:0]  score,
    output reg         game_over,

    output wire [9:0]  bird_x,
    output reg  [9:0]  bird_y,

    output reg  [9:0]  pipe0_x,
    output reg  [9:0]  pipe1_x,
    output reg  [8:0]  pipe0_gap_y,
    output reg  [8:0]  pipe1_gap_y
);
    localparam STATE_START    = 2'd0;
    localparam STATE_PLAYING  = 2'd1;
    localparam STATE_GAMEOVER = 2'd2;

    localparam MIN_GAP_Y = 40;
    localparam MAX_GAP_Y = SCREEN_H - GROUND_H - PIPE_GAP_H - 40;

    reg signed [7:0] bird_v;
    reg [15:0] lfsr;
    reg        pipe0_passed;
    reg        pipe1_passed;

    integer next_v;
    integer next_y;
    integer p0_next_x;
    integer p1_next_x;
    integer p0_spawn;
    integer p1_spawn;
    integer new_gap;
    reg     collision;

    assign bird_x = BIRD_X[9:0];

    always @(posedge clk) begin
        if (rst) begin
            game_state   <= STATE_START;
            score        <= 8'd0;
            game_over    <= 1'b0;

            bird_y       <= (SCREEN_H / 2);
            bird_v       <= 8'sd0;

            pipe0_x      <= SCREEN_W + 10'd120;
            pipe1_x      <= SCREEN_W + 10'd120 + PIPE_SPACING;
            pipe0_gap_y  <= INIT_GAP_Y;
            pipe1_gap_y  <= INIT_GAP_Y + 9'd20;

            pipe0_passed <= 1'b0;
            pipe1_passed <= 1'b0;
            lfsr         <= 16'h1ACE;
        end else if (frame_tick) begin
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

            case (game_state)
                STATE_START: begin
                    game_over    <= 1'b0;
                    score        <= 8'd0;
                    bird_y       <= (SCREEN_H / 2);
                    bird_v       <= 8'sd0;
                    pipe0_x      <= SCREEN_W + 10'd120;
                    pipe1_x      <= SCREEN_W + 10'd120 + PIPE_SPACING;
                    pipe0_gap_y  <= INIT_GAP_Y;
                    pipe1_gap_y  <= INIT_GAP_Y + 9'd20;
                    pipe0_passed <= 1'b0;
                    pipe1_passed <= 1'b0;

                    if (jump_btn) begin
                        game_state <= STATE_PLAYING;
                        bird_v     <= JUMP_VEL;
                    end
                end

                STATE_PLAYING: begin
                    next_v = bird_v + GRAVITY;
                    if (next_v > MAX_FALL) begin
                        next_v = MAX_FALL;
                    end
                    if (jump_btn) begin
                        next_v = JUMP_VEL;
                    end

                    next_y = $signed({1'b0, bird_y}) + next_v;
                    if (next_y < 0) begin
                        next_y = 0;
                    end
                    bird_v <= next_v[7:0];
                    bird_y <= next_y[9:0];

                    p0_next_x = pipe0_x - PIPE_SPEED;
                    p1_next_x = pipe1_x - PIPE_SPEED;

                    if ((pipe0_x + PIPE_W) <= BIRD_X && !pipe0_passed) begin
                        pipe0_passed <= 1'b1;
                        score <= score + 8'd1;
                    end
                    if ((pipe1_x + PIPE_W) <= BIRD_X && !pipe1_passed) begin
                        pipe1_passed <= 1'b1;
                        score <= score + 8'd1;
                    end

                    // p0_next_x is signed (integer), so it goes negative once the
                    // pipe scrolls off the left edge. Recycle the pipe there and
                    // re-arm pipe0_passed so it can score again on the next lap.
                    if (p0_next_x <= 0) begin
                        p0_spawn     = pipe1_x + PIPE_SPACING;
                        if (p0_spawn < SCREEN_W) p0_spawn = SCREEN_W; // enter from the right edge, no on-screen pop
                        new_gap      = MIN_GAP_Y + (lfsr[7:0] % (MAX_GAP_Y - MIN_GAP_Y + 1));
                        pipe0_x      <= p0_spawn[9:0];
                        pipe0_gap_y  <= new_gap[8:0];
                        pipe0_passed <= 1'b0;
                    end else begin
                        pipe0_x <= p0_next_x[9:0];
                    end

                    if (p1_next_x <= 0) begin
                        p1_spawn     = pipe0_x + PIPE_SPACING;
                        if (p1_spawn < SCREEN_W) p1_spawn = SCREEN_W;
                        new_gap      = MIN_GAP_Y + (lfsr[15:8] % (MAX_GAP_Y - MIN_GAP_Y + 1));
                        pipe1_x      <= p1_spawn[9:0];
                        pipe1_gap_y  <= new_gap[8:0];
                        pipe1_passed <= 1'b0;
                    end else begin
                        pipe1_x <= p1_next_x[9:0];
                    end

                    collision = 1'b0;

                    if ((bird_y + BIRD_SIZE) >= (SCREEN_H - GROUND_H)) begin
                        collision = 1'b1;
                    end

                    if (bird_y == 0) begin
                        collision = 1'b1;
                    end

                    if (((BIRD_X + BIRD_SIZE) > pipe0_x) && (BIRD_X < (pipe0_x + PIPE_W))) begin
                        if ((bird_y < pipe0_gap_y) || ((bird_y + BIRD_SIZE) > (pipe0_gap_y + PIPE_GAP_H))) begin
                            collision = 1'b1;
                        end
                    end

                    if (((BIRD_X + BIRD_SIZE) > pipe1_x) && (BIRD_X < (pipe1_x + PIPE_W))) begin
                        if ((bird_y < pipe1_gap_y) || ((bird_y + BIRD_SIZE) > (pipe1_gap_y + PIPE_GAP_H))) begin
                            collision = 1'b1;
                        end
                    end

                    if (collision) begin
                        game_state <= STATE_GAMEOVER;
                        game_over  <= 1'b1;
                    end
                end

                default: begin
                    if (jump_btn) begin
                        game_state <= STATE_START;
                    end
                end
            endcase
        end
    end
endmodule
