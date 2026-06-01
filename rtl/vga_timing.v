`timescale 1ns/1ps

module vga_timing (
    input  wire       clk,
    input  wire       rst,
    input  wire       pixel_tick,
    output reg        hsync,
    output reg        vsync,
    output wire       video_on,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y,
    output wire       frame_tick
);
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

    reg [9:0] h_count;
    reg [9:0] v_count;

    always @(posedge clk) begin
        if (rst) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else if (pixel_tick) begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 10'd0;
                end else begin
                    v_count <= v_count + 10'd1;
                end
            end else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            hsync <= ~((h_count >= (H_VISIBLE + H_FRONT)) &&
                       (h_count <  (H_VISIBLE + H_FRONT + H_SYNC)));
            vsync <= ~((v_count >= (V_VISIBLE + V_FRONT)) &&
                       (v_count <  (V_VISIBLE + V_FRONT + V_SYNC)));
        end
    end

    assign video_on  = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
    assign pixel_x   = h_count;
    assign pixel_y   = v_count;
    assign frame_tick = pixel_tick && (h_count == H_TOTAL - 1) && (v_count == V_TOTAL - 1);
endmodule
