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

    SW : in std_logic_vector(9 downto 0);
    HEX5 : out std_logic_vector(0 to 6);
    HEX0 : out std_logic_vector(0 to 6);

    LEDR : out std_logic_vector(1 downto 0);
    GPIO : out std_logic_vector(1 downto 0)
  ) ;
end Pong ;

architecture work of Pong is
    alias clk is MAX10_CLK1_50; -- Alias horlong 50meg

    signal VGA_clk : std_logic; -- Horloge du fonctionnement VGA environ 25MHz
    signal hsync_counter : integer range 0 to 799; -- Compteur de synchro horizontale (lignes)
    signal vsync_counter : integer range 0 to 524; -- Compteur de synchro verticale (frames)

    signal h_video : std_logic; -- Autorise l'affichage (dans la trame)
	signal v_video : std_logic; -- Pareil
    
    -- Position actuelle du curseur dans la trame
	signal VGA_x : integer range 0 to 639; -- Axe x (colonnes)
	signal VGA_y : integer range 0 to 479; -- Axe y (lignes)
	signal pixel : std_logic; -- Si '1', affichera un pixel blanc à l'emplacement du curseur

    -- Position verticale des raquettes
	signal lPalet : integer range 0 to 352 := 0; -- Raquette gauche
    signal rPalet : integer range 0 to 352 := 0; -- Droite
    alias lSW is SW(9); -- Alias pour le controle des raquettes gauche
    alias rSW is SW(0); -- et droite

    signal gameTick : std_logic; -- Horloge du timing du jeux
    signal tickCounter : integer range 0 to 250000; -- Diviseur pour l'horloge du jeu, 100Hz

    type direction is (l_u, l_d, r_u, r_d);
    -- l = vers la droite // r = vers la gauche // u = vers le haut // d = vers le bas
    signal ballDir : direction := l_u;
    -- Position de la balle (point le plus en haut à gauche de celle-ci)
    signal ball_x : integer range 0 to 639 := 20; -- Position en x (colonnes)
    signal ball_y : integer range 0 to 479 := 300; -- Position en y (lignes)

    signal lScore : integer range 0 to 10;
    signal rScore : integer range 0 to 10;
    -- signal pause : std_logic := '0';

begin
    VGA_Divider : process( clk ) -- 25MHz
    begin
        if rising_edge(clk) then
            VGA_clk <= not VGA_clk;
        end if ;
    end process ; -- VGA_Divider

    VGA_hsync : process( VGA_clk ) -- Synchronisation horizontale par ligne
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
                when 44 to 683 =>
					h_video <= '1';
					VGA_x <= hsync_counter - 44;
                when others =>
					h_video <= '0';
					VGA_x <= 0;
            end case ;
        end if ;
    end process ; -- VGA_hsync

    VGA_vsync : process( VGA_HS ) -- Synchronisation verticale par trame
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
                when 30 to 518 =>
					v_video <= '1';
					VGA_y <= vsync_counter - 30;
                when others =>
					v_video <= '0';
					VGA_y <= 0;
            end case ;
        end if ;
    end process ; -- VGA_vsync

    VGA_pixel : process( VGA_clk ) -- Change les valeurs de couleurs
    begin
        if rising_edge(VGA_clk) then
			if v_video = '1' and h_video = '1' then
				if pixel = '1' then
					VGA_R <= 15;
					VGA_G <= 15;
					VGA_B <= 15;
				else
					VGA_R <= 0;
					VGA_G <= 0;
					VGA_B <= 0;
				end if ;
            else
                VGA_R <= 0;
                VGA_G <= 0;
                VGA_B <= 0;
            end if ;
        end if ;
    end process ; -- VGA_pixel

	pixel_print : process( VGA_x, VGA_y ) -- Choisis d'afficher un pixel ou non
	begin
		if (VGA_x <= 16) and (VGA_y >= lPalet) and (VGA_y <= (lPalet + 128)) then -- Raquette 1
            pixel <= '1';
        elsif (VGA_x >= 639 - 16) and (VGA_y >= rPalet) and (VGA_y <= (rPalet + 128)) then -- Raquette 2
            pixel <= '1';
        elsif ((VGA_x >= ball_x) and (VGA_x <= (ball_x + 16)))
                and 
            ((VGA_y >= ball_y) and (VGA_y <= (ball_y + 16))) -- Balle
        then
            pixel <= '1';
        else
            pixel <= '0';
		end if ;
    end process ; -- pixel_print
    
    tick_div : process( clk ) -- Diviseur pour l'horloge du jeu
    begin
        if rising_edge(clk) then
            if tickCounter = 250000 then
                tickCounter <= 0;
                gameTick <= not gameTick;
            else
                tickCounter <= tickCounter + 1;
            end if ;
        end if ;
    end process ; -- tick_div

    palet_movement : process( gameTick ) -- Mouvement des raquettes
    begin
        if rising_edge(gameTick) then
            if lSW = '1' then
                if lPalet > 0 then
                    lPalet <= lPalet - 1;
                end if ;
            else
                if lPalet < (480 - 128) then
                    lPalet <= lPalet + 1;
                end if ;
            end if ;

            if rSW = '1' then
                if rPalet > 0 then
                    rPalet <= rPalet - 1;
                end if ;
            else
                if rPalet < (480 - 128) then
                    rPalet <= rPalet + 1;
                end if ;
            end if ;
        end if ;
    end process ; -- palet_movement

    ball_movement : process( gameTick ) -- Mouvement de la balle
    begin
        if rising_edge(gameTick) then
            if (ballDir = l_u) or (ballDir = l_d) then
                ball_x <= ball_x - 1;
                if ball_x <= 17 and (ball_y <= (lPalet + 128) and ball_y >= lPalet) then
                    case( ballDir ) is
                        when l_d => ballDir <= r_d;
                        when l_u => ballDir <= r_u;
                        when others => ballDir <= r_u;
                    end case ;
                end if ;
            end if ;
            if (ballDir = r_u) or (ballDir = r_d) then
                ball_x <= ball_x + 1;
                if (ball_x = (639 - 17 - 16)) and (ball_y <= (rPalet + 128) and ball_y >= rPalet) then
                    case( ballDir ) is
                        when r_d => ballDir <= l_d;
                        when r_u => ballDir <= l_u;
                        when others => ballDir <= l_u;
                    end case ;
                end if ;
            end if ;
            if (ballDir = l_u) or (ballDir = r_u) then
                ball_y <= ball_y - 1;
                if ball_y = 0 then
                    case( ballDir ) is
                        when l_u => ballDir <= l_d;
                        when r_u => ballDir <= r_d;
                        when others => ballDir <= r_d;
                    end case ;
                end if ;
            end if ;
            if (ballDir = l_d) or (ballDir = r_d) then
                ball_y <= ball_y + 1;
                if ball_y = 480 - 16 then
                    case( ballDir ) is
                        when r_d => ballDir <= r_u;
                        when l_d => ballDir <= l_u;
                        when others => ballDir <= l_u;
                    end case ;
                end if ;
            end if ;
            if ball_x = 0 then
                ballDir <= r_u;
                ball_x <= 20;
                ball_y <= 300;
                rScore <= rScore + 1;
            end if ;
            if ball_x = (639 - 16) then
                ballDir <= l_u;
                ball_x <= 619;
                ball_y <= 300;
                lScore <= lScore + 1;
            end if ;
        end if ;
    end process ; -- ball_movement

    -- game_end : process( ball_x )
    -- begin
    -- end process ; -- game_end

    score_print : process( lScore, rScore )
    begin
        case( lScore ) is
            when 0 =>
                HEX5 <= not "1111110";
            when 1 =>
                HEX5 <= not "0110000";
            when 2 =>
                HEX5 <= not "1101101";
            when 3 =>
                HEX5 <= not "1111001";
            when 4 =>
                HEX5 <= not "0110011";
            when 5 =>
                HEX5 <= not "1011011";
            when 6 =>
                HEX5 <= not "1011111";
            when 7 =>
                HEX5 <= not "1110000";
            when 8 =>
                HEX5 <= (others => '0');
            when 9 =>
                HEX5 <= not "1111011";
            when 10 =>
                HEX5 <= not "1100010";
                HEX0 <= not "0001000";
                -- pause <= '1';
        end case ;
        case( rScore ) is
            when 0 =>
                HEX0 <= not "1111110";
            when 1 =>
                HEX0 <= not "0110000";
            when 2 =>
                HEX0 <= not "1101101";
            when 3 =>
                HEX0 <= not "1111001";
            when 4 =>
                HEX0 <= not "0110011";
            when 5 =>
                HEX0 <= not "1011011";
            when 6 =>
                HEX0 <= not "1011111";
            when 7 =>
                HEX0 <= not "1110000";
            when 8 =>
                HEX0 <= (others => '0');
            when 9 =>
                HEX0 <= not "1111011";
            when 10 =>
                HEX0 <= not "1100010";
                HEX5 <= not "0001000";
                -- pause <= '1';
        end case ;
    end process ; -- score_print

    -- Debug Signaux
    LEDR(0) <= VGA_HS;
    LEDR(1) <= VGA_VS;

    GPIO(0) <= VGA_HS;
    GPIO(1) <= VGA_VS;
    -- end Debug


end architecture ; -- work