library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_controler is
    generic (
        -- Résolution active
        h_res  : natural := 720;
        v_res  : natural := 480;

        -- Timings horizontaux (480p)
        h_sync : natural := 61;
        h_fp   : natural := 58;
        h_bp   : natural := 18;

        -- Timings verticaux (480p)
        v_sync : natural := 5;
        v_fp   : natural := 30;
        v_bp   : natural := 9
    );
    port (
        i_clk   : in  std_logic;   
        i_rst_n : in  std_logic;

        -- Sorties HDMI
        o_hdmi_hs : out std_logic;
        o_hdmi_vs : out std_logic;
        o_hdmi_de : out std_logic;

        -- Compteurs pixel
        o_x_counter : out natural range 0 to h_res-1;
        o_y_counter : out natural range 0 to v_res-1;

        -- Interface pixel 
        o_pixel_en      : out std_logic;
        o_pixel_address : out natural
    );
end entity hdmi_controler;

architecture rtl of hdmi_controler is

    constant h_total : natural := h_res + h_fp + h_sync + h_bp;
    constant v_total : natural := v_res + v_fp + v_sync + v_bp;

    signal x : natural range 0 to h_total-1 := 0;
    signal y : natural range 0 to v_total-1 := 0;

    signal de_i : std_logic := '0';

begin

    -- Compteurs X / Y
  
    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            x <= 0;
            y <= 0;

        elsif rising_edge(i_clk) then
            if x = h_total-1 then
                x <= 0;
                if y = v_total-1 then
                    y <= 0;
                else
                    y <= y + 1;
                end if;
            else
                x <= x + 1;
            end if;
        end if;
    end process;

    -- Data Enable (zone visible)
  
    de_i <= '1' when (x < h_res and y < v_res) else '0';
    o_hdmi_de <= de_i;

    -- Compteurs visibles

    o_x_counter <= x when x < h_res else h_res-1;
    o_y_counter <= y when y < v_res else v_res-1;

    -- Synchronisations HDMI (polarité négative 480p)
  
    o_hdmi_hs <= '0'
        when (x >= h_res + h_fp and x < h_res + h_fp + h_sync)
        else '1';

    o_hdmi_vs <= '0'
        when (y >= v_res + v_fp and y < v_res + v_fp + v_sync)
        else '1';


    -- Interface pixel (linéarisation)
   
    o_pixel_en <= de_i;

    o_pixel_address <= (y * h_res + x) when de_i = '1' else 0;

end architecture rtl;
