library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fft_utils.bit_reverse;

entity AN831 is
	generic (
		fft_size_exp:                 integer := 4;
		bits_per_sample:              integer := 24);
	port (
		iCLK_100:                in    std_logic;    --100MHz

		AUD_BCLK:               in    std_logic;    --Audio CODEC Bit-Stream Clock
		AUD_ADCLRCK:            in    std_logic;    --Audio CODEC ADC LR Clock
		iAUD_ADCDAT:            in    std_logic;    --Audio CODEC ADC Data               
		
		out_page:				out   std_logic_vector(63 downto 0) := (others => '0');
		out_page_sample_available: out std_logic := '0';
		
		I2C_SDAT:               out   std_logic;    --I2C Data
		oI2C_SCLK:              out   std_logic    --I2C Clock
);
end AN831;

architecture AN831_impl of AN831 is
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
	constant number_of_samples:                     integer := 2**fft_size_exp;
	
	signal reset_n_signal:                          std_logic;
	signal start_signal:                            std_logic;
	signal tmp_left_channel_sample_from_adc_signal:     signed(bits_per_sample - 1 downto 0);
	signal tmp_right_channel_sample_from_adc_signal:    signed(bits_per_sample - 1 downto 0);

	
	signal left_channel_sample_from_adc_signal:     signed(bits_per_sample - 1 downto 0);
	signal right_channel_sample_from_adc_signal:    signed(bits_per_sample - 1 downto 0);
	signal sample_available_from_adc_signal:        std_logic;
	
	signal equalized_frequency_sample_left_signal:  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
	signal equalized_frequency_sample_right_signal: std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);


	signal tmp_equalized_frequency_sample_left_signal:  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
	signal tmp_equalized_frequency_sample_right_signal: std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);

	signal mask_signal:                             std_logic_vector(2**(fft_size_exp - 1) - 2 downto 0) := (others => '1');
	signal bin_0_signal:                            std_logic := '1';

	signal mask_out:                                std_logic_vector(15 downto 0);
	signal iSW_my:									std_logic_vector(17 downto 0) := (others => '0');
	signal start_delay:                             std_logic;
	signal iCLK_50:          std_logic:='0'; 
	signal level: std_logic_vector(7 downto 0) := (others => '0');
	signal out_page_tmp: std_logic_vector(63 downto 0) := (others => '0');
	

	type fsm is(idle, counting, available);
    signal state: fsm:=idle;
	constant counting_limit : integer := 10000000 - 1;
	constant hold_limit : integer := 5000000 + 1;
	
	signal count_value : integer := counting_limit;
	
begin
    c0:mypll port map(
        inclk0 => iCLK_100,
        c0 => iCLK_50
    );
	c1: compress 
	generic map(bits_per_sample => bits_per_sample)
	port map(in_value => std_logic_vector(tmp_left_channel_sample_from_adc_signal), out_value => level);

	c2: send port map(
		in7 => level,
		in6 => level,
		in5 => level,
		in4 => level,
		in3 => level,
		in2 => level,
		in1 => level,
		in0 => level,
		out_page => out_page_tmp
	);
	
	reset_n_signal <= '1';  -- reset signal should be '1' to work normally, my change
	start_signal <= start_delay;  -- start signal should be '1' to work normally

	-- send signal every 0.1s
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
-- signal tmp: std_logic_vector(3 downto 0) := 0;
	signal mid: std_logic_vector(11 downto 0) := (others => '0');
	begin
		mid <= in_value(bits_per_sample - 1 - 4 downto bits_per_sample - 16);
		process(in_value) begin
			if (CONV_INTEGER(mid) > 750) then
			out_value <= "10000000";
			--   tmp <= "1000";
			elsif (CONV_INTEGER(mid)>300) then
			out_value <= "01000000";
			--   tmp <= "0111";
			elsif (CONV_INTEGER(mid)>120) then
			out_value <= "00100000";
			--   tmp <= "0110";
			elsif (CONV_INTEGER(mid)>60) then
			out_value <= "00010000";
			--   tmp <= "0101";
			elsif (CONV_INTEGER(mid)>30) then
			out_value <= "00001000";
			--   tmp <= "0100";
			elsif (CONV_INTEGER(mid)>16) then
			out_value <= "00000100";
			--   tmp <= "0011";
			elsif (CONV_INTEGER(mid)>8) then
			out_value <= "00000010";
			--   tmp <= "0010";
			elsif (CONV_INTEGER(mid)>4) then
			out_value <= "00000001";
			--   tmp <= "0001";
			else
			out_value <= "00000000";
			--   tmp <= "0000";
			end if;
		end process;
end compress_impl;


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
