-- This is an UART test file

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity mUART is
    port(
        clk: in std_logic;
        send_button: in std_logic;
        tx: out std_logic
    );
end mUART;

architecture mUART_beh of mUART is
    component mTXD
        port (
            clk: in std_logic;
            send_cmd: in std_logic;
            data_in: in std_logic_vector(7 downto 0);
            data_out: out std_logic;
            in_valid: out std_logic
        );
    end component;
    signal data_send: std_logic_vector(7 downto 0);
    signal avail: std_logic;
    signal send: std_logic;
begin
    data_send <= "00001000"; --change this signal to make different output
    send <= avail and (not send_button);
    txd: mTXD port map (
        clk => clk, send_cmd => send, data_in => data_send, data_out => tx, in_valid=>avail
    );
end architecture mUART_beh;