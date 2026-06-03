`timescale 1ns/1ps

module flappy_game_core_tb;
    reg clk;
    reg rst;
    reg frame_tick;
    reg jump_btn;

    wire [1:0] game_state;
    wire [7:0] score;
    wire game_over;
    wire [9:0] bird_x;
    wire [9:0] bird_y;
    wire [9:0] pipe0_x;
    wire [9:0] pipe1_x;
    wire [8:0] pipe0_gap_y;
    wire [8:0] pipe1_gap_y;

    integer i;
    reg [9:0] y_before;
    reg saw_score;
    reg saw_gameover;
    reg [7:0] max_score;

    flappy_game_core #(
        .SCREEN_W(160),
        .SCREEN_H(240),
        .GROUND_H(20),
        .BIRD_X(40),
        .BIRD_SIZE(8),
        .PIPE_W(16),
        .PIPE_GAP_H(80),
        .PIPE_SPEED(4),
        .PIPE_SPACING(70),
        .INIT_GAP_Y(80),
        .JUMP_VEL(-4),
        .GRAVITY(1),
        .MAX_FALL(5)
    ) dut (
        .clk(clk),
        .rst(rst),
        .frame_tick(frame_tick),
        .jump_btn(jump_btn),
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

    always #5 clk = ~clk;

    task do_frame;
        begin
            frame_tick = 1'b1;
            @(posedge clk);
            @(posedge clk);
            frame_tick = 1'b0;
            @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        frame_tick = 1'b0;
        jump_btn = 1'b0;

        repeat (4) @(posedge clk);
        rst = 1'b0;

        do_frame();
        if (game_state !== 2'd0) begin
            $display("FAIL: expected STATE_START after reset");
            $fatal;
        end

        jump_btn = 1'b1;
        do_frame();
        jump_btn = 1'b0;

        if (game_state !== 2'd1) begin
            $display("FAIL: jump from start did not enter STATE_PLAYING");
            $fatal;
        end

        y_before = bird_y;
        do_frame();
        do_frame();
        if (bird_y == y_before) begin
            $display("FAIL: bird_y did not move during play");
            $fatal;
        end

        saw_score = 1'b0;
        max_score = 8'd0;
        for (i = 0; i < 1200; i = i + 1) begin
            // Crude autopilot: flap toward the vertical middle. On game over,
            // tap to restart so the bird keeps attempting and accumulates laps.
            if (game_state == 2'd2) begin
                jump_btn = (i[2:0] == 3'd0);
            end else if (bird_y > 10'd110) begin
                jump_btn = 1'b1;
            end else begin
                jump_btn = 1'b0;
            end

            do_frame();

            if (score > 0) begin
                saw_score = 1'b1;
            end
            if (score > max_score) begin
                max_score = score;
            end
        end

        if (!saw_score) begin
            $display("FAIL: score never incremented");
            $fatal;
        end

        // Regression guard: the old unsigned recycle test never re-armed the
        // pipes, so the score was permanently stuck at 2. Require it to exceed
        // the pipe count to prove pipes recycle and keep scoring.
        if (max_score <= 8'd2) begin
            $display("FAIL: score capped at %0d (pipes not recycling)", max_score);
            $fatal;
        end
        $display("INFO: max score reached = %0d", max_score);

        saw_gameover = 1'b0;
        jump_btn = 1'b0;
        for (i = 0; i < 350; i = i + 1) begin
            do_frame();
            if (game_state == 2'd2) begin
                saw_gameover = 1'b1;
            end
        end

        if (!saw_gameover) begin
            $display("FAIL: expected eventual game over (ground/pipe collision)");
            $fatal;
        end

        rst = 1'b1;
        repeat (3) @(posedge clk);
        rst = 1'b0;
        do_frame();

        if (score !== 8'd0 || game_state !== 2'd0) begin
            $display("FAIL: reset did not restore start state and zero score");
            $fatal;
        end

        $display("PASS: flappy_game_core basic behavior validated");
        $finish;
    end
endmodule
