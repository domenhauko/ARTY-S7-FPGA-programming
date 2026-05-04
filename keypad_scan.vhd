-- File: src/rtl/keypad_scan.vhd
--
-- Purpose:
--   Scan a Digilent Pmod KYPD 4x4 keypad.
--   The module drives one column low at a time and reads the row inputs.
--   When a stable new key press is detected, it emits a one-clock key_valid pulse.
--
-- Interface convention:
--   col_n(0) = COL1, col_n(1) = COL2, col_n(2) = COL3, col_n(3) = COL4
--   row_n(0) = ROW1, row_n(1) = ROW2, row_n(2) = ROW3, row_n(3) = ROW4
--
-- Key map:
--   ROW1: 1 2 3 A
--   ROW2: 4 5 6 B
--   ROW3: 7 8 9 C
--   ROW4: 0 F E D
--
-- Timing assumptions:
--   G_CLK_HZ must match the FPGA clock frequency.
--   G_SCAN_STEP_HZ sets how often the active column changes.
--   With 1000 Hz scan steps, each column is active for 1 ms and a full
--   four-column frame takes about 4 ms.
--
-- Reset behavior:
--   Active-high synchronous reset.
--   During reset all columns are driven high, meaning no column is selected.
--
-- Simulation:
--   Override G_CLK_HZ and G_SCAN_STEP_HZ with small values.
--   Drive a row low when the matching column is low, then check for key_valid.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keypad_scan is
  generic (
    G_CLK_HZ          : positive := 12_000_000;
    G_SCAN_STEP_HZ    : positive := 1_000;
    G_DEBOUNCE_FRAMES : positive := 5
  );
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;

    row_n     : in  std_logic_vector(3 downto 0);
    col_n     : out std_logic_vector(3 downto 0);

    key_code  : out unsigned(3 downto 0);
    key_valid : out std_logic
  );
end entity keypad_scan;

architecture rtl of keypad_scan is

  constant C_SCAN_STEP_COUNT : positive := G_CLK_HZ / G_SCAN_STEP_HZ;

  subtype t_col_index is natural range 0 to 3;

  signal row_meta : std_logic_vector(3 downto 0) := (others => '1');
  signal row_sync : std_logic_vector(3 downto 0) := (others => '1');

  signal scan_counter : natural range 0 to C_SCAN_STEP_COUNT - 1 := 0;
  signal col_index    : t_col_index := 0;
  signal col_drive_n  : std_logic_vector(3 downto 0) := "1110";

  signal frame_down : std_logic := '0';
  signal frame_code : unsigned(3 downto 0) := (others => '0');

  signal candidate_down : std_logic := '0';
  signal candidate_code : unsigned(3 downto 0) := (others => '0');
  signal stable_count   : natural range 0 to G_DEBOUNCE_FRAMES := 0;

  signal reported_down : std_logic := '0';
  signal reported_code : unsigned(3 downto 0) := (others => '0');

  signal key_code_reg  : unsigned(3 downto 0) := (others => '0');
  signal key_valid_reg : std_logic := '0';

  function key_for_position(
    row_idx : natural;
    col_idx : natural
  ) return unsigned is
  begin
    case row_idx is
      when 0 =>
        case col_idx is
          when 0      => return to_unsigned(1, 4);
          when 1      => return to_unsigned(2, 4);
          when 2      => return to_unsigned(3, 4);
          when others => return to_unsigned(10, 4); -- A
        end case;

      when 1 =>
        case col_idx is
          when 0      => return to_unsigned(4, 4);
          when 1      => return to_unsigned(5, 4);
          when 2      => return to_unsigned(6, 4);
          when others => return to_unsigned(11, 4); -- B
        end case;

      when 2 =>
        case col_idx is
          when 0      => return to_unsigned(7, 4);
          when 1      => return to_unsigned(8, 4);
          when 2      => return to_unsigned(9, 4);
          when others => return to_unsigned(12, 4); -- C
        end case;

      when others =>
        case col_idx is
          when 0      => return to_unsigned(0, 4);
          when 1      => return to_unsigned(15, 4); -- F
          when 2      => return to_unsigned(14, 4); -- E
          when others => return to_unsigned(13, 4); -- D
        end case;
    end case;
  end function key_for_position;

begin

  -- Two-flop synchronizer for the external row inputs.
  p_row_sync : process (clk)
  begin
    if rising_edge(clk) then
      row_meta <= row_n;
      row_sync <= row_meta;
    end if;
  end process p_row_sync;

  -- Active-low column drive.
  with col_index select
    col_drive_n <= "1110" when 0,      -- COL1 low
                   "1101" when 1,      -- COL2 low
                   "1011" when 2,      -- COL3 low
                   "0111" when others; -- COL4 low

  col_n <= "1111" when reset = '1' else col_drive_n;

  p_scan : process (clk)
    variable sample_down     : std_logic;
    variable sample_code     : unsigned(3 downto 0);
    variable next_frame_down : std_logic;
    variable next_frame_code : unsigned(3 downto 0);
  begin
    if rising_edge(clk) then
      key_valid_reg <= '0';

      if reset = '1' then
        scan_counter   <= 0;
        col_index      <= 0;

        frame_down     <= '0';
        frame_code     <= (others => '0');

        candidate_down <= '0';
        candidate_code <= (others => '0');
        stable_count   <= 0;

        reported_down  <= '0';
        reported_code  <= (others => '0');

        key_code_reg   <= (others => '0');

      else
        if scan_counter = C_SCAN_STEP_COUNT - 1 then
          scan_counter <= 0;

          -- Sample the synchronized row inputs for the currently active column.
          sample_down := '0';
          sample_code := (others => '0');

          for row_idx in 0 to 3 loop
            if (row_sync(row_idx) = '0') and (sample_down = '0') then
              sample_down := '1';
              sample_code := key_for_position(row_idx, col_index);
            end if;
          end loop;

          -- Accumulate the first detected key in this four-column scan frame.
          next_frame_down := frame_down;
          next_frame_code := frame_code;

          if (frame_down = '0') and (sample_down = '1') then
            next_frame_down := '1';
            next_frame_code := sample_code;
          end if;

          if col_index = 3 then
            -- End of a full keypad frame. Debounce the frame result.
            if (next_frame_down = candidate_down) and
               ((next_frame_down = '0') or (next_frame_code = candidate_code)) then

              if stable_count < G_DEBOUNCE_FRAMES then
                stable_count <= stable_count + 1;

                -- The candidate has just become stable.
                if stable_count = G_DEBOUNCE_FRAMES - 1 then
                  if next_frame_down = '1' then
                    if (reported_down = '0') or (next_frame_code /= reported_code) then
                      key_code_reg   <= next_frame_code;
                      key_valid_reg  <= '1';
                    end if;
                  end if;

                  reported_down <= next_frame_down;
                  reported_code <= next_frame_code;
                end if;
              end if;

            else
              candidate_down <= next_frame_down;
              candidate_code <= next_frame_code;
              stable_count   <= 1;
            end if;

            -- Start next four-column frame.
            frame_down <= '0';
            frame_code <= (others => '0');
            col_index  <= 0;

          else
            -- Continue current frame on the next column.
            frame_down <= next_frame_down;
            frame_code <= next_frame_code;
            col_index  <= col_index + 1;
          end if;

        else
          scan_counter <= scan_counter + 1;
        end if;
      end if;
    end if;
  end process p_scan;

  key_code  <= key_code_reg;
  key_valid <= key_valid_reg;

end architecture rtl;