library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity Pong is
  port (
    MAX10_CLK1_50 : in std_logic;
    VGA_HS : buffer std_logic;
    VGA_VS : buffer std_logic;
    
    LEDR : out std_logic_vector(1 downto 0);
    GPIO : out std_logic_vector(1 downto 0)
  ) ;
end Pong ;

architecture work of Pong is
    alias clk is MAX10_CLK1_50;

    signal VGA_clk : std_logic;
    signal hsync_counter : integer range 0 to 799;
    signal vsync_counter : integer range 0 to 524;


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
        end if ;
    end process ; -- VGA_vsync

    LEDR(0) <= VGA_HS;
    LEDR(1) <= VGA_VS;

    GPIO(0) <= VGA_HS;
    GPIO(1) <= VGA_VS;


end architecture ; -- work