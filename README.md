# Flappy Bird in Verilog (FPGA/VGA)

This project implements a Flappy Bird clone in synthesizable Verilog, aligned with the capstone proposal requirements:

- VGA output with bird, pipes, and background rendering
- Gravity + jump-based bird motion
- Moving pipe obstacles with pseudo-random gap heights
- Collision detection with pipes/ground
- FSM with `START`, `PLAYING`, and `GAME_OVER`
- Score counting for passed pipes
- Seven-segment score display and LED state indication

## File Layout

- `rtl/flappy_top.v`: top-level integration for FPGA
- `rtl/vga_timing.v`: 640x480@60Hz timing generator (25 MHz pixel tick from main clock)
- `rtl/flappy_game_core.v`: gameplay FSM, physics, pipes, collision, score
- `rtl/flappy_renderer.v`: per-pixel RGB generation
- `rtl/seg7_decoder.v`: BCD digit to 7-segment map
- `rtl/score_display.v`: multiplexed 2-digit score output
- `tb/flappy_game_core_tb.v`: local self-checking simulation testbench
- `Makefile`: simulation/lint targets

## Local Test (Icarus Verilog)

```bash
make sim
```

Expected output includes:

```text
PASS: flappy_game_core basic behavior validated
```

To run syntax/lint check on RTL only:

```bash
make lint
```

## Vivado Notes

1. Add all files from `rtl/` as design sources.
2. Optionally add `tb/flappy_game_core_tb.v` as simulation source.
3. For Basys 3, add `constraints/Basys-3-Master.xdc` as a constraints source.
4. Basys 3 mapping in this project:
   - `btn_reset` = `BTN_C`
   - `btn_jump` = `BTN_U`
   - `led[2:0]` = `LED0..LED2`
   - `vga_*` use the onboard 12-bit VGA connector; `seg`, `an`, `dp` use the standard Digilent Basys 3 pins
