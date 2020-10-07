library verilog;
use verilog.vl_types.all;
entity F_CODE is
    port(
        INX             : in     vl_logic_vector(3 downto 0);
        DISPLAY_NUM     : out    vl_logic_vector(15 downto 0);
        \TO\            : out    vl_logic_vector(10 downto 0)
    );
end F_CODE;
