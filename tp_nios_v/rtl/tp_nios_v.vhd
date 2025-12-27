library ieee;
use ieee.std_logic_1164.all;

library nios;
use nios.nios;

entity tp_nios_v is
    port (
        i_clk : in std_logic;
        i_rst_n : in std_logic;
        o_led : out std_logic_vector(9 downto 0)
    );
end entity tp_nios_v;

architecture rtl of tp_nios_v is
    
begin

nios0 : entity nios.nios
    port map (
        clk_clk                          => i_clk,
        reset_reset_n                    => i_rst_n,
        pio_0_external_connection_export => o_led
    );
    
end architecture rtl;