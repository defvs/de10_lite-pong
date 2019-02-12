-- DE10-LITE_Pong : Projet de Daniel Thirion, DUT GEII SALON DE PROVENCE, 2019
-- Réalisation d'un Pong sur la carte DE10-Lite avec utilisation du port VGA
-- Inclut un système de scores, des sons simples, et permet une customisation facile
--
-- 4 fichiers VHDL - Standard VHDL-2008, compilé sous Quartus Prime Lite 18.1
--  Pong.vhd (top-level)
--  |   seg7.vhd (7 segments)
--  |   VGA.vhd (sortie vidéo VGA)
--  |   sound.vhd (estion du son)
--  |   |   lpm_divide (Fonction diviseur de Altera, automatique)
--  |   \_
--  \_

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
        HEX0 : out std_logic_vector(0 to 6);

        GPIO : out std_logic_vector(0 downto 0);
        ARDUINO_IO : out std_logic_vector(2 downto 2)
    );
end Pong ;

architecture description of Pong is

    -- Constantes des tailles du jeu, en pixels

    constant ballSize : integer := 16; -- Taille de la balle
    constant paletHeight : integer := 128; -- Hauteur des raquettes
    constant paletWidth : integer := 16; -- Largeurs des raquettes

    -- Constantes des couleurs du jeu
    
    -- La couleur est sous forme 16#fff# avec fff les valeurs ROUGE VERT BLEU
    -- Astuce: utilisez Google (https://goo.gl/imyKPJ) ou tappez "Color Picker".
    -- Choisissez une couleur, regardez le code hexadécimal, et recopiez le comme ca:
    -- #12ab56
    -- Deviendra :
    -- 16#1a5# car on ne garde que le poids le plus fort pour chaque couleur.
    -- 12 est condensé en 1 ; ab est condensé en a ; 56 est condensé en 5
    -- Rouge 1 / Vert 10 (= a) / Bleu 5
    constant ballColor : integer := 16#c3f#; -- Couleur de la balle
    constant lPaletColor : integer := 16#4bf#; -- Couleur de la raquette gauche
    constant rPaletColor : integer := 16#f44#; -- droite
    constant backgroundColor : integer := 16#fff#; -- Couleur de fond



    alias clk is MAX10_CLK1_50; -- Alias horlong 50meg

    signal VGA_clk : std_logic; -- Horloge du fonctionnement VGA environ 25MHz

	signal VGA_x : integer range 0 to 639; -- Axe x (colonnes)
	signal VGA_y : integer range 0 to 479; -- Axe y (lignes)
    signal pixel : std_logic; -- Si '1', affichera un pixel blanc à l'emplacement du curseur
    signal color : integer range 0 to 4096; -- Couleur en héxadécimal

    -- Position verticale des raquettes
	signal lPalet : integer range 0 to 352 := 0; -- Raquette gauche
    signal rPalet : integer range 0 to 352 := 0; -- Droite
    alias lSW is SW(9); -- Alias pour le controle des raquettes gauche
    alias rSW is SW(0); -- et droite

    alias pause is SW(5); -- Switch n.5 = Pause du jeu

    signal gameTick : std_logic; -- Horloge du timing du jeux
    signal tickCounter : integer range 0 to 250000; -- Diviseur pour l'horloge du jeu, 100Hz

    type direction is (l_u, l_d, r_u, r_d);
    -- l = vers la droite // r = vers la gauche // u = vers le haut // d = vers le bas
    signal ballDir : direction := r_u;
    -- Position de la balle (point le plus en haut à gauche de celle-ci)
    signal ball_x : integer range 0 to 639 := 20; -- Position en x (colonnes)
    signal ball_y : integer range 0 to 479 := 300; -- Position en y (lignes)
    signal lScore : integer range 0 to 10 := 0; -- Score du joueur gauche
    signal rScore : integer range 0 to 10 := 0; -- Score du joueur droit

    signal currentSpeed : integer range 0 to 125000 := 125000; -- Vitesse actuelle du jeu; accelère avec le temps si personne ne marque

    signal gameStart : std_logic; -- Reset du jeu

    -- Variables pour le traitement du son
    signal playSound : std_logic;
    signal frequency : integer range 0 to 1000;
    signal duration : integer range 0 to 1000;
    signal oldDir : direction;
    signal oldlScore : integer range 0 to 10;
    signal oldrScore : integer range 0 to 10;

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
        color <= backgroundColor;
        pixel <= '0';
		if (VGA_x <= paletWidth) and (VGA_y >= lPalet) and (VGA_y <= (lPalet + paletHeight)) then -- Raquette 1
            color <= lPaletColor;
        elsif (VGA_x >= 639 - paletWidth) and (VGA_y >= rPalet) and (VGA_y <= (rPalet + paletHeight)) then -- Raquette 2
            color <= rPaletColor;
        elsif ((VGA_x >= ball_x) and (VGA_x <= (ball_x + ballSize)))
                and 
            ((VGA_y >= ball_y) and (VGA_y <= (ball_y + ballSize))) -- Balle
        then
            color <= ballColor;
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


    soundLib_sub : entity work.soundLib port map( -- Entitée pour le son
        clk, -- Horloge 50MHz
        frequency, -- Fréquence voulue
        duration, -- Durée voulue
        playSound, -- Front montant pour jouer
        ARDUINO_IO(2) -- Sortie vers le haut parleur
    );

    sound_trigger : process( clk ) --   Process pour le son. On est obligé de le faire en synchronisé sur l'horloge
    begin                          --   car on doit reset playSound au prochain front de 50Mhz
        if rising_edge(clk) then
            playSound <= '0';
            if oldDir /= ballDir then -- Changement de direction de la balle
                frequency <= 900;
                duration <= 100;
                playSound <= '1';
            end if;
            if oldlScore /= lScore or oldrScore /= rScore then --   Changement de score. 
                                                            --      Priorité par rapport au changement de direction
                frequency <= 500;
                duration <= 500;
                playSound <= '1';
            end if;
            oldDir <= ballDir; -- Variables buffer pour vérifier si la direction ou les scores ont changés
            oldlScore <= lScore; -- Sans devoir les mettres dans le process
            oldrScore <= rScore; -- Car c'est clk qui dirige le process.
        end if ;
    end process ; -- sound_trigger


end description ; -- work