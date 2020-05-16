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


