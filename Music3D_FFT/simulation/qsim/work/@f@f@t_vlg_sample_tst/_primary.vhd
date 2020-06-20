library verilog;
use verilog.vl_types.all;
entity FFT_vlg_sample_tst is
    port(
        input_im        : in     vl_logic_vector(63 downto 0);
        input_re        : in     vl_logic_vector(63 downto 0);
        sampler_tx      : out    vl_logic
    );
end FFT_vlg_sample_tst;
