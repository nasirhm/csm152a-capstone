`timescale 1ns/1ps

module score_display (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] score,
    output reg  [3:0] an,
    output wire [6:0] seg,
    output wire       dp
);
    reg [15:0] refresh_cnt;
    reg        mux_sel;
    reg [3:0]  digit;

    wire [3:0] ones = score % 10;
    wire [3:0] tens = (score / 10) % 10;

    seg7_decoder u_seg7 (
        .digit(digit),
        .seg(seg)
    );

    assign dp = 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            refresh_cnt <= 16'd0;
            mux_sel     <= 1'b0;
        end else begin
            refresh_cnt <= refresh_cnt + 16'd1;
            if (refresh_cnt == 16'd0) begin
                mux_sel <= ~mux_sel;
            end
        end
    end

    always @(*) begin
        if (mux_sel) begin
            an    = 4'b1101;
            digit = tens;
        end else begin
            an    = 4'b1110;
            digit = ones;
        end
    end
endmodule
