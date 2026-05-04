# Arty S7 FPGA Distance Controller

A VHDL project for the **Digilent Arty S7-50** FPGA board using three Digilent Pmod peripherals:

- **Pmod SSD** — 2-digit seven-segment display
- **Pmod KYPD** — 16-key keypad
- **Pmod MAXSONAR** — ultrasonic range detector

The final system lets the user enter a desired two-digit distance with the keypad, measures the actual distance using the ultrasonic sensor, and displays the difference on the seven-segment display.

<p align="center">
  <img src="docs/images/setup.jpg" alt="Arty S7 FPGA setup with Pmods" width="650">
</p>

> Setup photo and demo video will be added later.

---

## Project Overview

The design was built milestone by milestone in Vivado using synthesizable VHDL.

### Milestone 0 — Board Sanity Check

- Created a minimal top-level design.
- Used the Arty S7 onboard clock.
- Blinked an onboard LED to confirm bitstream generation and programming.

### Milestone 1 — Pmod SSD Display

- Added the Digilent Pmod SSD.
- Displayed fixed test values.
- Built a reusable multiplexed seven-segment display driver.
- Corrected the display orientation in VHDL.

### Milestone 2 — Pmod KYPD Keypad

- Added the Digilent Pmod KYPD.
- Scanned the 4×4 keypad matrix.
- Debounced key presses.
- Displayed the last two numeric key presses on the SSD.

### Milestone 3 — Pmod MAXSONAR Distance Measurement

- Added the Digilent Pmod MAXSONAR.
- Captured the PWM distance output.
- Converted PWM pulse width to distance in inches.
- Compared measured distance against the user-entered target.
- Displayed the absolute distance error on the SSD.

---

## Final Behavior

1. The user enters a desired distance using the keypad.
2. The FPGA stores the last two numeric digits as the target distance in inches.
3. The ultrasonic sensor measures the actual distance.
4. The SSD displays the absolute difference between target and measured distance.
5. If the measured object is too close, the displayed value blinks with the onboard LED.
6. If the measured object is farther away than the target, the displayed value stays steady.

Example:

| Keypad Input | Target Distance |
|---|---:|
| `2`, `4` | 24 inches |
| `0`, `8` | 8 inches |
| `5`, `0` | 50 inches |

---

## Hardware Used

- Digilent Arty S7-50 development board
- Xilinx Spartan-7 FPGA
- Digilent Pmod SSD
- Digilent Pmod KYPD
- Digilent Pmod MAXSONAR
- Vivado Design Suite

---

## Pmod Connections

Current hardware mapping:

| Peripheral | Arty S7 Connector | Notes |
|---|---|---|
| Pmod SSD J1 | JA upper row | Segments A–D |
| Pmod SSD J2 | JB upper row | Segments E–G and digit select |
| Pmod KYPD | JD full connector | 4 columns + 4 rows |
| Pmod MAXSONAR | JC upper row | PWM input used for distance |

The MAXSONAR design uses the PWM output interface. The sensor is measured in inches because its PWM timing is specified in inches.

---

## Repository Contents

```text
.
├── Arty-S7-50-Master.xdc
├── top_arty_s7.vhd
├── pmod_ssd_driver.vhd
├── keypad_scan.vhd
├── maxsonar_pwm_capture_inch.vhd
└── README.md
