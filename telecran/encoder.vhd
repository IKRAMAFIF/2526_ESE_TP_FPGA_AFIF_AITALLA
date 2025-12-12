library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder is
    port(
        i_clk   : in  std_logic;
        i_rst_n : in  std_logic;
        i_ch_a  : in  std_logic;
        i_ch_b  : in  std_logic;
        o_inc   : out std_logic;
        o_dec   : out std_logic
    );
end entity;

architecture rtl of encoder is
    signal a_now, a_prev : std_logic := '0';
    signal b_now, b_prev : std_logic := '0';
begin

    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            a_now  <= '0';
            a_prev <= '0';
            b_now  <= '0';
            b_prev <= '0';
        elsif rising_edge(i_clk) then
            a_prev <= a_now;
            a_now  <= i_ch_a;

            b_prev <= b_now;
            b_now  <= i_ch_b;
        end if;
    end process;

  
    o_inc <= '1' when (
                (a_prev='0' and a_now='1' and b_now='1') or
                (a_prev='1' and a_now='0' and b_now='1')
             )
             else '0';

    o_dec <= '1' when (
                (b_prev='0' and b_now='1' and a_now='1') or
                (b_prev='1' and b_now='0' and a_now='1')
             )
             else '0';

end architecture;