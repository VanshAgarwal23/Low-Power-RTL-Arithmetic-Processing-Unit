set ::env(DESIGN_NAME) pipelined_apu

set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/*.v]

set ::env(CLOCK_PORT) clk
set ::env(CLOCK_PERIOD) 10.0

set ::env(FP_CORE_UTIL) 35
set ::env(PL_TARGET_DENSITY) 0.55

set ::env(FP_ASPECT_RATIO) 1
set ::env(ROUTING_CORES) 4
