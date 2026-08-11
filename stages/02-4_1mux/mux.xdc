## Arty A7-100T constraints for the 4-to-1, 4-bit mux stage.
##
## Board mapping:
##   a[3:0]   -> switches SW3-SW0
##   sel[1:0] -> buttons BTN1-BTN0
##   y[3:0]   -> user LEDs LD7-LD4
##   b[3:0]   -> Pmod JA pins 4-1
##   c[3:0]   -> Pmod JA pins 10, 9, 8, 7
##   d[3:0]   -> Pmod JB pins 4-1

## Input a: slide switches
set_property -dict { PACKAGE_PIN A8  IOSTANDARD LVCMOS33 } [get_ports {a[0]}];
set_property -dict { PACKAGE_PIN C11 IOSTANDARD LVCMOS33 } [get_ports {a[1]}];
set_property -dict { PACKAGE_PIN C10 IOSTANDARD LVCMOS33 } [get_ports {a[2]}];
set_property -dict { PACKAGE_PIN A10 IOSTANDARD LVCMOS33 } [get_ports {a[3]}];

## Select: push buttons
set_property -dict { PACKAGE_PIN D9 IOSTANDARD LVCMOS33 } [get_ports {sel[0]}];
set_property -dict { PACKAGE_PIN C9 IOSTANDARD LVCMOS33 } [get_ports {sel[1]}];

## Output y: user LEDs
set_property -dict { PACKAGE_PIN H5  IOSTANDARD LVCMOS33 } [get_ports {y[0]}];
set_property -dict { PACKAGE_PIN J5  IOSTANDARD LVCMOS33 } [get_ports {y[1]}];
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports {y[2]}];
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports {y[3]}];

## Input b: Pmod JA pins 1-4
set_property -dict { PACKAGE_PIN G13 IOSTANDARD LVCMOS33 } [get_ports {b[0]}];
set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 } [get_ports {b[1]}];
set_property -dict { PACKAGE_PIN A11 IOSTANDARD LVCMOS33 } [get_ports {b[2]}];
set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33 } [get_ports {b[3]}];

## Input c: Pmod JA pins 7-10
set_property -dict { PACKAGE_PIN D13 IOSTANDARD LVCMOS33 } [get_ports {c[0]}];
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports {c[1]}];
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports {c[2]}];
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports {c[3]}];

## Input d: Pmod JB pins 1-4
set_property -dict { PACKAGE_PIN E15 IOSTANDARD LVCMOS33 } [get_ports {d[0]}];
set_property -dict { PACKAGE_PIN E16 IOSTANDARD LVCMOS33 } [get_ports {d[1]}];
set_property -dict { PACKAGE_PIN D15 IOSTANDARD LVCMOS33 } [get_ports {d[2]}];
set_property -dict { PACKAGE_PIN C15 IOSTANDARD LVCMOS33 } [get_ports {d[3]}];
