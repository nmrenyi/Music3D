-----------------------------------------------------------
--
-- Copyright (c) 2020, nmrenyi <ry18@mails.tsinghua.edu.cn>
--
-----------------------------------------------------------
-- AN831.vhd
-- create time: 2020-05-01
-- target chip: EP2C70F672C8
-- clock selection: iCLK_100 = 100MHz
-- main signal:
--             Input:      iCLK_100    | System clock at 100 MHz
--                         AUD_BCLK    | Audio CODEC Bit-Stream Clock
--                         AUD_ADCLRCK | Audio CODEC ADC LR Clock
--                         iAUD_ADCDAT | Audio CODEC ADC Data
--
--             Output:     outpage     				 | Light information in one frame
--						   out_page_sample_available | Light information available signal
--                         I2C_SDAT    				 | I2C Data
--                         oI2C_SCLK   			     | I2C Clock
--       
-- main process: AUDIO_PROCESSOR    : do FFT
--               MW8731_CONTROLLER1 : Read AN831 audio output, config WM8731 registers
-- main function: Read AN831 module output, do FFT, prepare light information for light cube.
-----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fft_utils.bit_reverse;

entity AN831 is
	generic (
		fft_size_exp:                 integer := 4;
		bits_per_sample:              integer := 24);
	port (
		iCLK_100:                in    std_logic;    --100MHz clock

		AUD_BCLK:               in    std_logic;    --Audio CODEC Bit-Stream Clock
		AUD_ADCLRCK:            in    std_logic;    --Audio CODEC ADC LR Clock
		iAUD_ADCDAT:            in    std_logic;    --Audio CODEC ADC Data               
		
		out_page:				out   std_logic_vector(63 downto 0) := (others => '0');    --light information for a single frame
		out_page_sample_available: out std_logic := '0';    --light information available signal
		
		I2C_SDAT:               out   std_logic;    --I2C Data
		oI2C_SCLK:              out   std_logic    --I2C Clock
);
end AN831;

architecture AN831_impl of AN831 is

	-- component declarations
    component mypll IS
        PORT
        (
            areset		: IN STD_LOGIC  := '0';
            inclk0		: IN STD_LOGIC  := '0';
            c0		: OUT STD_LOGIC :='0' ;
            locked		: OUT STD_LOGIC 
        );
		END component;
	component compress
	generic(bits_per_sample:integer);
	port(
        in_value : in std_logic_vector(bits_per_sample - 1 downto 0):= (others => '0');
        out_value: out std_logic_vector(7 downto 0) := (others => '0')
		);
	end component;
	component send
	port(
		in7: in std_logic_vector(7 downto 0) := (others => '0');
		in6: in std_logic_vector(7 downto 0) := (others => '0');
		in5: in std_logic_vector(7 downto 0) := (others => '0');
		in4: in std_logic_vector(7 downto 0) := (others => '0');
		in3: in std_logic_vector(7 downto 0) := (others => '0');
		in2: in std_logic_vector(7 downto 0) := (others => '0');
		in1: in std_logic_vector(7 downto 0) := (others => '0');
		in0: in std_logic_vector(7 downto 0) := (others => '0');
		out_page: out std_logic_vector(63 downto 0) := (others => '0')
	);
	end component;

	-- other signal declarations
	constant number_of_samples:                     integer := 2**fft_size_exp;
	signal reset_n_signal:                          std_logic;
	signal start_signal:                            std_logic;

	-- original code for ADC signal
	signal tmp_left_channel_sample_from_adc_signal:     signed(bits_per_sample - 1 downto 0);
	signal tmp_right_channel_sample_from_adc_signal:    signed(bits_per_sample - 1 downto 0);
	
	-- two's complement code for ADC signal
	signal left_channel_sample_from_adc_signal:     signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_from_adc_signal:    signed(bits_per_sample - 1 downto 0);
	signal sample_available_from_adc_signal:        std_logic;
	
	-- two's complement code for FFT
	signal equalized_frequency_sample_left_signal:  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
	signal equalized_frequency_sample_right_signal: std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
	
	-- original code for FFT
	signal tmp_equalized_frequency_sample_left_signal:  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
	signal tmp_equalized_frequency_sample_right_signal: std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);

	-- mask signals, which we do not use in final version
	signal mask_signal:                             std_logic_vector(2**(fft_size_exp - 1) - 2 downto 0) := (others => '1');
	signal bin_0_signal:                            std_logic := '1';
	signal mask_out:                                std_logic_vector(15 downto 0);
	signal iSW_my:									std_logic_vector(17 downto 0) := (others => '0');
	signal start_delay:                             std_logic;
	
	-- 50MHz clock
	signal iCLK_50:          std_logic:='0'; 
	
	-- record of light signal per frame
	signal out_page_tmp: std_logic_vector(63 downto 0) := (others => '0');

	-- 8 frequency information for light cube
	signal f1: std_logic_vector(7 downto 0) := (others => '0');
	signal f2: std_logic_vector(7 downto 0) := (others => '0');
	signal f3: std_logic_vector(7 downto 0) := (others => '0');
	signal f4: std_logic_vector(7 downto 0) := (others => '0');
	signal f5: std_logic_vector(7 downto 0) := (others => '0');
	signal f6: std_logic_vector(7 downto 0) := (others => '0');
	signal f7: std_logic_vector(7 downto 0) := (others => '0');
	signal f8: std_logic_vector(7 downto 0) := (others => '0');
	
	-- Finite State Machine for sending
	type fsm is(idle, counting, available);
	signal state: fsm:=idle;
	
	-- send outpage every 0.1s, duty cycle = 50
	constant counting_limit : integer := 10000000 - 1;
	constant hold_limit : integer := 5000000 + 1;
	signal count_value : integer := counting_limit;
	
begin

	-- use PLL for clock division, from 100MHz to 50MHz
    c0:mypll port map(
        inclk0 => iCLK_100,
        c0 => iCLK_50
	);
	
	-- temp code for volume version of light cube
	-- c1: compress 
	-- generic map(bits_per_sample => bits_per_sample)
	-- port map(in_value => std_logic_vector(tmp_left_channel_sample_from_adc_signal), out_value => level);


	-- freq1 to freq8 aim to extract 8 different frequency signals into f1 to f8
	freq1: compress 
	generic map(bits_per_sample => bits_per_sample)
	port map(
		in_value => tmp_equalized_frequency_sample_left_signal(2**fft_size_exp * bits_per_sample - 1 downto 2**fft_size_exp * bits_per_sample - 24), 
		out_value => f1
	);

	freq2: compress 
	generic map(bits_per_sample => bits_per_sample)
	port map(
		in_value => tmp_equalized_frequency_sample_left_signal(2**fft_size_exp * bits_per_sample - 24 - 1 downto 2**fft_size_exp * bits_per_sample - 48), 
		out_value => f2
	);
	freq3: compress 
	generic map(bits_per_sample => bits_per_sample)
	port map(
		in_value => tmp_equalized_frequency_sample_left_signal(2**fft_size_exp * bits_per_sample - 48 - 1 downto 2**fft_size_exp * bits_per_sample - 72), 
		out_value => f3
	);
	freq4: compress 
	generic map(bits_per_sample => bits_per_sample)
	port map(
		in_value => tmp_equalized_frequency_sample_left_signal(2**fft_size_exp * bits_per_sample - 72 - 1 downto 2**fft_size_exp * bits_per_sample - 96), 
		out_value => f4
	);
	freq5: compress 
	generic map(bits_per_sample => bits_per_sample)
	port map(
		in_value => tmp_equalized_frequency_sample_left_signal(2**fft_size_exp * bits_per_sample - 96 - 1 downto 2**fft_size_exp * bits_per_sample - 120), 
		out_value => f5
	);
	freq6: compress 
	generic map(bits_per_sample => bits_per_sample)
	port map(
		in_value => tmp_equalized_frequency_sample_left_signal(2**fft_size_exp * bits_per_sample - 120 - 1 downto 2**fft_size_exp * bits_per_sample - 144), 
		out_value => f6
	);
	freq7: compress 
	generic map(bits_per_sample => bits_per_sample)
	port map(
		in_value => tmp_equalized_frequency_sample_left_signal(2**fft_size_exp * bits_per_sample - 144 - 1 downto 2**fft_size_exp * bits_per_sample - 168), 
		out_value => f7
	);
	freq8: compress 
	generic map(bits_per_sample => bits_per_sample)
	port map(
		in_value => tmp_equalized_frequency_sample_left_signal(2**fft_size_exp * bits_per_sample - 168 - 1 downto 2**fft_size_exp * bits_per_sample - 192), 
		out_value => f8
	);
	
	-- convert f1-f8 to a single signal, out_page_tmp
	c2: send port map(
		in7 => f8,
		in6 => f7,
		in5 => f6,
		in4 => f5,
		in3 => f4,
		in2 => f3,
		in1 => f2,
		in0 => f1,
		out_page => out_page_tmp
	);
	

	reset_n_signal <= '1';  -- reset signal should be '1' to work normally
	start_signal <= start_delay;  -- start signal should be '1' to work normally

	-- send signal every 0.1s, duty cycle = 50
    process(iCLK_100) begin
        if (rising_edge(iCLK_100)) then
            case state is
                when idle => 
                    count_value <= counting_limit;
                    state <= counting;
                    out_page_sample_available <= '0';
                when counting =>
                    if (count_value < hold_limit) then
                        out_page_sample_available <= '0';
                    end if;
                    if (count_value > 1) then
                        count_value <= count_value - 1;
                    else
                        out_page <= out_page_tmp;
                        state <= available;
                    end if;
                when available =>
                    out_page_sample_available <= '1';
                    count_value <= counting_limit;
                    state <= counting;
            end case;
        end if;
	end process;
	
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

	-- Audio process module for FFT
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
		
		equalized_frequency_sample_left =>  equalized_frequency_sample_left_signal,
		equalized_frequency_sample_right => equalized_frequency_sample_right_signal,

		tmp_equalized_frequency_sample_left =>  tmp_equalized_frequency_sample_left_signal,
		tmp_equalized_frequency_sample_right => tmp_equalized_frequency_sample_right_signal,

		bin_0 =>                            bin_0_signal,
		mask =>                             mask_signal);

	-- WM8731 control module, for reading ADC signal and configure WM8731
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
		
		tmp_left_channel_sample_from_adc => tmp_left_channel_sample_from_adc_signal,
		tmp_right_channel_sample_from_adc=> tmp_right_channel_sample_from_adc_signal,
		
		bclk =>                          AUD_BCLK,
		adclrc =>                        AUD_ADCLRCK,
		adcdat =>                        iAUD_ADCDAT,

		i2c_sdat =>                      I2C_SDAT,
		i2c_sclk =>                      oI2C_SCLK);

	
end AN831_impl;

-- extract frequency information into different levels for light cube
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
entity compress is
	generic (
		bits_per_sample:              integer := 24);
	port(
		in_value : in std_logic_vector(bits_per_sample - 1 downto 0):= (others => '0');
		out_value: out std_logic_vector(7 downto 0) := (others => '0')
	);
end compress;
architecture compress_impl of compress is 
	signal mid: std_logic_vector(11 downto 0) := (others => '0');
	begin
		mid <= in_value(bits_per_sample - 1 - 4 downto bits_per_sample - 16);
		process(in_value) begin
			if (CONV_INTEGER(mid) > 750) then
				out_value <= "11111111";    -- light up all 8 lights in one bar
			elsif (CONV_INTEGER(mid)>300) then
				out_value <= "01111111";
			elsif (CONV_INTEGER(mid)>120) then
				out_value <= "00111111";
			elsif (CONV_INTEGER(mid)>60) then
				out_value <= "00011111";
			elsif (CONV_INTEGER(mid)>30) then
				out_value <= "00001111";
			elsif (CONV_INTEGER(mid)>16) then
				out_value <= "00000111";
			elsif (CONV_INTEGER(mid)>8) then
				out_value <= "00000011";
			elsif (CONV_INTEGER(mid)>4) then
				out_value <= "00000001";    -- light up the lowest light in one bar
			else
				out_value <= "00000000";	-- no light in this bar
			end if;
		end process;
end compress_impl;

-- convert 8 different frequency signals into a big vector
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
entity send is 
	port(
		in7: in std_logic_vector(7 downto 0) := (others => '0');
		in6: in std_logic_vector(7 downto 0) := (others => '0');
		in5: in std_logic_vector(7 downto 0) := (others => '0');
		in4: in std_logic_vector(7 downto 0) := (others => '0');
		in3: in std_logic_vector(7 downto 0) := (others => '0');
		in2: in std_logic_vector(7 downto 0) := (others => '0');
		in1: in std_logic_vector(7 downto 0) := (others => '0');
		in0: in std_logic_vector(7 downto 0) := (others => '0');
		out_page: out std_logic_vector(63 downto 0) := (others => '0')
	);
end send;

-- convert 8 signals to 1 signal.
architecture send_impl of send is 
signal tmp: std_logic_vector(63 downto 0) := (others => '0');
	begin
	out_page <= tmp;
	tmp(64 - 1 downto 56) <= in7;
	tmp(56 - 1 downto 48) <= in6;
	tmp(48 - 1 downto 40) <= in5;
	tmp(40 - 1 downto 32) <= in4;
	tmp(32 - 1 downto 24) <= in3;
	tmp(24 - 1 downto 16) <= in2;
	tmp(16 - 1 downto 8) <= in1;
	tmp(8 - 1 downto 0) <= in0;
end send_impl;
