-----------------------------------------------------------
--
-- Copyright (c) 2020, nmrenyi <ry18@mails.tsinghua.edu.cn>
-- Referenced to https://github.com/Ugon/fpga-fft-equalizer
-----------------------------------------------------------
-- i2c_clk_prescaler.vhd
-- create time: 2020-05-01
-- target chip: EP2C70F672C8
-- clock selection: clk_50MHz = 50MHz
-- main signal:
--             Input:      clk_50MHz   | System clock at 50 MHz
--
--             Output:     clk_100kHz  		| 100kHz clock
-- main function: Convert 50MHz clock to 100kHz clock.
-----------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;

entity i2c_clk_prescaler is
	port (
		clk_50Mhz:  in  std_logic;
		clk_100kHz: out std_logic);
end i2c_clk_prescaler;

architecture i2c_clk_prescaler_impl of i2c_clk_prescaler is
	constant switch_threshold: integer := 250;
	signal   clk_100kHz_int:   std_logic;
begin
	clk_100kHz <= clk_100kHz_int;

	process (clk_50Mhz)
		variable count: integer := 0;
	begin
		if(rising_edge(clk_50Mhz)) then
			if(count < switch_threshold) then
				count := count + 1;
			else 
				count := 0;
				clk_100kHz_int <= not clk_100kHz_int;
			end if;
		end if;
	end process;
	
end i2c_clk_prescaler_impl;