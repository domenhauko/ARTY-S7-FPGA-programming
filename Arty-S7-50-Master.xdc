## Clock Signals
set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33 } [get_ports { clk12mhz }];
create_clock -add -name clk12mhz -period 83.333 -waveform {0 41.667} [get_ports { clk12mhz }];

## Onboard LED heartbeat
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { led0 }];

## BTN0 reset input
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { btn0 }];

## Pmod SSD on JA/JB upper row
## SSD J1 -> JA pins 1-6
##   J1 pin 1 AA -> JA pin 1
##   J1 pin 2 AB -> JA pin 2
##   J1 pin 3 AC -> JA pin 3
##   J1 pin 4 AD -> JA pin 4
##   J1 pin 5 GND
##   J1 pin 6 VCC
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { ssd_aa }]; # JA pin 1
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { ssd_ab }]; # JA pin 2
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { ssd_ac }]; # JA pin 3
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { ssd_ad }]; # JA pin 4

## SSD J2 -> JB pins 1-6
##   J2 pin 1 AE -> JB pin 1
##   J2 pin 2 AF -> JB pin 2
##   J2 pin 3 AG -> JB pin 3
##   J2 pin 4 C  -> JB pin 4
##   J2 pin 5 GND
##   J2 pin 6 VCC
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { ssd_ae }]; # JB pin 1
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { ssd_af }]; # JB pin 2
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { ssd_ag }]; # JB pin 3
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { ssd_c  }]; # JB pin 4