-- File: src/rtl/pmod_ssd_driver.vhd
--
-- Purpose:
--   Drive a Digilent Pmod SSD two-digit seven-segment display.
--   This module accepts two hexadecimal digit values and multiplexes
--   them onto the two physical display digits.
--
-- Inputs:
--   clk        : system clock
--   reset      : active-high synchronous reset
--   digit_tens : digit shown on the first selected SSD digit
--   digit_ones : digit shown on the second selected SSD digit
--
-- Outputs:
--   ssd_aa through ssd_ag : active-high segment anode outputs
--   ssd_c                : digit select signal, connected to PmodSSD pin C
--
-- Timing assumptions:
--   G_CLK_HZ must match the board clock frequency.
--   G_SCAN_HZ is the digit-switching rate. 1000 Hz means the selected
--   digit changes every 1 ms, giving each digit a refresh rate of about 500 Hz.
--
-- Reset behavior:
--   On reset, the scan counter and active digit are reset.
--   Segment outputs are blanked while reset is high.
--
-- Simulation:
--   For a quick simulation, override G_CLK_HZ with a small value such as 100
--   and G_SCAN_HZ with 10. Then observe ssd_c toggling and the segment outputs
--   alternating between digit_tens and digit_ones.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pmod_ssd_driver is
  generic (
    G_CLK_HZ  : positive := 12_000_000;
    G_SCAN_HZ : positive := 1_000
  );
  port (
    clk        : in  std_logic;
    reset      : in  std_logic;

    digit_tens : in  unsigned(3 downto 0);
    digit_ones : in  unsigned(3 downto 0);

    ssd_aa     : out std_logic;
    ssd_ab     : out std_logic;
    ssd_ac     : out std_logic;
    ssd_ad     : out std_logic;
    ssd_ae     : out std_logic;
    ssd_af     : out std_logic;
    ssd_ag     : out std_logic;
    ssd_c      : out std_logic
  );
end entity pmod_ssd_driver;

architecture rtl of pmod_ssd_driver is

  -- Number of input clock cycles between display digit changes.
  constant C_SCAN_COUNT : positive := G_CLK_HZ / G_SCAN_HZ;

  signal scan_counter  : natural range 0 to C_SCAN_COUNT - 1 := 0;
  signal active_digit  : std_logic := '0';

  signal selected_digit : unsigned(3 downto 0) := (others => '0');

  -- Segment bit order is:
  --   bit 6 = A
  --   bit 5 = B
  --   bit 4 = C
  --   bit 3 = D
  --   bit 2 = E
  --   bit 1 = F
  --   bit 0 = G
  signal seg_pattern : std_logic_vector(6 downto 0) := (others => '0');

  function sevenseg_encode(digit : unsigned(3 downto 0)) return std_logic_vector is
  begin
    case to_integer(digit) is
      when 0 =>
        return "1111110"; -- 0: A B C D E F
      when 1 =>
        return "0110000"; -- 1: B C
      when 2 =>
        return "1101101"; -- 2: A B D E G
      when 3 =>
        return "1111001"; -- 3: A B C D G
      when 4 =>
        return "0110011"; -- 4: B C F G
      when 5 =>
        return "1011011"; -- 5: A C D F G
      when 6 =>
        return "1011111"; -- 6: A C D E F G
      when 7 =>
        return "1110000"; -- 7: A B C
      when 8 =>
        return "1111111"; -- 8: A B C D E F G
      when 9 =>
        return "1111011"; -- 9: A B C D F G
      when others =>
        return "0000000"; -- blank for unsupported values
    end case;
  end function sevenseg_encode;

begin

  p_scan : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        scan_counter <= 0;
        active_digit <= '0';
      else
        if scan_counter = C_SCAN_COUNT - 1 then
          scan_counter <= 0;
          active_digit <= not active_digit;
        else
          scan_counter <= scan_counter + 1;
        end if;
      end if;
    end if;
  end process p_scan;

  -- active_digit = '0':
  --   Drive the first display value and set C high.
  --
  -- active_digit = '1':
  --   Drive the second display value and set C low.
  --
  -- If your physical display shows 24 instead of 42, swap digit_tens and
  -- digit_ones in the top-level instance. That is only a visual orientation issue.
  selected_digit <= digit_tens when active_digit = '0' else digit_ones;

  seg_pattern <= (others => '0') when reset = '1'
                 else sevenseg_encode(selected_digit);

  ssd_c <= '1' when active_digit = '0' else '0';

  ssd_aa <= seg_pattern(6);
  ssd_ab <= seg_pattern(5);
  ssd_ac <= seg_pattern(4);
  ssd_ad <= seg_pattern(3);
  ssd_ae <= seg_pattern(2);
  ssd_af <= seg_pattern(1);
  ssd_ag <= seg_pattern(0);

end architecture rtl;