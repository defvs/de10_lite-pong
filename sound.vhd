-- DE10-LITE_Pong : Projet de Daniel Thirion, DUT GEII SALON DE PROVENCE, 2019
library ieee ;
	use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    
-- Cette entitée à pour but de jouer un son pendant 'duration' millisecondes
-- Ce son est un signal carré en sortie 'output', et on peut régler la fréquence par 'frequency'
-- Au front montant de 'play', les informations de durées sont enregistrées et le son est joué.
-- La fréquence peut toujours être modifiée pendant le son, mais pas sa durée. Il faut pour cela
-- redonner un coup d'horloge 'play'.
--
-- Signaux :
--  * clk50M - Horloge 50MHz de la carte
--  * frequency - Fréquence du son voulu (0 - 20KHz)
--  * duration : durée en millisecondes (0 - 10000ms = 0 - 10sec)
--  * play : Lance la lecture au FRONT MONTANT
--  * output : sortie du signal carré, à mapper.

entity sound is
  port (
    clk50M : in std_logic;
    frequency : in integer range 0 to 20000;
    duration : in integer range 0 to 10000;
    play : in std_logic;
    output : out std_logic
  ) ;
end sound ;

architecture arch of soundLib is
    signal startTime : integer range 0 to 10000000;
    signal endTime : integer range 0 to 10000000;

    signal freqTimer : integer range 0 to 25000000;

    signal millis : integer range 0 to 10000000;
    signal millisCounter : integer range 0 to 25000;
begin
    millisDivider : process( clk50M ) -- Diviseur permettant de compter les millisecondes
    begin
        if rising_edge(clk50M) then
            if millisCounter = 25000 then
                millisCounter <= 0;
                millis <= millis + 1;
            else
                millisCounter <= millisCounter + 1;
            end if ;
        end if ;
    end process ; -- millisDivider

    player : process( play ) -- Au front montant de play, on joue le son
    begin
        if rising_edge(play) then
            startTime <= millis; -- et on enregistre les informations temporelles
            endTime <= millis + duration; -- et le temps de fin
        end if ;
    end process ; -- player

    timerDiv : process( clk50M ) -- Diviseur pour la fréquence du son voulu
    begin
        if rising_edge(clk50M) then
            if freqTimer = 25000000 / frequency then
                if millis >= startTime and millis <= endTime then -- Seulement si on veut jouer la note
                    output <= not output;
                end if ;
                freqTimer <= 0;
            else
                freqTimer <= freqTimer + 1;
            end if ;
        end if ;
    end process ; -- timerDiv

end architecture ; -- arch