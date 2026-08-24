create_clock -name clk -period 20.000 -waveform {0.000 10.000} [get_ports clk]


set_input_delay -clock clk 8.000 [get_ports {inst[*]}]
set_input_delay -clock clk 8.000 [get_ports rst]
set_output_delay -clock clk 8.000 [get_ports {alu_ctrl[*]}]

set_output_delay -clock clk 8.000 [get_ports {pc_out[*]}]
set_output_delay -clock clk 8.000 [get_ports illegal_out]