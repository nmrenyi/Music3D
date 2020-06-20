library verilog;
use verilog.vl_types.all;
entity FFT is
    port(
        input_re        : in     vl_logic_vector(63 downto 0);
        input_im        : in     vl_logic_vector(63 downto 0);
        output_re       : out    vl_logic_vector(87 downto 0);
        output_im       : out    vl_logic_vector(87 downto 0)
    );
end FFT;
