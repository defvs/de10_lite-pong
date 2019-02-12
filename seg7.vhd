-- DE10-LITE_Pong : Projet de Daniel Thirion, DUT GEII SALON DE PROVENCE, 2019
library ieee ;
	use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

-- Entitée permettant l'affichage rapide sur le(s) 7 segments de la carte DE10-Lite
-- Chaque segment est indépendant.
-- 
-- Signaux :
--  * seg[5..0] : Entier de 0 à 9 qui sera affiché sur l'afficheur correspondant. Si entre 10 et 15, ne rien afficher.
--  * HEX[5..0] : Sorties vers les afficheurs, à mapper.

entity seg7 is
  port (
    seg0 : in integer range 0 to 15;
    seg1 : in integer range 0 to 15;
    seg2 : in integer range 0 to 15;
    seg3 : in integer range 0 to 15;
    seg4 : in integer range 0 to 15;
    seg5 : in integer range 0 to 15;

    HEX0 : out std_logic_vector(0 to 6);
    HEX1 : out std_logic_vector(0 to 6);
    HEX2 : out std_logic_vector(0 to 6);
    HEX3 : out std_logic_vector(0 to 6);
    HEX4 : out std_logic_vector(0 to 6);
    HEX5 : out std_logic_vector(0 to 6)  
);
end seg7 ;

architecture description of seg7 is
begin
    print0 : process( seg0 )
    begin
        HEX0 <= (others => '1');
        case( seg0 ) is
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
            when others =>
                HEX0 <= (others => '1');
        end case ;
    end process ; -- print0
    print1 : process( seg1 )
    begin
        HEX1 <= (others => '1');
        case( seg1 ) is
            when 0 =>
                HEX1 <= not "1111110";
            when 1 =>
                HEX1 <= not "0110000";
            when 2 =>
                HEX1 <= not "1101101";
            when 3 =>
                HEX1 <= not "1111001";
            when 4 =>
                HEX1 <= not "0110011";
            when 5 =>
                HEX1 <= not "1011011";
            when 6 =>
                HEX1 <= not "1011111";
            when 7 =>
                HEX1 <= not "1110000";
            when 8 =>
                HEX1 <= (others => '0');
            when 9 =>
                HEX1 <= not "1111011";
            when others =>
                HEX1 <= (others => '1');
        end case ;
    end process ; -- print1
    print2 : process( seg2 )
    begin
        HEX2 <= (others => '1');
        case( seg2 ) is
            when 0 =>
                HEX2 <= not "1111110";
            when 1 =>
                HEX2 <= not "0110000";
            when 2 =>
                HEX2 <= not "1101101";
            when 3 =>
                HEX2 <= not "1111001";
            when 4 =>
                HEX2 <= not "0110011";
            when 5 =>
                HEX2 <= not "1011011";
            when 6 =>
                HEX2 <= not "1011111";
            when 7 =>
                HEX2 <= not "1110000";
            when 8 =>
                HEX2 <= (others => '0');
            when 9 =>
                HEX2 <= not "1111011";
            when others =>
                HEX2 <= (others => '1');
        end case ;
    end process ; -- print2
    print3 : process( seg3 )
    begin
        HEX3 <= (others => '1');
        case( seg3 ) is
            when 0 =>
                HEX3 <= not "1111110";
            when 1 =>
                HEX3 <= not "0110000";
            when 2 =>
                HEX3 <= not "1101101";
            when 3 =>
                HEX3 <= not "1111001";
            when 4 =>
                HEX3 <= not "0110011";
            when 5 =>
                HEX3 <= not "1011011";
            when 6 =>
                HEX3 <= not "1011111";
            when 7 =>
                HEX3 <= not "1110000";
            when 8 =>
                HEX3 <= (others => '0');
            when 9 =>
                HEX3 <= not "1111011";
            when others =>
                HEX3 <= (others => '1');
        end case ;
    end process ; -- print3
    print4 : process( seg4 )
    begin
        HEX4 <= (others => '1');
        case( seg4 ) is
            when 0 =>
                HEX4 <= not "1111110";
            when 1 =>
                HEX4 <= not "0110000";
            when 2 =>
                HEX4 <= not "1101101";
            when 3 =>
                HEX4 <= not "1111001";
            when 4 =>
                HEX4 <= not "0110011";
            when 5 =>
                HEX4 <= not "1011011";
            when 6 =>
                HEX4 <= not "1011111";
            when 7 =>
                HEX4 <= not "1110000";
            when 8 =>
                HEX4 <= (others => '0');
            when 9 =>
                HEX4 <= not "1111011";
            when others =>
                HEX4 <= (others => '1');
        end case ;
    end process ; -- print4
    print5 : process( seg5 )
    begin
        HEX5 <= (others => '1');
        case( seg5 ) is
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
            when others =>
                HEX5 <= (others => '1');
        end case ;
    end process ; -- print5

end architecture ; -- arch