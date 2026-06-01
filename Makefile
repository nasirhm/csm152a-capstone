SIM_OUT := sim/flappy_tb.out
VVP_OUT := sim/flappy_tb.vvp

RTL := rtl/vga_timing.v rtl/flappy_game_core.v rtl/flappy_renderer.v rtl/seg7_decoder.v rtl/score_display.v rtl/flappy_top.v
TB  := tb/flappy_game_core_tb.v

.PHONY: sim clean lint

sim:
	iverilog -g2012 -Wall -o $(VVP_OUT) $(RTL) $(TB)
	vvp $(VVP_OUT) | tee $(SIM_OUT)

lint:
	iverilog -g2012 -Wall -t null $(RTL)

clean:
	rm -f sim/*.vvp sim/*.out
