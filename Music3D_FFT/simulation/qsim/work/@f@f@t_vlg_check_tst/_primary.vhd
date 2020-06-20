library verilog;
use verilog.vl_types.all;
entity FFT_vlg_check_tst is
    port(
        output_im       : in     vl_logic_vector(87 downto 0);
        output_re       : in     vl_logic_vector(87 downto 0);
        sampler_rx      : in     vl_logic
    );
end FFT_vlg_check_tst;
