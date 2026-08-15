# Allow the combinational ALU 8 ns of a 10 ns CPU clock period.
set_max_delay -datapath_only 8.000 -from [all_inputs] -to [all_outputs]
