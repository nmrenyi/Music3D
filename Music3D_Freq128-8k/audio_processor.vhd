library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fft_utils.all;

entity audio_processor is
	generic (
		fft_size_exp:                          integer := 3;
		bits_per_sample:                       integer := 24);
	port (	
		reset_n:                          in   std_logic;
		bclk:                             in   std_logic;

		left_channel_sample_from_adc:     in   signed(bits_per_sample - 1 downto 0) := (others => '0');
		right_channel_sample_from_adc:    in   signed(bits_per_sample - 1 downto 0) := (others => '0');
		sample_available_from_adc:        in   std_logic                            := '0';
		
		equalized_frequency_sample_left:  out  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
		equalized_frequency_sample_right: out  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
		
		tmp_equalized_frequency_sample_left:  out  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);
		tmp_equalized_frequency_sample_right: out  std_logic_vector(2**fft_size_exp * bits_per_sample - 1 downto 0);

		bin_0:                            in   std_logic;
		mask:                             in   std_logic_vector(2**(fft_size_exp - 1) - 2 downto 0));
end audio_processor;

architecture audio_processor_impl of audio_processor is
	constant fft_size:                       integer := 2**fft_size_exp;

	signal new_vector_signal:                std_logic;

	signal pre_fft_left_re_natural:          std_logic_vector(fft_size * bits_per_sample - 1 downto 0);
	signal pre_fft_right_re_natural:         std_logic_vector(fft_size * bits_per_sample - 1 downto 0);
	
	signal post_fft_left_re_natural:         std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal post_fft_left_im_natural:         std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal post_fft_right_re_natural:        std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal post_fft_right_im_natural:        std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);

	signal post_fft_left_re_natural_masked:  std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);
	signal post_fft_right_re_natural_masked: std_logic_vector(fft_size * (bits_per_sample + fft_size_exp) - 1 downto 0);

	signal post_ifft_left_re_natural:        std_logic_vector(fft_size * bits_per_sample - 1 downto 0);
	signal post_ifft_right_re_natural:       std_logic_vector(fft_size * bits_per_sample - 1 downto 0);

	signal mask_int:                         std_logic_vector(fft_size - 1 downto 0);
	component mask_freq
		generic (
			vector_length : integer;
			samples : integer
		);
		port(
			in_sig: in std_logic_vector(vector_length * samples - 1 downto 0);
			out_sig: out std_logic_vector(vector_length * samples - 1 downto 0)
		);
	end component;
begin	
--	mask_int(2** fft_size_exp      - 1 downto 2**(fft_size_exp - 1) + 1) <= bit_reverse(mask);
--	mask_int(2**(fft_size_exp - 1)                                     ) <= '1';
--	mask_int(2**(fft_size_exp - 1) - 1 downto 1                        ) <= mask;
--	mask_int(0                                                         ) <= bin_0;

	equalized_frequency_sample_left  <= divide_and_resize_all(post_fft_left_re_natural_masked, 2**fft_size_exp, bits_per_sample + fft_size_exp, 2**(fft_size_exp - 1), bits_per_sample);
	equalized_frequency_sample_right <= divide_and_resize_all(post_fft_right_re_natural_masked, 2**fft_size_exp, bits_per_sample + fft_size_exp, 2**(fft_size_exp - 1), bits_per_sample);

	uut1: mask_freq generic map(vector_length => bits_per_sample, samples => fft_size) port map(in_sig => divide_and_resize_all(post_fft_left_re_natural_masked, 2**fft_size_exp, bits_per_sample + fft_size_exp, 2**(fft_size_exp - 1), bits_per_sample), out_sig => tmp_equalized_frequency_sample_left);
	uut2: mask_freq generic map(vector_length => bits_per_sample, samples => fft_size) port map(in_sig => divide_and_resize_all(post_fft_right_re_natural_masked, 2**fft_size_exp, bits_per_sample + fft_size_exp, 2**(fft_size_exp - 1), bits_per_sample), out_sig => tmp_equalized_frequency_sample_right);



--	process(post_fft_left_re_natural, post_fft_right_re_natural, mask_int)
--		variable many_bits: std_logic_vector((bits_per_sample + fft_size_exp) - 1 downto 0);
--	begin
--		for i in fft_size downto 1 loop
--			many_bits := (others => mask_int(i - 1));
--			post_fft_left_re_natural_masked (i * (bits_per_sample + fft_size_exp) - 1 downto (i - 1) * (bits_per_sample + fft_size_exp)) <= 
--				  post_fft_left_re_natural  (i * (bits_per_sample + fft_size_exp) - 1 downto (i - 1) * (bits_per_sample + fft_size_exp)) and many_bits;
--			post_fft_right_re_natural_masked(i * (bits_per_sample + fft_size_exp) - 1 downto (i - 1) * (bits_per_sample + fft_size_exp)) <= 
--				  post_fft_right_re_natural (i * (bits_per_sample + fft_size_exp) - 1 downto (i - 1) * (bits_per_sample + fft_size_exp)) and many_bits;
--		end loop;
--	end process;
	
	---unmasked
	process(post_fft_left_re_natural, post_fft_right_re_natural)
		variable many_bits: std_logic_vector((bits_per_sample + fft_size_exp) - 1 downto 0);
	begin
		for i in fft_size downto 1 loop
			many_bits := (others => mask_int(i - 1));
			post_fft_left_re_natural_masked (i * (bits_per_sample + fft_size_exp) - 1 downto (i - 1) * (bits_per_sample + fft_size_exp)) <= 
				  post_fft_left_re_natural  (i * (bits_per_sample + fft_size_exp) - 1 downto (i - 1) * (bits_per_sample + fft_size_exp));
			post_fft_right_re_natural_masked(i * (bits_per_sample + fft_size_exp) - 1 downto (i - 1) * (bits_per_sample + fft_size_exp)) <= 
				  post_fft_right_re_natural (i * (bits_per_sample + fft_size_exp) - 1 downto (i - 1) * (bits_per_sample + fft_size_exp));
		end loop;
	end process;
	FFT_INPUT_FORMER1: entity work.fft_input_deserializer
	generic map (
		number_of_samples => fft_size,
		bits_per_sample => bits_per_sample)
	port map (
		reset_n => reset_n,
		bclk => bclk,
		
		sample_available_from_adc => sample_available_from_adc,
		left_channel_sample_from_adc => left_channel_sample_from_adc,
		right_channel_sample_from_adc => right_channel_sample_from_adc,
		
		vector_left => pre_fft_left_re_natural,
		vector_right => pre_fft_right_re_natural,
		new_vector => new_vector_signal);

	FFT_LEFT: entity work.fft_dif
	generic map (
		fft_size_exp => fft_size_exp,
		bits_per_sample => bits_per_sample,
		output_natural_order => true)
	port map (
		input_re => pre_fft_left_re_natural,
		input_im => (others => '0'),
		
		output_re => post_fft_left_re_natural,
		output_im => post_fft_left_im_natural);

	FFT_RIGHT: entity work.fft_dif
	generic map (
		fft_size_exp => fft_size_exp,
		bits_per_sample => bits_per_sample,
		output_natural_order => true)
	port map (
		input_re => pre_fft_right_re_natural,
		input_im => (others => '0'),
		
		output_re => post_fft_right_re_natural,
		output_im => post_fft_right_im_natural);

end audio_processor_impl;



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity mask_freq is 
    generic(
        vector_length: integer := 4;
		  samples: integer := 4
    );
    port(
        in_sig: in std_logic_vector(vector_length * samples - 1 downto 0) := (others => '0');
        out_sig: out std_logic_vector(vector_length * samples - 1 downto 0) := (others => '0')
    );
end mask_freq;
architecture mask_freq_impl of mask_freq is 
    begin
        process(in_sig) begin
			for i in 0 to (samples - 1) loop
				if in_sig((i + 1) * vector_length - 1) = '1' then
					out_sig((i + 1) * vector_length - 1 downto i * vector_length) <= not(in_sig((i + 1) * vector_length - 1 downto i * vector_length));
				else
					out_sig((i + 1) * vector_length - 1 downto i * vector_length) <= in_sig((i + 1) * vector_length - 1 downto i * vector_length);
				end if;
			end loop;
			
			end process;
end mask_freq_impl;


