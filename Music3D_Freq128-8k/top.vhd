library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is 
generic (
    fft_size_exp:                 integer := 7;
    bits_per_sample:              integer := 16);
port (
    iCLK_100:                in    std_logic;    --100MHz
    iCLK_11MHz:              in    std_logic;    --11MHz

    AUD_BCLK:               in    std_logic;    --Audio CODEC Bit-Stream Clock
    AUD_ADCLRCK:            in    std_logic;    --Audio CODEC ADC LR Clock
    iAUD_ADCDAT:            in    std_logic;    --Audio CODEC ADC Data               
    tx_out: out std_logic;
    
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
        tx_out => tx_out
    );

end top_impl;
