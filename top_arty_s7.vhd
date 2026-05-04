-- File: src/rtl/top_arty_s7.vhd
--
-- Milestone 2 top-level design for Digilent Arty S7-50.
--
-- Purpose:
--   Keep the heartbeat LED.
--   Keep the Pmod SSD display.
--   Add Pmod KYPD scanning on JD.
--   Display the last two keypad values typed.
--
-- Inputs:
--   clk12mhz      : 12 MHz board clock
--   btn0          : active-high reset button
--   kypd_row1..4  : keypad row inputs
--
-- Outputs:
--   led0          : onboard LED heartbeat
--   ssd_*         : Pmod SSD signals on JA/JB upper row
--   kypd_col1..4  : keypad column drive outputs
--
-- Reset behavior:
--   BTN0 is synchronized and used as active-high synchronous reset.
--   Display resets to 00.
--
-- Simulation:
--   For a fast top-level simulation, lower G_CLK_HZ and the child module
--   generics, or simulate keypad_scan directly first.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_arty_s7 is
  generic (
    G_CLK_HZ : positive := 12_000_000
  );
  port (
    clk12mhz : in  std_logic;
    btn0     : in  std_logic;

    led0     : out std_logic;

    ssd_aa   : out std_logic;
    ssd_ab   : out std_logic;
    ssd_ac   : out std_logic;
    ssd_ad   : out std_logic;
    ssd_ae   : out std_logic;
    ssd_af   : out std_logic;
    ssd_ag   : out std_logic;
    ssd_c    : out std_logic;

    kypd_col1 : out std_logic;
    kypd_col2 : out std_logic;
    kypd_col3 : out std_logic;
    kypd_col4 : out std_logic;

    kypd_row1 : in  std_logic;
    kypd_row2 : in  std_logic;
    kypd_row3 : in  std_logic;
    kypd_row4 : in  std_logic
  );
end entity top_arty_s7;

architecture rtl of top_arty_s7 is

  constant C_LED_TOGGLE_COUNT : positive := G_CLK_HZ / 2;

  signal reset_meta : std_logic := '0';
  signal reset_sync : std_logic := '0';

  signal led_counter : natural range 0 to C_LED_TOGGLE_COUNT - 1 := 0;
  signal led0_reg    : std_logic := '0';

  signal keypad_cols_n : std_logic_vector(3 downto 0) := (others => '1');
  signal keypad_rows_n : std_logic_vector(3 downto 0) := (others => '1');

  signal key_code  : unsigned(3 downto 0) := (others => '0');
  signal key_valid : std_logic := '0';

  signal display_tens : unsigned(3 downto 0) := (others => '0');
  signal display_ones : unsigned(3 downto 0) := (others => '0');

begin

  -- Synchronize external BTN0 before using it inside the FPGA clock domain.
  p_reset_sync : process (clk12mhz)
  begin
    if rising_edge(clk12mhz) then
      reset_meta <= btn0;
      reset_sync <= reset_meta;
    end if;
  end process p_reset_sync;

  -- Heartbeat LED.
  p_heartbeat : process (clk12mhz)
  begin
    if rising_edge(clk12mhz) then
      if reset_sync = '1' then
        led_counter <= 0;
        led0_reg    <= '0';
      else
        if led_counter = C_LED_TOGGLE_COUNT - 1 then
          led_counter <= 0;
          led0_reg    <= not led0_reg;
        else
          led_counter <= led_counter + 1;
        end if;
      end if;
    end if;
  end process p_heartbeat;

  led0 <= led0_reg;

  -- Top-level board I/O mapping for the keypad.
  -- Internal vector order is COL1..COL4 and ROW1..ROW4.
  kypd_col1 <= keypad_cols_n(0);
  kypd_col2 <= keypad_cols_n(1);
  kypd_col3 <= keypad_cols_n(2);
  kypd_col4 <= keypad_cols_n(3);

  keypad_rows_n(0) <= kypd_row1;
  keypad_rows_n(1) <= kypd_row2;
  keypad_rows_n(2) <= kypd_row3;
  keypad_rows_n(3) <= kypd_row4;

  u_keypad_scan : entity work.keypad_scan(rtl)
    generic map (
      G_CLK_HZ          => G_CLK_HZ,
      G_SCAN_STEP_HZ    => 1_000,
      G_DEBOUNCE_FRAMES => 5
    )
    port map (
      clk       => clk12mhz,
      reset     => reset_sync,

      row_n     => keypad_rows_n,
      col_n     => keypad_cols_n,

      key_code  => key_code,
      key_valid => key_valid
    );

  -- Shift the last two key presses into the display.
  p_display_registers : process (clk12mhz)
  begin
    if rising_edge(clk12mhz) then
      if reset_sync = '1' then
        display_tens <= to_unsigned(0, 4);
        display_ones <= to_unsigned(0, 4);
      else
        if key_valid = '1' then
          display_tens <= display_ones;
          display_ones <= key_code;
        end if;
      end if;
    end if;
  end process p_display_registers;

  u_pmod_ssd_driver : entity work.pmod_ssd_driver(rtl)
    generic map (
      G_CLK_HZ  => G_CLK_HZ,
      G_SCAN_HZ => 1_000
    )
    port map (
      clk        => clk12mhz,
      reset      => reset_sync,

      digit_tens => display_tens,
      digit_ones => display_ones,

      ssd_aa     => ssd_aa,
      ssd_ab     => ssd_ab,
      ssd_ac     => ssd_ac,
      ssd_ad     => ssd_ad,
      ssd_ae     => ssd_ae,
      ssd_af     => ssd_af,
      ssd_ag     => ssd_ag,
      ssd_c      => ssd_c
    );

end architecture rtl;