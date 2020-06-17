-----------------------------------------------------------
--
-- Copyright (c) 2020, nmrenyi <ry18@mails.tsinghua.edu.cn>
--
-----------------------------------------------------------
-- top.vhd
-- create time: 2020-05-01
-- target chip: EP2C70F672C8
-- clock selection: iCLK_100 = 100MHz, iCLK_11MHz = 11MHz
-- demo info: Use AN831 module for AUD_BCLK, AUD_ADCLRCK, iAUD_ADCDAT input and I2C_SDAT, oI2C_SCLK output. 
--            Use a click button for Mode input.
--            Use LightCube for tx_out.
--
-- main signal:
--             Input:      iCLK_100    | System clock at 100 MHz
--                         iCLK_11MHz  | System clock at 11 MHz
--                         Mode        | Mode Selection
--                         AUD_BCLK    | Audio CODEC Bit-Stream Clock (frequency = 2 * Fs * bits_per_sample)
--                         AUD_ADCLRCK | Audio CODEC ADC LR Clock
--                         iAUD_ADCDAT | Audio CODEC ADC Data
--
--             Output:     tx_out      | TX line 
--                         I2C_SDAT    | I2C Data
--                         oI2C_SCLK   | I2C Clock
--       
-- main process: AN831:       : Read AN831 module output, do FFT, prepare light information for light cube.
--               mTransmitter : Pack data to RX/TX output
-- main function: Get data from audio module, do FFT, and package data to RX/TX output
-----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is 
generic (
    fft_size_exp:                 integer := 6;  -- FFT size = 2^fft_size_exp, here we use 64 point FFT
    bits_per_sample:              integer := 24);-- 24 bits per sample
port (
    iCLK_100:               in    std_logic;    --100MHz
    iCLK_11MHz:             in    std_logic;    --11MHz
	Mode:                   in    std_logic;
    AUD_BCLK:               in    std_logic;    --Audio CODEC Bit-Stream Clock
    AUD_ADCLRCK:            in    std_logic;    --Audio CODEC ADC LR Clock
    iAUD_ADCDAT:            in    std_logic;    --Audio CODEC ADC Data  

    tx_out:                 out   std_logic;
    I2C_SDAT:               out   std_logic;    --I2C Data
    oI2C_SCLK:              out   std_logic    --I2C Clock
);
end top;

architecture top_impl of top is
    signal out_page				:   std_logic_vector(63 downto 0) := (others => '0');
    signal out_page_sample_available : std_logic := '0';
begin

    AN831: entity work.AN831
    generic map(
        fft_size_exp => fft_size_exp,
        bits_per_sample => bits_per_sample
    )
    port map(
        iCLK_100 => iCLK_100,
        AUD_BCLK => AUD_BCLK,
        AUD_ADCLRCK => AUD_ADCLRCK,
        iAUD_ADCDAT => iAUD_ADCDAT,
        out_page => out_page,
        out_page_sample_available => out_page_sample_available,
        I2C_SDAT => I2C_SDAT,
        oI2C_SCLK => oI2C_SCLK
    );

    mTransmitter: entity work.mTransmitter
    port map(
        data_in => out_page,
        send_cmd => out_page_sample_available,
        iCLK_11MHz => iCLK_11MHz,
		  mode => Mode,
        tx_out => tx_out
    );

end top_impl;
