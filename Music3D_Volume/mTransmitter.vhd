-----------------------------------------------------------
--
-- Copyright (c) 2020, pptrick <pancy17@mails.tsinghua.edu.cn>
--
-----------------------------------------------------------
-- Input:      iCLK_11MHz | System clock at 11.0592 MHz (Baud: 115200)
--             data_in    | Input data (serial 64 bits)
--             send_cmd   | Input command : Input data valid
--
-- Output:     tx_out     | TX line 
-----------------------------------------------------------
-- mTransmitter.vhd
-- Get data from audio module and packaged them to RX/TX output
-----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.trans_pkg.all; -- define 'cube_vector'

entity mTransmitter is
    port(
        data_in: in std_logic_vector(63 downto 0);
        send_cmd: in std_logic;
        iCLK_11MHz: in std_logic;
        tx_out: out std_logic
    );
end mTransmitter;

architecture recv_beh of mTransmitter is
    component mTXD
        port (
            clk: in std_logic;
            send_cmd: in std_logic;
            data_in: in std_logic_vector(7 downto 0);
            data_out: out std_logic;
            in_valid: out std_logic
        );
    end component;
    type state is (idle, start, send, finish);
    subtype data_count is integer range 0 to 7;
    signal current_state, next_state : state;
    signal x_counter: data_count := 0;
    signal y_counter: data_count := 0;
    signal data_buff: cube_vector:= (others => (others => '0'));
    signal send_available: std_logic:= '0';  -- syc with send_cmd
    signal send_serial: std_logic:= '0'; -- '1' when in start/send state
    signal recv_serial: std_logic:= '0'; -- syc with mTXD's in_valid
    signal send_valid: std_logic:= '0'; -- valid output time after changing state
    signal send_total: std_logic:='0'; -- decide whether data can be send to mTXD
    signal ticker: integer := 0;
    signal data_out: std_logic_vector(7 downto 0) := (others => '0');
begin
    send_total <= send_serial and send_valid and recv_serial;
    send_available <= send_cmd;
    txd: mTXD port map (
        clk => iCLK_11MHz, send_cmd => send_total, data_in => data_out, data_out => tx_out, in_valid=>recv_serial
    );
    process (send_cmd)
    begin
        if(rising_edge(send_cmd)) then
            data_buff <= data_buff(6 downto 0) & data_in; 
        end if;
    end process;

    REG: process (iCLK_11MHz)
    begin
        if(rising_edge(iCLK_11MHz)) then
            if(ticker = 2000 or (current_state=idle and next_state=idle)) then
                ticker <= 0;
                send_valid <= '1';
                current_state <= next_state;
                if(current_state = send) then
                    if(x_counter = 7) then
                        x_counter <= 0;
                        y_counter <= y_counter + 1;
                    else
                        x_counter <= x_counter + 1;
                    end if;
                else
                    x_counter <= 0;
                    y_counter <= 0;
                end if;
            elsif (ticker = 200) then
                send_valid <= '0';
                ticker <= ticker + 1;
            else
                ticker <= ticker + 1;
            end if;
        end if;
    end process;

    COM: process (current_state, recv_serial, send_available, x_counter, y_counter)
    begin
        case current_state is
            when idle =>
                data_out <= (others => '0');
                send_serial <= '0';
                if(send_available = '1') then
                    next_state <= start;
                else
                    next_state <= idle;
                end if;
            when start =>
                data_out <= "11110010"; --F2
                send_serial <= '1';
                next_state <= send;
            when send =>
                data_out <= data_buff(y_counter)(7 downto 0); -- (x_counter+1)*8-1 downto x_counter*8
                send_serial <= '1';
                if((y_counter = 7)and(x_counter = 7)) then -- all 64 bits complete
                    next_state <= finish;
                else
                    next_state <= send;
                end if;
            when finish =>
                send_serial <= '0';
                next_state <= idle;
            when others =>
                send_serial <= '0';
                next_state <= idle;
        end case;
    end process;
end architecture recv_beh;