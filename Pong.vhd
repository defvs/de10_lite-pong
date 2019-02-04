library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity Pong is port (
	MAX10_CLK1_50 : in std_logic;
	VGA_HS : buffer std_logic;
	VGA_VS : buffer std_logic;
	GPIO: buffer std_logic_vector (1 downto 0);
	SW : in std_logic_vector (2 downto 0);
	VGA_R : out integer range 0 to 15;
	VGA_G : out integer range 0 to 15;
	VGA_B : out integer range 0 to 15
	);
end Pong ;

architecture work of Pong is
	signal VGA_h: std_logic;
	signal compteur_h: integer range 0 to 799;
	signal compteur_v: integer range 0 to 524;
	signal video_h : std_logic;
	signal video_v : std_logic;
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
			
			case (compteur_h) is
				when 44 to 683 => video_h <= '1';
				when others => video_h <= '0';
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
			
			case (compteur_v) is
				when 30 to 509 => video_v <= '1';
				when others => video_v <= '0';
			end case;
		end if;
	end process synchro_v;
	
	bande : process(compteur_h,compteur_v)
	begin
		if compteur_v <= 80 and compteur_v >=50 then
			VGA_R <= 15;
		else 
			VGA_R <= 0;
		end if;
		if compteur_v <= 400 and compteur_v >= 200 and compteur_h >= 400 and compteur_h <= 600 then
			VGA_G <= 15;
		else
			VGA_G <=0;
		end if;
	end process bande;
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
--	golli : process(video_h,video_v)
--	begin
--		if video_h = '1' and video_v = '1' then 
--			if SW(0) = '1' then
--				VGA_R <= 15;
--			else 
--				VGA_R <= 0;
--			end if ;
--			if SW(1) = '1' then
--				VGA_B <= 15;
--			else 
--				VGA_B <= 0;
--			end if;
--			if SW(2) = '1' then
--				VGA_G <= 15;
--			else 
--				VGA_G <= 0;
--			end if;
--		else
--			VGA_R <= 0;
--			VGA_B <= 0;
--			VGA_G <= 0;
--		end if;
--	end process golli;

	GPIO(0) <= VGA_HS;
	GPIO(1) <= VGA_VS;

end architecture ;