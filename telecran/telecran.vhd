library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pll;
use pll.all;

entity telecran is
    port (
        i_clk_50: in std_logic;

      
        io_hdmi_i2c_scl : inout std_logic;
        io_hdmi_i2c_sda : inout std_logic;
        o_hdmi_tx_clk   : out std_logic;
        o_hdmi_tx_d     : out std_logic_vector(23 downto 0);
        o_hdmi_tx_de    : out std_logic;
        o_hdmi_tx_hs    : out std_logic;
        i_hdmi_tx_int   : in std_logic;
        o_hdmi_tx_vs    : out std_logic;

        i_rst_n : in std_logic;

        o_leds       : out std_logic_vector(9 downto 0); -- LEFT
        o_de10_leds  : out std_logic_vector(7 downto 0); -- RIGHT

        
        i_left_ch_a  : in std_logic;
        i_left_ch_b  : in std_logic;
        i_left_pb    : in std_logic;

        i_right_ch_a : in std_logic;
        i_right_ch_b : in std_logic;
        i_right_pb   : in std_logic
    );
end entity;

architecture rtl of telecran is

    component I2C_HDMI_Config 
        port (
            iCLK : in std_logic;
            iRST_N : in std_logic;
            I2C_SCLK : out std_logic;
            I2C_SDAT : inout std_logic;
            HDMI_TX_INT : in std_logic
        );
    end component;

    component pll 
        port (
            refclk : in std_logic;
            rst : in std_logic;
            outclk_0 : out std_logic;
            locked : out std_logic
        );
    end component;

   
    signal s_clk_27 : std_logic;
    signal s_rst_pll : std_logic;

    signal s_left_inc, s_left_dec   : std_logic;
    signal s_right_inc, s_right_dec : std_logic;

    signal s_count_left  : unsigned(9 downto 0) := (others => '0');
    signal s_count_right : unsigned(7 downto 0) := (others => '0');

begin

  
    o_hdmi_tx_d  <= (others => '0');
    o_hdmi_tx_de <= '0';
    o_hdmi_tx_hs <= '0';
    o_hdmi_tx_vs <= '0';
    o_hdmi_tx_clk <= s_clk_27;

    
    pll0 : component pll
        port map(
            refclk    => i_clk_50,
            rst       => not(i_rst_n),
            outclk_0  => s_clk_27,
            locked    => s_rst_pll
        );

    
    I2C_HDMI_Config0 : component I2C_HDMI_Config
        port map (
            iCLK        => i_clk_50,
            iRST_N      => i_rst_n,
            I2C_SCLK    => io_hdmi_i2c_scl,
            I2C_SDAT    => io_hdmi_i2c_sda,
            HDMI_TX_INT => i_hdmi_tx_int
        );


    encoder_left : entity work.encoder
        port map (
            i_clk   => s_clk_27,
            i_rst_n => s_rst_pll,
            i_ch_a  => i_left_ch_a,
            i_ch_b  => i_left_ch_b,
            o_inc   => s_left_inc,
            o_dec   => s_left_dec
        );

    process(s_clk_27, s_rst_pll)
    begin
        if s_rst_pll = '0' then
            s_count_left <= (others => '0');

        elsif rising_edge(s_clk_27) then
            if s_left_inc = '1' then
                s_count_left <= s_count_left + 1;
            elsif s_left_dec = '1' then
                s_count_left <= s_count_left - 1;
            end if;
        end if;
    end process;

    o_leds <= std_logic_vector(s_count_left);


    encoder_right : entity work.encoder
        port map (
            i_clk   => s_clk_27,
            i_rst_n => s_rst_pll,
            i_ch_a  => i_right_ch_a,
            i_ch_b  => i_right_ch_b,
            o_inc   => s_right_inc,
            o_dec   => s_right_dec
        );

    process(s_clk_27, s_rst_pll)
    begin
        if s_rst_pll = '0' then
            s_count_right <= (others => '0');

        elsif rising_edge(s_clk_27) then
            if s_right_inc = '1' then
                s_count_right <= s_count_right + 1;
            elsif s_right_dec = '1' then
                s_count_right <= s_count_right - 1;
            end if;
        end if;
    end process;

    o_de10_leds <= std_logic_vector(s_count_right);

end architecture rtl;