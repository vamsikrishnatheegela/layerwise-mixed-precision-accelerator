# Clock: 100 MHz
create_clock -name clk -period 10.000 [get_ports clk]

# Clock uncertainty
set_clock_uncertainty 0.200 [get_clocks clk]

# Input arrival times relative to the clock
set_input_delay 1.000 -clock clk \
    [get_ports {enable clear_acc precision_mode activation* weight*}]

# Output required time relative to the clock
set_output_delay 1.000 -clock clk [get_ports accumulator*]

# Input transition assumption
set_input_transition 0.100 \
    [get_ports {enable clear_acc precision_mode activation* weight*}]
