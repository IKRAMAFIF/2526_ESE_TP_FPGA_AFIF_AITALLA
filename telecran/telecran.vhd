library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pll;
use pll.all;

entity telecran is
    port (
        -- FPGA
        i_clk_50 : in std_logic;

        -- HDMI
        io_hdmi_i2c_scl : inout std_logic;
        io_hdmi_i2c_sda : inout std_logic;
        o_hdmi_tx_clk  : out std_logic;
        o_hdmi_tx_d    : out std_logic_vector(23 downto 0);
        o_hdmi_tx_de   : out std_logic;
        o_hdmi_tx_hs   : out std_logic;
        i_hdmi_tx_int  : in  std_logic;
        o_hdmi_tx_vs   : out std_logic;

        -- Reset
        i_rst_n : in std_logic;

        -- LEDs
        o_leds      : out std_logic_vector(9 downto 0);
        o_de10_leds : out std_logic_vector(7 downto 0);

        -- Encodeurs
        i_left_ch_a  : in std_logic;
        i_left_ch_b  : in std_logic;
        i_left_pb    : in std_logic; -- bouton ACTIF BAS
        i_right_ch_a : in std_logic;
        i_right_ch_b : in std_logic;
        i_right_pb   : in std_logic
    );
end entity telecran;

architecture rtl of telecran is

    
    -- CONSTANTES
    
    constant h_res   : natural := 720;
    constant v_res   : natural := 480;
    constant FB_SIZE : natural := h_res * v_res;

    
    -- ENCODEUR GAUCHE (X)
    
    signal aL_d1, aL_d2, bL_d1, bL_d2 : std_logic := '0';
    signal aL_rise, aL_fall, bL_rise, bL_fall : std_logic;
    signal cnt_x : unsigned(9 downto 0) := (others => '0');

    
    -- ENCODEUR DROIT (Y)
    
    signal aR_d1, aR_d2, bR_d1, bR_d2 : std_logic := '0';
    signal aR_rise, aR_fall, bR_rise, bR_fall : std_logic;
    signal cnt_y : unsigned(9 downto 0) := (others => '0');

    
    -- enc_enable (~1 ms)
    
    signal enc_enable : std_logic := '0';

    
    -- POSITION PIXEL
    
    signal x_pos : natural range 0 to h_res-1;
    signal y_pos : natural range 0 to v_res-1;

    
    -- FRAMEBUFFER
    
    signal fb_addr_wr_reg : natural range 0 to FB_SIZE-1;
    signal fb_addr_rd     : natural range 0 to FB_SIZE-1;
    signal fb_data_wr     : std_logic_vector(7 downto 0);
    signal fb_data_rd     : std_logic_vector(7 downto 0);
    signal fb_data_rd_reg : std_logic_vector(7 downto 0);
    signal fb_we          : std_logic;

    
    -- EFFACEMENT 
	 
    signal clear_active  : std_logic := '0';
    signal clear_addr    : natural range 0 to FB_SIZE-1 := 0;
    signal clear_request : std_logic; -- bouton appuyé = 1

    
    -- HDMI / PLL
    
    component I2C_HDMI_Config
        port (
            iCLK        : in  std_logic;
            iRST_N      : in  std_logic;
            I2C_SCLK    : out std_logic;
            I2C_SDAT    : inout std_logic;
            HDMI_TX_INT : in  std_logic
        );
    end component;

    component pll
        port (
            refclk   : in  std_logic;
            rst      : in  std_logic;
            outclk_0 : out std_logic;
            locked   : out std_logic
        );
    end component;

    signal s_clk_27   : std_logic;
    signal pll_locked : std_logic;
    signal s_rst_n    : std_logic;

    signal s_hs, s_vs, s_de : std_logic;
    signal s_x_counter : natural range 0 to h_res-1;
    signal s_y_counter : natural range 0 to v_res-1;

begin

    
    -- BOUTON (ACTIF BAS)
    
    clear_request <= not i_left_pb;

    
    -- GESTION EFFACEMENT
    
    process(i_clk_50, i_rst_n)
    begin
        if i_rst_n = '0' then
            clear_active <= '0';
            clear_addr   <= 0;

        elsif rising_edge(i_clk_50) then
            if clear_request = '1' then
                clear_active <= '1';
                if clear_addr = FB_SIZE-1 then
                    clear_addr <= 0;
                else
                    clear_addr <= clear_addr + 1;
                end if;
            else
                clear_active <= '0';
                clear_addr   <= 0;
            end if;
        end if;
    end process;

    
    -- DÉTECTION FRONTS 
	 
    aL_rise <= '1' when (aL_d1='1' and aL_d2='0') else '0';
    aL_fall <= '1' when (aL_d1='0' and aL_d2='1') else '0';
    bL_rise <= '1' when (bL_d1='1' and bL_d2='0') else '0';
    bL_fall <= '1' when (bL_d1='0' and bL_d2='1') else '0';

    aR_rise <= '1' when (aR_d1='1' and aR_d2='0') else '0';
    aR_fall <= '1' when (aR_d1='0' and aR_d2='1') else '0';
    bR_rise <= '1' when (bR_d1='1' and bR_d2='0') else '0';
    bR_fall <= '1' when (bR_d1='0' and bR_d2='1') else '0';

   
    -- enc_enable (~1 ms)
  
    process(i_clk_50, i_rst_n)
        variable counter : natural range 0 to 5000 := 0;
    begin
        if i_rst_n = '0' then
            counter := 0;
            enc_enable <= '0';
        elsif rising_edge(i_clk_50) then
            if counter = 5000 then
                counter := 0;
                enc_enable <= '1';
            else
                counter := counter + 1;
                enc_enable <= '0';
            end if;
        end if;
    end process;

    
    -- ENCODEUR GAUCHE → X

    process(i_clk_50, i_rst_n)
    begin
        if i_rst_n = '0' then
            aL_d1 <= '0'; aL_d2 <= '0';
            bL_d1 <= '0'; bL_d2 <= '0';
            cnt_x <= (others => '0');

        elsif rising_edge(i_clk_50) then
            if enc_enable = '1' then
                aL_d1 <= i_left_ch_a;
                aL_d2 <= aL_d1;
                bL_d1 <= i_left_ch_b;
                bL_d2 <= bL_d1;

                if (aL_rise='1' and bL_d1='0') or
                   (aL_fall='1' and bL_d1='1') then
                    cnt_x <= cnt_x + 1;
                elsif (bL_rise='1' and aL_d1='0') or
                      (bL_fall='1' and aL_d1='1') then
                    cnt_x <= cnt_x - 1;
                end if;
            end if;
        end if;
    end process;

    
    -- ENCODEUR DROIT → Y
    
    process(i_clk_50, i_rst_n)
    begin
        if i_rst_n = '0' then
            aR_d1 <= '0'; aR_d2 <= '0';
            bR_d1 <= '0'; bR_d2 <= '0';
            cnt_y <= (others => '0');

        elsif rising_edge(i_clk_50) then
            if enc_enable = '1' then
                aR_d1 <= i_right_ch_a;
                aR_d2 <= aR_d1;
                bR_d1 <= i_right_ch_b;
                bR_d2 <= bR_d1;

                if (aR_rise='1' and bR_d1='0') or
                   (aR_fall='1' and bR_d1='1') then
                    cnt_y <= cnt_y + 1;
                elsif (bR_rise='1' and aR_d1='0') or
                      (bR_fall='1' and aR_d1='1') then
                    cnt_y <= cnt_y - 1;
                end if;
            end if;
        end if;
    end process;

    
    -- POSITION PIXEL
    
    x_pos <= to_integer(cnt_x) mod h_res;
    y_pos <= to_integer(cnt_y) mod v_res;

    
    -- ÉCRITURE FRAMEBUFFER
    
    fb_we      <= '1' when clear_active='1' else enc_enable;
    fb_data_wr <= x"00" when clear_active='1' else x"01";

    process(i_clk_50)
    begin
        if rising_edge(i_clk_50) then
            if clear_active = '1' then
                fb_addr_wr_reg <= clear_addr;
            elsif enc_enable = '1' then
                fb_addr_wr_reg <= y_pos * h_res + x_pos;
            end if;
        end if;
    end process;

    fb_addr_rd <= s_y_counter * h_res + s_x_counter;

    
    -- DPRAM
    
    u_fb : entity work.dpram
        generic map (
            mem_size   => FB_SIZE,
            data_width => 8
        )
        port map (
            i_clk_a   => i_clk_50,
            i_data_a  => fb_data_wr,
            i_addr_a  => fb_addr_wr_reg,
            i_we_a    => fb_we,
            o_q_a     => open,

            i_clk_b   => s_clk_27,
            i_data_b  => (others => '0'),
            i_addr_b  => fb_addr_rd,
            i_we_b    => '0',
            o_q_b     => fb_data_rd
        );

    process(s_clk_27)
    begin
        if rising_edge(s_clk_27) then
            fb_data_rd_reg <= fb_data_rd;
        end if;
    end process;

    
    -- PLL + HDMI
    
    pll0 : pll
        port map (
            refclk   => i_clk_50,
            rst      => not i_rst_n,
            outclk_0 => s_clk_27,
            locked   => pll_locked
        );

    s_rst_n <= i_rst_n and pll_locked;

    I2C_HDMI_Config0 : I2C_HDMI_Config
        port map (
            iCLK        => i_clk_50,
            iRST_N      => i_rst_n,
            I2C_SCLK    => io_hdmi_i2c_scl,
            I2C_SDAT    => io_hdmi_i2c_sda,
            HDMI_TX_INT => i_hdmi_tx_int
        );

    u_hdmi_ctrl : entity work.hdmi_controler
        generic map (
            h_res => h_res, v_res => v_res,
            h_sync => 61, h_fp => 58, h_bp => 18,
            v_sync => 5,  v_fp => 30, v_bp => 9
        )
        port map (
            i_clk => s_clk_27,
            i_rst_n => s_rst_n,
            o_hdmi_hs => s_hs,
            o_hdmi_vs => s_vs,
            o_hdmi_de => s_de,
            o_x_counter => s_x_counter,
            o_y_counter => s_y_counter,
            o_pixel_en => open,
            o_pixel_address => open
        );

    o_hdmi_tx_clk <= s_clk_27;
    o_hdmi_tx_hs  <= s_hs;
    o_hdmi_tx_vs  <= s_vs;
    o_hdmi_tx_de  <= s_de;

    
    -- AFFICHAGE HDMI
    
    process(s_clk_27)
    begin
        if rising_edge(s_clk_27) then
            if s_de='1' and fb_data_rd_reg /= x"00" then
                o_hdmi_tx_d <= x"FFFFFF";
            else
                o_hdmi_tx_d <= x"000000";
            end if;
        end if;
    end process;

    
    -- LEDs
    
    o_leds <= std_logic_vector(cnt_x);
    o_de10_leds <= (others => '0');

end architecture rtl;