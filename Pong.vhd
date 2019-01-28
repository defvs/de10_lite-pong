library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity Pong is
  port (
    MAX10_CLK1_50 : in std_logic;
    VGA_HS : buffer std_logic;
    VGA_VS : buffer std_logic
    
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
            hsync_counter <= hsync_counter + 1;
            if hsync_counter = 0 then
                VGA_HS <= '1';
            elsif hsync_counter = 703 then
                VGA_HS <= '0';
            end if ;
        end if ;
    end process ; -- VGA_hsync

    VGA_vsync : process( VGA_HS )
    begin
        if falling_edge(VGA_HS) then
            vsync_counter <= vsync_counter + 1;
            if vsync_counter = 522 then
                VGA_VS <= '0';
            elsif vsync_counter = 0 then
                VGA_VS <= '1';
            end if ;
        end if ;
    end process ; -- VGA_vsync



end architecture ; -- work