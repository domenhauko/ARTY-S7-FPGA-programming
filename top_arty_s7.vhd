-- File: src/rtl/top_arty_s7.vhd
--
-- Milestone 1 top-level design for Digilent Arty S7-50.
--
-- Purpose:
--   Keep the Milestone 0 heartbeat LED.
--   Add a Digilent Pmod SSD two-digit seven-segment display.
--   Display the fixed test value 42.
--
-- Inputs:
--   clk12mhz : 12 MHz board clock
--   btn0     : active-high user button used as reset
--
-- Outputs:
--   led0     : onboard LED heartbeat
--   ssd_*    : Pmod SSD signals
--
-- Important timing assumptions:
--   clk12mhz is constrained to 12 MHz in the XDC.
--
-- Reset behavior:
--   BTN0 is synchronized into the clk12mhz clock domain.
--   Pressing BTN0 clears the heartbeat LED and blanks/resets the SSD driver.
--
-- Simulation:
--   Override G_CLK_HZ with a small value for fast simulation.
--   Check that led0 toggles and that ssd_c alternates between the two digits.

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
    ssd_c    : out std_logic
  );
end entity top_arty_s7;

architecture rtl of top_arty_s7 is

  constant C_LED_TOGGLE_COUNT : positive := G_CLK_HZ / 2;

  constant C_TEST_TENS : unsigned(3 downto 0) := to_unsigned(4, 4);
  constant C_TEST_ONES : unsigned(3 downto 0) := to_unsigned(2, 4);

  signal reset_meta : std_logic := '0';
  signal reset_sync : std_logic := '0';

  signal led_counter : natural range 0 to C_LED_TOGGLE_COUNT - 1 := 0;
  signal led0_reg    : std_logic := '0';

begin

  -- Synchronize external BTN0 before using it inside the FPGA clock domain.
  p_reset_sync : process (clk12mhz)
  begin
    if rising_edge(clk12mhz) then
      reset_meta <= btn0;
      reset_sync <= reset_meta;
    end if;
  end process p_reset_sync;

  -- Heartbeat LED from Milestone 0.
  -- This is still useful because it tells us the FPGA clock is running.
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

  u_pmod_ssd_driver : entity work.pmod_ssd_driver(rtl)
    generic map (
      G_CLK_HZ  => G_CLK_HZ,
      G_SCAN_HZ => 1_000
    )
    port map (
      clk        => clk12mhz,
      reset      => reset_sync,

      digit_tens => C_TEST_TENS,
      digit_ones => C_TEST_ONES,

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