set_property PACKAGE_PIN Y9 [get_ports {clk_100MHz}];   # "GCLK"

set_property PACKAGE_PIN W11 [get_ports {TX}];          # "JB2"
set_property PACKAGE_PIN V10 [get_ports {RX}];          # "JB3"

set_property PACKAGE_PIN T18 [get_ports {reset}];       # "BTNU"

set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];
