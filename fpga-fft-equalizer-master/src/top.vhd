library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fft_utils.bit_reverse;

entity top is
	generic (
		fft_size_exp:                 integer := 4;
		bits_per_sample:              integer := 24);
	port (
		iCLK_100:                in    std_logic;    --100MHz

		-- oLEDG:                  out   std_logic_vector(8  downto 0);
		-- oLEDR:                  out   std_logic_vector(17 downto 0);

		-- iKEY:                   in    std_logic_vector(3  downto 0);
		-- iSW:                    in    std_logic_vector(17 downto 0);


		AUD_BCLK:               in    std_logic;    --Audio CODEC Bit-Stream Clock
		AUD_ADCLRCK:            in    std_logic;    --Audio CODEC ADC LR Clock
		iAUD_ADCDAT:            in    std_logic;    --Audio CODEC ADC Data               
		-- AUD_DACLRCK:            in    std_logic;    --Audio CODEC DAC LR Clock
		-- oAUD_DACDAT:            out   std_logic;    --Audio CODEC DAC DATA
		-- oAUD_XCK:               out   std_logic;    --Audio CODEC Chip Clock
		  
		I2C_SDAT:               out   std_logic;    --I2C Data
		oI2C_SCLK:              out   std_logic    --I2C Clock
);
end top;

architecture top_impl of top is
	component fdiv
	generic(N: integer:=2);
	port(
        clkin: IN std_logic;
        clkout: OUT std_logic
		);
	end component;
	constant number_of_samples:                     integer := 2**fft_size_exp;
	
	signal reset_n_signal:                          std_logic;
	signal start_signal:                            std_logic;

	
	signal left_channel_sample_from_adc_signal:     signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_from_adc_signal:    signed(bits_per_sample - 1 downto 0);
	signal sample_available_from_adc_signal:        std_logic;
	
	-- signal left_channel_sample_to_dac_signal:       signed(bits_per_sample - 1 downto 0);
	-- signal right_channel_sample_to_dac_signal:      signed(bits_per_sample - 1 downto 0); 
	-- signal sample_available_to_dac_signal:          std_logic; 

	signal equalized_frequency_sample_left_signal:  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
	signal equalized_frequency_sample_right_signal: std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);

	signal mask_signal:                             std_logic_vector(6 downto 0);
	signal bin_0_signal:                            std_logic;

	signal mask_out:                                std_logic_vector(15 downto 0);
	signal iSW_my:									std_logic_vector(17 downto 0) := (others => '0');
	signal start_delay:                             std_logic;
	signal iCLK_50:          std_logic:='0'; 

begin
	c0: fdiv generic map ( N => 2) port map(clkin=>iCLK_100, clkout=>iCLK_50);

	-- reset_n_signal <= iKEY(0);  -- reset signal should be '1' to work normally, original code
	
	
	reset_n_signal <= '1';  -- reset signal should be '1' to work normally, my change
	
	
	start_signal <= start_delay;  -- start signal should be '1' to work normally

	-- these LEDS are used for visualizing the start/reset and mask signal!
	-- oLEDG(0) <= reset_n_signal;
	-- oLEDG(7) <= start_signal;
	-- oLEDR(17 downto 10) <= iSW(17 downto 10);
	-- oLEDR(9) <= '0';
	-- oLEDR(8) <= '0';
	-- oLEDR(7 downto 0) <= iSW(7 downto 0);



	---- original code
	-- bin_0_signal <= iSW(17);
	-- mask_signal <= bit_reverse(iSW(16 downto 10));  -- mask signal is critical here, it may mute some frequecies. But it needs try to see.
	-- -- and size of mask is fixed to 7, however, the fft size is default 2**4=16, which can change!
	

	-- my code, iSW_my are all '0'
	bin_0_signal <= iSW_my(17);
	mask_signal <= bit_reverse(iSW_my(16 downto 10));  -- mask signal is critical here, it may mute some frequecies. But it needs try to see.
	-- and size of mask is fixed to 7, however, the fft size is default 2**4=16, which can change!


	process(iCLK_50)
		variable cnt: integer := 10;
		variable lim: integer := 50000000;
	begin
		if rising_edge(iCLK_50) then
			if(cnt < lim) then
				cnt := cnt + 1;
				start_delay <= '0';
			else 
				start_delay <= '1';
			end if;
		end if;
	end process;

	AUDIO_PROCESSOR: entity work.audio_processor
	generic map (
		fft_size_exp =>                     fft_size_exp,
		bits_per_sample =>                  bits_per_sample)
	port map (
		reset_n =>                          reset_n_signal,
		bclk =>                             AUD_BCLK,
		
		left_channel_sample_from_adc =>     left_channel_sample_from_adc_signal,
		right_channel_sample_from_adc =>    right_channel_sample_from_adc_signal,
		sample_available_from_adc =>        sample_available_from_adc_signal,
		
		-- left_channel_sample_to_dac =>       left_channel_sample_to_dac_signal,
		-- right_channel_sample_to_dac =>      right_channel_sample_to_dac_signal,
		-- sample_available_to_dac =>          sample_available_to_dac_signal,

		equalized_frequency_sample_left =>  equalized_frequency_sample_left_signal,
		equalized_frequency_sample_right => equalized_frequency_sample_right_signal,

		bin_0 =>                            bin_0_signal,
		mask =>                             mask_signal);

	MW8731_CONTROLLER1: entity work.mw8731_controller
	generic map (
		number_of_samples =>             number_of_samples,
		bits_per_sample =>               bits_per_sample)
	port map (
		clk_50MHz =>                     iCLK_50,
		reset_n =>                       reset_n_signal,
		
		start_operation =>               start_signal,

		left_channel_sample_from_adc =>  left_channel_sample_from_adc_signal,
		right_channel_sample_from_adc => right_channel_sample_from_adc_signal,
		sample_available_from_adc =>     sample_available_from_adc_signal,

		-- left_channel_sample_to_dac =>    left_channel_sample_to_dac_signal,
		-- right_channel_sample_to_dac =>   right_channel_sample_to_dac_signal,
		-- sample_available_to_dac =>       sample_available_to_dac_signal,

		-- mclk_18MHz =>                    oAUD_XCK,
		
		bclk =>                          AUD_BCLK,
		adclrc =>                        AUD_ADCLRCK,
		adcdat =>                        iAUD_ADCDAT,
		-- daclrc =>                        AUD_DACLRCK,
		-- dacdat =>                        oAUD_DACDAT,

		i2c_sdat =>                      I2C_SDAT,
		i2c_sclk =>                      oI2C_SCLK);

	
end top_impl;


Library ieee;
Use ieee.std_logic_1164.all;
Use ieee.std_logic_unsigned.all;
Use ieee.std_logic_arith.all;
Entity fdiv is
  generic(N: integer:=2);       --rate=N锛孨鏄伓鏁
  port(
        clkin: IN std_logic;
        clkout: OUT std_logic
        );
End fdiv;
Architecture a of fdiv is
	signal cnt: integer range 0 to n/2-1;
	signal temp: std_logic:='0';
  Begin
	process(clkin)
	begin
		if(clkin'event and clkin='1') then
			if(cnt=	N/2-1) then
				cnt <= 0;
				temp <= NOT temp;
			else
				cnt <= cnt+1;
			end if;
		end if;
	end process;
  
	clkout <=  temp;
  End a;
