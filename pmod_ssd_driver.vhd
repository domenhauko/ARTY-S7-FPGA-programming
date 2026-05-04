-- File: src/rtl/pmod_ssd_driver.vhd
--
-- Purpose:
--   Drive a Digilent Pmod SSD two-digit seven-segment display.
--   This version supports hexadecimal-style digits 0-F.
--
--   For the current physical mounting, the SSD is visually rotated 180 degrees
--   relative to the keypad/user. Therefore the default generic settings rotate
--   the segment mapping and swap the two digit positions.
--
-- Inputs:
--   clk        : system clock
--   reset      : active-high synchronous reset
--   digit_tens : older/left digit value in normal reading order
--   digit_ones : newest/right digit value in normal reading order
--
-- Outputs:
--   ssd_aa through ssd_ag : active-high segment anode outputs
--   ssd_c                : digit select signal
--
-- Timing assumptions:
--   G_CLK_HZ must match the board clock frequency.
--   G_SCAN_HZ is the digit-switching rate.
--
-- Reset behavior:
--   On reset, scan state is cleared and segment outputs are blanked.
--
-- Simulation:
--   Override G_CLK_HZ and G_SCAN_HZ with small values and observe ssd_c
--   toggling while the segment pattern alternates between the two digits.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pmod_ssd_driver is
  generic (
    G_CLK_HZ      : positive := 12_000_000;
    G_SCAN_HZ     : positive := 1_000;

    -- For your current physical mounting:
    --   true  = display is visually rotated 180 degrees
    --   false = display is in normal orientation
    G_ROTATE_180  : boolean := true;

    -- For a 180-degree physical rotation, the visual left/right digits swap.
    -- Keep this true for your current setup.
    G_SWAP_DIGITS : boolean := true
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

  subtype t_hex_digit is unsigned(3 downto 0);
  subtype t_segments  is std_logic_vector(6 downto 0);

  constant C_SCAN_COUNT : positive := G_CLK_HZ / G_SCAN_HZ;

  signal scan_counter  : natural range 0 to C_SCAN_COUNT - 1 := 0;
  signal active_digit  : std_logic := '0';

  signal selected_digit  : t_hex_digit := (others => '0');
  signal logical_pattern : t_segments  := (others => '0');
  signal output_pattern  : t_segments  := (others => '0');

  -- Segment bit order:
  --   bit 6 = A
  --   bit 5 = B
  --   bit 4 = C
  --   bit 3 = D
  --   bit 2 = E
  --   bit 1 = F
  --   bit 0 = G
  function sevenseg_encode(digit : t_hex_digit) return t_segments is
  begin
    case to_integer(digit) is
      when 0  => return "1111110"; -- 0
      when 1  => return "0110000"; -- 1
      when 2  => return "1101101"; -- 2
      when 3  => return "1111001"; -- 3
      when 4  => return "0110011"; -- 4
      when 5  => return "1011011"; -- 5
      when 6  => return "1011111"; -- 6
      when 7  => return "1110000"; -- 7
      when 8  => return "1111111"; -- 8
      when 9  => return "1111011"; -- 9
      when 10 => return "1110111"; -- A
      when 11 => return "0011111"; -- b
      when 12 => return "1001110"; -- C
      when 13 => return "0111101"; -- d
      when 14 => return "1001111"; -- E
      when 15 => return "1000111"; -- F
      when others => return "0000000";
    end case;
  end function sevenseg_encode;

  -- Convert a normal A-B-C-D-E-F-G segment pattern to the physical output
  -- pattern needed when the display is viewed upside down.
  --
  -- For a 180-degree rotation:
  --   logical A must drive physical D
  --   logical B must drive physical E
  --   logical C must drive physical F
  --   logical D must drive physical A
  --   logical E must drive physical B
  --   logical F must drive physical C
  --   logical G must drive physical G
  --
  -- Since output_pattern bit order is physical A-B-C-D-E-F-G:
  --   output A = logical D
  --   output B = logical E
  --   output C = logical F
  --   output D = logical A
  --   output E = logical B
  --   output F = logical C
  --   output G = logical G
  function rotate_segments_180(pattern : t_segments) return t_segments is
  begin
    return pattern(3) & pattern(2) & pattern(1) &
           pattern(6) & pattern(5) & pattern(4) &
           pattern(0);
  end function rotate_segments_180;

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

  -- Select which logical digit value is being driven.
  --
  -- Normal display:
  --   active_digit = 0 -> digit_tens
  --   active_digit = 1 -> digit_ones
  --
  -- Rotated physical display:
  --   the visual left/right positions swap, so we reverse that selection.
  selected_digit <= digit_ones when ((G_SWAP_DIGITS = true)  and (active_digit = '0')) else
                    digit_tens when ((G_SWAP_DIGITS = true)  and (active_digit = '1')) else
                    digit_tens when ((G_SWAP_DIGITS = false) and (active_digit = '0')) else
                    digit_ones;

  logical_pattern <= (others => '0') when reset = '1'
                     else sevenseg_encode(selected_digit);

  output_pattern <= rotate_segments_180(logical_pattern) when G_ROTATE_180 = true
                    else logical_pattern;

  ssd_c <= '1' when active_digit = '0' else '0';

  ssd_aa <= output_pattern(6);
  ssd_ab <= output_pattern(5);
  ssd_ac <= output_pattern(4);
  ssd_ad <= output_pattern(3);
  ssd_ae <= output_pattern(2);
  ssd_af <= output_pattern(1);
  ssd_ag <= output_pattern(0);

end architecture rtl;