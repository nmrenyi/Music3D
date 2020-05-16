------------------------------------
-- This is a test file, to check if
-- the transmitter can work.
------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.trans_pkg.all;

entity top is
    port(
        clk: in std_logic;
        btn: in std_logic;
        tx: out std_logic
        --sd: out std_logic;
        --dt: out std_logic_vector(7 downto 0);
        --rcv: out std_logic;
        --sd_v: out std_logic
    );
end top;

architecture top_beh of top is
    component mTransmitter
        port(
            data_in: in std_logic_vector(63 downto 0);
            send_cmd: in std_logic;
            iCLK_11MHz: in std_logic;
            tx_out: out std_logic
            --test: out std_logic;
            --dt: out std_logic_vector(7 downto 0);
            --rcv: out std_logic;
            --sd_v: out std_logic
        );
    end component;
    signal data: std_logic_vector(63 downto 0) := (others => '0') ;
    signal bt: std_logic;
    begin
        bt <= not btn;
        Tr: mTransmitter port map (
            data_in => data, send_cmd => bt, iCLK_11MHz => clk, tx_out => tx --test => sd, dt => dt, rcv => rcv, sd_v => sd_v
        );
        process (btn)
        begin
            if(btn='1' and btn'event) then
                data <= data + 1;
            end if;
        end process;
    end architecture top_beh;