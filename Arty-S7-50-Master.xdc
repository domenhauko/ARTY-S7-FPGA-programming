## Clock Signals
set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33 } [get_ports { clk12mhz }];
create_clock -add -name clk12mhz -period 83.333 -waveform {0 41.667} [get_ports { clk12mhz }];

## Onboard LED heartbeat
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { led0 }];

## BTN0 reset input
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { btn0 }];

## Pmod KYPD on JD
## KYPD pin 1 COL4 -> JD pin 1
## KYPD pin 2 COL3 -> JD pin 2
## KYPD pin 3 COL2 -> JD pin 3
## KYPD pin 4 COL1 -> JD pin 4
## KYPD pin 5 GND
## KYPD pin 6 VCC
## KYPD pin 7 ROW4 -> JD pin 7
## KYPD pin 8 ROW3 -> JD pin 8
## KYPD pin 9 ROW2 -> JD pin 9
## KYPD pin 10 ROW1 -> JD pin 10
## KYPD pin 11 GND
## KYPD pin 12 VCC

set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { kypd_col4 }]; # JD pin 1
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { kypd_col3 }]; # JD pin 2
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { kypd_col2 }]; # JD pin 3
set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { kypd_col1 }]; # JD pin 4

set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports { kypd_row4 }]; # JD pin 7
set_property -dict { PACKAGE_PIN R11   IOSTANDARD LVCMOS33 } [get_ports { kypd_row3 }]; # JD pin 8
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { kypd_row2 }]; # JD pin 9
set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports { kypd_row1 }]; # JD pin 10

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

## Pmod MAXSONAR on JC upper row
## MAXSONAR pin 2 RX  -> JC pin 2, driven high by FPGA for free-run behavior
## MAXSONAR pin 4 PWM -> JC pin 4, captured by FPGA

set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { maxsonar_rx  }]; # JC pin 2
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { maxsonar_pwm }]; # JC pin 4