library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity chaser is
    port (
        i_clk   : in  std_logic;                       
        i_rst_n : in  std_logic;                       
        o_led   : out std_logic_vector(9 downto 0)     
    );
end entity chaser;

architecture rtl of chaser is
    signal r_led   : std_logic_vector(9 downto 0) := "0000000001";  
    signal counter : unsigned(23 downto 0) := (others => '0');      
begin

    process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_led   <= "0000000001";                   
            counter <= (others => '0');

        elsif rising_edge(i_clk) then
            if counter = 5_000_000 then
                counter <= (others => '0');

                
                if r_led = "1000000000" then
                    r_led <= "0000000001";             
                else
                    r_led <= r_led(8 downto 0) & '0';  
                end if;

            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    o_led <= r_led;
end architecture rtl;