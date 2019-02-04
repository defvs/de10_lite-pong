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
        HEX4 : out std_logic_vector(0 to 6);
        HEX1 : out std_logic_vector(0 to 6);
        HEX0 : out std_logic_vector(0 to 6)
    );
end Pong ;

architecture description of Pong is
    alias clk is MAX10_CLK1_50; -- Alias horlong 50meg

    signal VGA_clk : std_logic; -- Horloge du fonctionnement VGA environ 25MHz

	signal VGA_x : integer range 0 to 639; -- Axe x (colonnes)
	signal VGA_y : integer range 0 to 479; -- Axe y (lignes)
    signal pixel : std_logic; -- Si '1', affichera un pixel blanc à l'emplacement du curseur
    signal color : integer range 0 to 4096;

    -- Position verticale des raquettes
	signal lPalet : integer range 0 to 352 := 0; -- Raquette gauche
    signal rPalet : integer range 0 to 352 := 0; -- Droite
    constant paletHeight : integer := 128;
    constant paletWidth : integer := 16;
    alias lSW is SW(9); -- Alias pour le controle des raquettes gauche
    alias rSW is SW(0); -- et droite

    alias pause is SW(5);

    signal gameTick : std_logic; -- Horloge du timing du jeux
    signal tickCounter : integer range 0 to 250000; -- Diviseur pour l'horloge du jeu, 100Hz

    type direction is (l_u, l_d, r_u, r_d);
    -- l = vers la droite // r = vers la gauche // u = vers le haut // d = vers le bas
    signal ballDir : direction := r_u;
    -- Position de la balle (point le plus en haut à gauche de celle-ci)
    signal ball_x : integer range 0 to 639 := 20; -- Position en x (colonnes)
    signal ball_y : integer range 0 to 479 := 300; -- Position en y (lignes)
    constant ballSize : integer := 16;

    signal lScore : integer range 0 to 10 := 0; -- Score du joueur gauche
    signal rScore : integer range 0 to 10 := 0; -- Score du joueur droit

    signal currentSpeed : integer range 0 to 125000 := 125000; -- Vitesse actuelle du jeu; accelère avec le temps si personne ne marque

    signal gameStart : std_logic; -- Reset du jeu

begin
    VGA_Divider : process( clk ) -- 25MHz pour le VGA
    begin
        if rising_edge(clk) then
            VGA_clk <= not VGA_clk;
        end if ;
    end process ; -- VGA_Divider
    
    VGA_Sub : entity work.VGA port map( -- Entitée contrôle écran VGA
            clk => VGA_clk, -- Horloge VGA
            HS => VGA_HS, -- Signal synchro horizontal
            VS => VGA_VS, -- Signal synchro verticale
            R_out => VGA_R, -- Signal rouge sortie
            G_out => VGA_G, -- Signal vert sortie
            B_out => VGA_B, -- Signal bleu sortie
            x => VGA_x, -- Coordonnées X actuelles
            y => VGA_y, -- Coordonnées Y actuelles
            RGB_in => color,
            pixel => pixel -- Signal forcé couleur blanche
    );

	pixel_print : process( VGA_x, VGA_y ) -- Choisis d'afficher un pixel ou non
    begin
        color <= 16#000#;
        pixel <= '0';
		if (VGA_x <= paletWidth) and (VGA_y >= lPalet) and (VGA_y <= (lPalet + paletHeight)) then -- Raquette 1
            color <= 16#4bf#;
        elsif (VGA_x >= 639 - paletWidth) and (VGA_y >= rPalet) and (VGA_y <= (rPalet + paletHeight)) then -- Raquette 2
            color <= 16#f44#;
        elsif ((VGA_x >= ball_x) and (VGA_x <= (ball_x + ballSize)))
                and 
            ((VGA_y >= ball_y) and (VGA_y <= (ball_y + ballSize))) -- Balle
        then
            color <= 16#c3f#;
        else
            pixel <= '0';
		end if ;
    end process ; -- pixel_print
    
    tick_div : process( clk ) -- Diviseur pour l'horloge du jeu
    begin
        if rising_edge(clk) and pause = '0' then
            if tickCounter = currentSpeed then
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
            if lSW = '1' then -- Raquette gauche
                if lPalet > 0 then
                    lPalet <= lPalet - 1;
                end if ;
            else
                if lPalet < (480 - paletHeight) then
                    lPalet <= lPalet + 1;
                end if ;
            end if ;

            if rSW = '1' then -- Raquette droite
                if rPalet > 0 then
                    rPalet <= rPalet - 1;
                end if ;
            else
                if rPalet < (480 - paletHeight) then
                    rPalet <= rPalet + 1;
                end if ;
            end if ;
        end if ;
    end process ; -- palet_movement

    ball_movement : process( gameTick ) -- Mouvement de la balle
    begin
        if rising_edge(gameTick) then
            if gameStart = '1' then
                if (ballDir = l_u) or (ballDir = l_d) then -- Direction vers la gauche
                    ball_x <= ball_x - 1;
                    if ball_x <= paletWidth + 1 and ((ball_y <= (lPalet + paletHeight) and ball_y >= lPalet) 
                        or (ball_y + ballSize <= (lPalet + paletHeight) and ball_y + ballSize >= lPalet)) then -- Touche la raquette
                        case( ballDir ) is
                            when l_d => ballDir <= r_d;
                            when l_u => ballDir <= r_u;
                            when others => ballDir <= r_u;
                        end case;
                        if currentSpeed >= 5000 then
                            currentSpeed <= currentSpeed - 5000;
                        end if ;
                    end if ;
                end if ;
                if (ballDir = r_u) or (ballDir = r_d) then -- Direction vers la droite
                    ball_x <= ball_x + 1;
                    if ball_x >= (639 - paletWidth - 1 - ballSize) and ((ball_y <= (rPalet + paletHeight) and ball_y >= rPalet) 
                        or (ball_y + ballSize <= (rPalet + paletHeight) and ball_y + ballSize >= rPalet)) then -- Touche la raquette
                        case( ballDir ) is
                            when r_d => ballDir <= l_d;
                            when r_u => ballDir <= l_u;
                            when others => ballDir <= l_u;
                        end case ;
                        if currentSpeed >= 5000 then
                            currentSpeed <= currentSpeed - 5000;
                        end if ;
                    end if ;
                end if ;
                if (ballDir = l_u) or (ballDir = r_u) then -- Direction vers le haut
                    ball_y <= ball_y - 1;
                    if ball_y = 0 then
                        case( ballDir ) is
                            when l_u => ballDir <= l_d;
                            when r_u => ballDir <= r_d;
                            when others => ballDir <= r_d;
                        end case ;
                    end if ;
                end if ;
                if (ballDir = l_d) or (ballDir = r_d) then -- Direction vers le bas
                    ball_y <= ball_y + 1;
                    if ball_y = 480 - ballSize then
                        case( ballDir ) is
                            when r_d => ballDir <= r_u;
                            when l_d => ballDir <= l_u;
                            when others => ballDir <= l_u;
                        end case ;
                    end if ;
                end if ;
                if ball_x = 0 then -- Si la balle arrive derrière la raquette gauche
                    ballDir <= r_u;
                    ball_x <= 20;
                    ball_y <= 300;
                    rScore <= rScore + 1;
                    currentSpeed <= 125000;
                end if ;
                if ball_x = (639 - ballSize) then -- Si la balle arrive derrière la raquette droite
                    ballDir <= l_u;
                    ball_x <= 619;
                    ball_y <= 300;
                    lScore <= lScore + 1;
                    currentSpeed <= 125000;
                end if ;
                if lScore = 10 or rScore = 10 then -- Si un des deux scores arrive à 10
                    gameStart <= '0';
                end if ;
            else -- Reset de la partie (balle, score)
                ballDir <= r_u; 
                ball_x <= 20;
                ball_y <= 300;
                lScore <= 0;
                rScore <= 0;
                gameStart <= '1';
            end if ;
        end if ;
    end process ; -- ball_movement

    seg7_sub : entity work.seg7 port map( -- Entitée afficheur 7 segments
        rScore, -- Score droite mappé sur seg0
        0, 0, 0, 0, -- Pas interessé par les autres afficheurs
        lScore, -- Score gauche mappé sur seg5
        HEX0, -- Sortie sur afficheur de droite
        open, open, open, open, -- Pas interessé
        HEX5 -- Sortie sur afficheur de gauche
    );

    score_print : process( lScore, rScore ) -- Afficheur du score sur les 7seg
    begin
        case( lScore ) is -- Score gauche
            when 1 to 9 =>
                HEX1 <= (others => '1');
                HEX4 <= (others => '1');
            when 10 =>
                HEX4 <= not "1100010";
                HEX1 <= not "0001000";
            when 0 =>
        end case ;
        case( rScore ) is -- Score droit
            when 1 to 9 =>
                HEX1 <= (others => '1');
                HEX4 <= (others => '1');
            when 10 =>
                HEX1 <= not "1100010";
                HEX4 <= not "0001000";
            when 0 =>
        end case ;
    end process ; -- score_print


end architecture ; -- work