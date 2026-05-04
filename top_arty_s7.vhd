-- File: src/rtl/top_arty_s7.vhd
--
-- Milestone 3 top-level design for Digilent Arty S7-50.
--
-- Purpose:
--   Keep heartbeat LED.
--   Keep Pmod SSD on JA/JB upper row.
--   Keep Pmod KYPD on JD.
--   Add PmodMAXSONAR on JC upper row using PWM timing.
--   Display abs(wanted distance - measured distance).
--   Blink the displayed number when the measured object is closer than wanted.
--
-- Units:
--   Inches.
--
-- Reset behavior:
--   BTN0 is synchronized and used as active-high synchronous reset.
--   Desired distance resets to 00.
--   Display shows 00 until sensor samples arrive.

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
    kypd_row4 : in  std_logic;

    maxsonar_rx  : out std_logic;
    maxsonar_pwm : in  std_logic
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

  signal desired_tens : unsigned(3 downto 0) := (others => '0');
  signal desired_ones : unsigned(3 downto 0) := (others => '0');

  signal measured_inches     : unsigned(7 downto 0) := (others => '0');
  signal sensor_sample_valid : std_logic := '0';
  signal have_sensor_sample  : std_logic := '0';

  signal desired_inches_int  : natural range 0 to 99 := 0;
  signal measured_inches_int : natural range 0 to 255 := 0;
  signal diff_inches_int     : natural range 0 to 255 := 0;
  signal diff_display_int    : natural range 0 to 99 := 0;

  signal object_too_close    : std_logic := '0';
  signal display_enable      : std_logic := '1';

  signal diff_tens : unsigned(3 downto 0) := (others => '0');
  signal diff_ones : unsigned(3 downto 0) := (others => '0');

begin

  -- Keep PmodMAXSONAR RX high so the module free-runs.
  maxsonar_rx <= '1';

  p_reset_sync : process (clk12mhz)
  begin
    if rising_edge(clk12mhz) then
      reset_meta <= btn0;
      reset_sync <= reset_meta;
    end if;
  end process p_reset_sync;

  -- Heartbeat LED, reused as the display blink timing source.
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

  -- Keypad board I/O mapping.
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

  -- Only decimal keys 0 through 9 update the wanted distance.
  -- A-F are ignored for this distance-entry mode.
  p_desired_distance : process (clk12mhz)
  begin
    if rising_edge(clk12mhz) then
      if reset_sync = '1' then
        desired_tens <= to_unsigned(0, 4);
        desired_ones <= to_unsigned(0, 4);
      else
        if key_valid = '1' then
          if key_code <= to_unsigned(9, 4) then
            desired_tens <= desired_ones;
            desired_ones <= key_code;
          end if;
        end if;
      end if;
    end if;
  end process p_desired_distance;

  u_maxsonar_pwm_capture : entity work.maxsonar_pwm_capture(rtl)
    generic map (
      G_CYCLES_PER_INCH => 1764
    )
    port map (
      clk             => clk12mhz,
      reset           => reset_sync,

      pwm_in          => maxsonar_pwm,

      distance_inches => measured_inches,
      sample_valid    => sensor_sample_valid
    );

  p_have_sensor_sample : process (clk12mhz)
  begin
    if rising_edge(clk12mhz) then
      if reset_sync = '1' then
        have_sensor_sample <= '0';
      else
        if sensor_sample_valid = '1' then
          have_sensor_sample <= '1';
        end if;
      end if;
    end if;
  end process p_have_sensor_sample;

  desired_inches_int  <= (to_integer(desired_tens) * 10) + to_integer(desired_ones);
  measured_inches_int <= to_integer(measured_inches);

  p_difference : process (
    desired_inches_int,
    measured_inches_int,
    have_sensor_sample
  )
    variable diff_temp : natural range 0 to 255;
  begin
    if have_sensor_sample = '0' then
      diff_temp        := 0;
      object_too_close <= '0';
    else
      if measured_inches_int > desired_inches_int then
        diff_temp        := measured_inches_int - desired_inches_int;
        object_too_close <= '0';
      elsif measured_inches_int < desired_inches_int then
        diff_temp        := desired_inches_int - measured_inches_int;
        object_too_close <= '1';
      else
        diff_temp        := 0;
        object_too_close <= '0';
      end if;
    end if;

    diff_inches_int <= diff_temp;

    if diff_temp > 99 then
      diff_display_int <= 99;
    else
      diff_display_int <= diff_temp;
    end if;
  end process p_difference;

  diff_tens <= to_unsigned(diff_display_int / 10, 4);
  diff_ones <= to_unsigned(diff_display_int mod 10, 4);

  -- Fixed display when object is at/behind target.
  -- Blinking display when object is closer than the wanted distance.
  display_enable <= led0_reg when object_too_close = '1' else '1';

  u_pmod_ssd_driver : entity work.pmod_ssd_driver(rtl)
    generic map (
      G_CLK_HZ      => G_CLK_HZ,
      G_SCAN_HZ     => 1_000,
      G_ROTATE_180  => true,
      G_SWAP_DIGITS => true
    )
    port map (
      clk            => clk12mhz,
      reset          => reset_sync,
      display_enable => display_enable,

      digit_tens     => diff_tens,
      digit_ones     => diff_ones,

      ssd_aa         => ssd_aa,
      ssd_ab         => ssd_ab,
      ssd_ac         => ssd_ac,
      ssd_ad         => ssd_ad,
      ssd_ae         => ssd_ae,
      ssd_af         => ssd_af,
      ssd_ag         => ssd_ag,
      ssd_c          => ssd_c
    );

end architecture rtl;