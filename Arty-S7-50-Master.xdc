## Clock Signals
set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33 } [get_ports { clk12mhz }]; #IO_L13P_T2_MRCC_15 Sch=uclk
create_clock -add -name clk12mhz -period 83.333 -waveform {0 41.667} [get_ports { clk12mhz }];

## LEDs
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { led0 }]; #IO_L16N_T2_A27_15 Sch=led[2]

## Buttons
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { btn0 }]; #IO_L18N_T2_A23_15 Sch=btn[0]