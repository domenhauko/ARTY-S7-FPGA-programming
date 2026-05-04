-- File: src/rtl/top_arty_s7.vhd
--
-- Milestone 0 sanity-check design for Digilent Arty S7-50.
--
-- Purpose:
--   Blink one onboard user LED using the 12 MHz board oscillator.
--   BTN0 acts as an active-high synchronous reset.
--
-- Timing assumptions:
--   clk12mhz is the 12 MHz oscillator from the Arty S7 board.
--   The XDC must constrain clk12mhz with an 83.333 ns period.
--
-- Reset behavior:
--   BTN0 is synchronized into the clk12mhz clock domain.
--   When synchronized reset is high, the counter is cleared and led0 is off.
--
-- Simulation:
--   For a fast simulation, override G_CLK_HZ with a small value, for example 20,
--   and keep G_BLINK_HZ at 1. Then led0 toggles every 10 clock cycles.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_arty_s7 is
  generic (
    G_CLK_HZ    : positive := 12_000_000;
    G_BLINK_HZ : positive := 1
  );
  port (
    clk12mhz : in  std_logic;
    btn0     : in  std_logic;
    led0     : out std_logic
  );
end entity top_arty_s7;

architecture rtl of top_arty_s7 is

  constant C_TOGGLE_COUNT : positive := G_CLK_HZ / (2 * G_BLINK_HZ);

  signal reset_meta : std_logic := '0';
  signal reset_sync : std_logic := '0';

  signal blink_counter : natural range 0 to C_TOGGLE_COUNT - 1 := 0;
  signal led0_reg      : std_logic := '0';

begin

  -- Synchronize the external push button into the clock domain.
  -- BTN0 is mechanical, so it can bounce, but for a reset input that is acceptable
  -- in this simple milestone. Later keypad inputs will need proper debounce logic.
  p_reset_sync : process (clk12mhz)
  begin
    if rising_edge(clk12mhz) then
      reset_meta <= btn0;
      reset_sync <= reset_meta;
    end if;
  end process p_reset_sync;

  -- Blink generator using a clock enable style counter.
  -- No internally divided clock is created.
  p_blink : process (clk12mhz)
  begin
    if rising_edge(clk12mhz) then
      if reset_sync = '1' then
        blink_counter <= 0;
        led0_reg      <= '0';
      else
        if blink_counter = C_TOGGLE_COUNT - 1 then
          blink_counter <= 0;
          led0_reg      <= not led0_reg;
        else
          blink_counter <= blink_counter + 1;
        end if;
      end if;
    end if;
  end process p_blink;

  led0 <= led0_reg;

end architecture rtl;