library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_blink is
    port (
        i_clk   : in  std_logic;   
        i_rst_n : in  std_logic;   
        o_led   : out std_logic
    );
end entity led_blink;

architecture rtl of led_blink is
    signal r_led   : std_logic := '0';
    signal counter : unsigned(22 downto 0) := (others => '0');
    
begin
    process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_led   <= '0';
            counter <= (others => '0');
        elsif rising_edge(i_clk) then
            if counter = 5_000_000 then
                counter <= (others => '0');
                r_led <= not r_led;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    o_led <= r_led;
end architecture rtl;