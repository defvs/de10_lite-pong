library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity Pong is
  port (
    MAX10_CLK1_50 : in std_logic;

    VGA_HS : buffer std_logic;
    VGA_VS : buffer std_logic;
    VGA_R : buffer integer range 0 to 15;
    VGA_G : buffer integer range 0 to 15;
    VGA_B : buffer integer range 0 to 15;

    SW : in std_logic_vector(2 downto 0);
    LEDR : out std_logic_vector(1 downto 0);
    GPIO : out std_logic_vector(1 downto 0)
  ) ;
end Pong ;

architecture work of Pong is
    alias clk is MAX10_CLK1_50;

    signal VGA_clk : std_logic;
    signal hsync_counter : integer range 0 to 799;
    signal vsync_counter : integer range 0 to 524;

    signal h_video : std_logic;
    signal v_video : std_logic;

begin
    VGA_Divider : process( clk ) -- 25MHz
    begin
        if rising_edge(clk) then
            VGA_clk <= not VGA_clk;
        end if ;
    end process ; -- VGA_Divider

    VGA_hsync : process( VGA_clk )
    begin
        if rising_edge(VGA_clk) then
            if hsync_counter = 799 then
                hsync_counter <= 0;
            else
                hsync_counter <= hsync_counter + 1;
            end if ;
            case( hsync_counter ) is
                when 0 => VGA_HS <= '1';
                when 703 => VGA_HS <= '0';
                when others =>
            end case ;
            
            case( hsync_counter ) is
                when 44 to 684 =>
                    h_video <= '1';
                when others =>
                    h_video <= '0';
            end case ;
        end if ;
    end process ; -- VGA_hsync

    VGA_vsync : process( VGA_HS )
    begin
        if rising_edge(VGA_HS) then
            if vsync_counter = 525 then
                vsync_counter <= 0;
            else
                vsync_counter <= vsync_counter + 1;
            end if ;

            case( vsync_counter ) is
                when 0 => VGA_VS <= '1';
                when 522 => VGA_VS <= '0';
                when others =>
            end case ;

            case( vsync_counter ) is
                when 30 to 519 =>
                    v_video <= '1';
                when others =>
                    v_video <= '0';
            end case ;
        end if ;
    end process ; -- VGA_vsync

    VGA_pixel : process( VGA_clk )
    begin
        if rising_edge(VGA_clk) then
            if v_video = '1' and h_video = '1' then
                if SW(0) = '1' then
                    VGA_R <= 15;
                else
                    VGA_R <= 0;
                end if ;

                if SW(1) = '1' then
                    VGA_G <= 15;
                else
                    VGA_G <= 0;
                end if ;

                if SW(2) = '1' then
                    VGA_B <= 15;
                else
                    VGA_B <= 15;
                end if ;
            else
                VGA_R <= 0;
                VGA_G <= 0;
                VGA_B <= 0;
            end if ;
        end if ;
    end process ; -- VGA_pixel

    LEDR(0) <= VGA_HS;
    LEDR(1) <= VGA_VS;

    GPIO(0) <= VGA_HS;
    GPIO(1) <= VGA_VS;


end architecture ; -- work