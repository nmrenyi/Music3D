-----------------------------------------------------------------------
--               UART | Transmitter unit
-----------------------------------------------------------------------
--
-- Copyright (c) 2020, pptrick <pancy17@mails.tsinghua.edu.cn>
--
-----------------------------------------------------------------------
-- Input:      clk        | System clock at 11.0592 MHz (Baud: 115200)
--             data_in    | Input data (serial 8 bits)
--             send_cmd   | Input command : Input data valid
--
-- Output:     data_out   | TX line 
--             in_valid   | '1' when transmitter accepts
----------------------------------------------------------------------
-- mTXD.vhd
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity mTXD is
    port(
        clk: in std_logic;
        send_cmd: in std_logic;
        data_in: in std_logic_vector(7 downto 0);
        data_out: out std_logic;
        in_valid: out std_logic
    );
end mTXD;

architecture mTXD_rtl of mTXD is
    type TXstat is (idle, start, send, finish); -- states of 'state machine'
    signal TX_current_stat, TX_next_stat: TXstat;
    signal data_buf: std_logic_vector(7 downto 0):= (others => '0'); -- A data buffer of input serial data(8 bits)
    signal data_counter: integer := 0; -- A recorder of current data position (0~7)
    signal ticker: integer := 0; -- Time ticker, to control output frequency
begin
    REG: process (clk) 
    begin
        if(clk='1' AND clk'event) then
            if(ticker = 95 or (TX_current_stat=idle and TX_next_stat=idle)) then -- '95' stands for clock_freq(11.0592MHz)/Baud(115200 bps)
                ticker <= 0;
                TX_current_stat <= TX_next_stat; -- Move from current state to next state
                if(TX_current_stat = send) then
                    data_counter <= data_counter+1; -- When sending data, data_counter change
                else
                    data_counter <= 0;
                end if;
            else
                ticker <= ticker + 1;
            end if;
        end if;
    end process;

    COM: process (TX_current_stat, send_cmd, data_counter)
    begin
        case TX_current_stat is
            when idle =>
                in_valid <= '1';
                data_out <= '1';
                if (send_cmd = '1') then
                    TX_next_stat <= start;
                else
                    TX_next_stat <= idle;
                end if;
            when start =>
                in_valid <= '0';
                data_out <= '0';
                data_buf <= data_in;
                TX_next_stat <= send;
            when send =>
                in_valid <= '0';
                data_out <= data_buf(data_counter);
                if(data_counter = 7) then
                    TX_next_stat <= finish;
                else
                    TX_next_stat <= send;
                end if;
            when finish =>
                in_valid <= '0';
                data_out <= '1';
                TX_next_stat <= idle;
            when others =>
                in_valid <= '0';
                data_out <= '1';
                TX_next_stat <= idle;
        end case;
    end process;
end architecture mTXD_rtl; 