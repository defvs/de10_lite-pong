-- DE10-LITE_Pong : Projet de Daniel Thirion, DUT GEII SALON DE PROVENCE, 2019
library ieee ;
	use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

-- Entitée qui vise à faciliter l'utilisation d'un écran VGA
-- Usage :
--  * clk INPUT => Horloge de 25Mhz
--  * HS / VS OUTPUT => A rediriger vers le VGA, synchronisation
--  * R/G/B_in INPUT => Signaux de couleurs sur 4 bits
--  * R/G/B_out OUTPUT => A rediriger vers le VGA, couleurs
-- 
    
entity VGA is
  port (
    clk : in std_logic;
    HS : buffer std_logic;
    VS : out std_logic;
    RGB_in : in integer range 0 to 4096; -- RGB en hexa.
    -- 4 bits = R / 4 bits = G / 4 bits = B

    R_out : out integer range 0 to 15;
    G_out : out integer range 0 to 15;
    B_out : out integer range 0 to 15;

    pixel : in std_logic;

    x : out integer range 0 to 639;
    y : out integer range 0 to 479
  ) ;
end VGA ;

architecture description of VGA is
    signal hsync_counter : integer range 0 to 799; -- Compteur de synchro horizontale (lignes)
    signal vsync_counter : integer range 0 to 524; -- Compteur de synchro verticale (frames)

    signal H_VIDEO : std_logic;
    signal V_VIDEO : std_logic;
begin
    VGA_hsync : process( clk ) -- Synchronisation horizontale par ligne
    begin
        if rising_edge(clk) then
            if hsync_counter = 799 then
                hsync_counter <= 0;
            else
                hsync_counter <= hsync_counter + 1;
            end if ;
            case( hsync_counter ) is
                when 0 => HS <= '1';
                when 703 => HS <= '0';
                when others =>
            end case ;
            
            case( hsync_counter ) is
                when 44 to 683 => -- Dans la zone d'affichage
					H_VIDEO <= '1';
					x <= hsync_counter - 44;
                when others => -- Hors de la zone
					H_VIDEO <= '0';
					x <= 0;
            end case ;
        end if ;
    end process ; -- VGA_hsync

    VGA_vsync : process( HS ) -- Synchronisation verticale par trame
    begin
        if rising_edge(HS) then
            if vsync_counter = 525 then
                vsync_counter <= 0;
            else
                vsync_counter <= vsync_counter + 1;
            end if ;

            case( vsync_counter ) is
                when 0 => VS <= '1';
                when 522 => VS <= '0';
                when others =>
            end case ;

            case( vsync_counter ) is
                when 30 to 509 => -- Dans la zone d'affichage
					V_VIDEO <= '1';
					y <= vsync_counter - 30;
                when others => -- Hors de la zone
					V_VIDEO <= '0';
					y <= 0;
            end case ;
        end if ;
    end process ; -- VGA_vsync

    VGA_pixel : process( clk ) -- Change les valeurs de couleurs
    begin
        if rising_edge(clk) then
			if V_VIDEO = '1' and H_VIDEO = '1' then
				if pixel = '1' then -- Afficher du blanc
					R_out <= 15;
					G_out <= 15;
					B_out <= 15;
				else -- Afficher la couleur donnée en hexa
					R_out <= to_integer(to_unsigned(RGB_in,12)(11 downto 8));
					G_out <= to_integer(to_unsigned(RGB_in,12)(7 downto 4));
					B_out <= to_integer(to_unsigned(RGB_in,12)(3 downto 0));
				end if ;
            else -- Ne rien afficher
                R_out <= 0;
                G_out <= 0;
                B_out <= 0;
            end if ;
        end if ;
    end process ; -- VGA_pixel
end architecture ; -- description