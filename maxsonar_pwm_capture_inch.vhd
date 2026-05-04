-- File: src/rtl/maxsonar_pwm_capture.vhd
--
-- Purpose:
--   Capture the PmodMAXSONAR PWM output and convert pulse width to inches.
--   For a 12 MHz clock, 147 us equals 1764 clock cycles.
--
-- Inputs:
--   clk    : system clock
--   reset  : active-high synchronous reset
--   pwm_in : asynchronous PWM input from PmodMAXSONAR
--
-- Outputs:
--   distance_inches : most recent measured distance in inches, 0 to 255
--   sample_valid    : one-clock pulse when a new PWM measurement is latched
--
-- Timing assumptions:
--   Default G_CYCLES_PER_INCH = 1764 assumes clk = 12 MHz.
--   PmodMAXSONAR PWM high time is interpreted as 147 us per inch.
--
-- Reset behavior:
--   Clears the synchronizer, active pulse counter, distance register, and valid pulse.
--
-- Simulation:
--   Override G_CYCLES_PER_INCH with a small value, for example 4.
--   Drive pwm_in high for N * G_CYCLES_PER_INCH cycles and check distance_inches.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity maxsonar_pwm_capture is
  generic (
    G_CYCLES_PER_INCH : positive := 1764
  );
  port (
    clk             : in  std_logic;
    reset           : in  std_logic;

    pwm_in          : in  std_logic;

    distance_inches : out unsigned(7 downto 0);
    sample_valid    : out std_logic
  );
end entity maxsonar_pwm_capture;

architecture rtl of maxsonar_pwm_capture is

  signal pwm_meta : std_logic := '0';
  signal pwm_sync : std_logic := '0';
  signal pwm_prev : std_logic := '0';

  signal pulse_active     : std_logic := '0';
  signal inch_cycle_count : natural range 0 to G_CYCLES_PER_INCH - 1 := 0;
  signal pulse_inches     : natural range 0 to 255 := 0;

  signal distance_reg     : unsigned(7 downto 0) := (others => '0');
  signal sample_valid_reg : std_logic := '0';

begin

  -- Synchronize asynchronous sensor PWM input.
  p_sync : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        pwm_meta <= '0';
        pwm_sync <= '0';
      else
        pwm_meta <= pwm_in;
        pwm_sync <= pwm_meta;
      end if;
    end if;
  end process p_sync;

  p_capture : process (clk)
    variable rounded_inches : natural range 0 to 255;
  begin
    if rising_edge(clk) then
      sample_valid_reg <= '0';
      pwm_prev <= pwm_sync;

      if reset = '1' then
        pulse_active     <= '0';
        inch_cycle_count <= 0;
        pulse_inches     <= 0;
        distance_reg     <= (others => '0');

      else
        -- Rising edge: start a new pulse measurement.
        if (pwm_prev = '0') and (pwm_sync = '1') then
          pulse_active     <= '1';
          inch_cycle_count <= 0;
          pulse_inches     <= 0;

        -- While high: count 147 us chunks.
        elsif pwm_sync = '1' then
          if pulse_active = '1' then
            if inch_cycle_count = G_CYCLES_PER_INCH - 1 then
              inch_cycle_count <= 0;

              if pulse_inches < 255 then
                pulse_inches <= pulse_inches + 1;
              end if;
            else
              inch_cycle_count <= inch_cycle_count + 1;
            end if;
          end if;

        -- Falling edge: latch a completed measurement.
        elsif (pwm_prev = '1') and (pwm_sync = '0') then
          if pulse_active = '1' then
            rounded_inches := pulse_inches;

            -- Round to the nearest inch.
            if (inch_cycle_count >= (G_CYCLES_PER_INCH / 2)) and
               (rounded_inches < 255) then
              rounded_inches := rounded_inches + 1;
            end if;

            distance_reg     <= to_unsigned(rounded_inches, 8);
            sample_valid_reg <= '1';
          end if;

          pulse_active     <= '0';
          inch_cycle_count <= 0;
          pulse_inches     <= 0;
        end if;
      end if;
    end if;
  end process p_capture;

  distance_inches <= distance_reg;
  sample_valid    <= sample_valid_reg;

end architecture rtl;