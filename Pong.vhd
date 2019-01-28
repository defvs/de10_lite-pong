library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity Pong is port (
	MAX10_CLK1_50 : in std_logic;
	VGA_HS : buffer std_logic;
	VGA_VS : buffer std_logic;
	GPIO: buffer std_logic_vector (1 downto 0)
);
end Pong ;

architecture work of Pong is
	signal VGA_h: std_logic;
	signal compteur_h: integer range 0 to 799;
	signal compteur_v: integer range 0 to 524;
begin
	diviseur_vga :process(MAX10_CLK1_50)
	begin
		if rising_edge(MAX10_CLK1_50) then 
			VGA_h <= not VGA_h;
		end if;
	end process diviseur_vga;

	synchro_h : process(VGA_h)
	begin
		if rising_edge(VGA_h) then
			compteur_h <= compteur_h + 1;

			case (compteur_h) is
				when 703 => VGA_HS <='0'; 
				when 0 => VGA_HS <= '1';
				when 799 => compteur_h <= 0;
				when others =>
			end case;
		end if;
	end process synchro_h;

	synchro_v : process(VGA_HS)
	begin 
		if rising_edge(VGA_HS) then 
			compteur_v <= compteur_v +1;

			case (compteur_v) is 
				when 0 => VGA_VS <='1';
				when 522 => VGA_VS <='0';
				when 524 => compteur_v <= 0;
				when others =>
			end case;
		end if;
	end process synchro_v;

	GPIO(0) <= VGA_HS;
	GPIO(1) <= VGA_VS;

end architecture ;