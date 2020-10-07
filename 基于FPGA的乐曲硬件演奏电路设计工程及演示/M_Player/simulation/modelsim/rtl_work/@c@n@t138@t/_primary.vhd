library verilog;
use verilog.vl_types.all;
entity CNT138T is
    port(
        CLK             : in     vl_logic;
        RST             : in     vl_logic;
        LOAD            : in     vl_logic;
        CNT8            : out    vl_logic_vector(7 downto 0)
    );
end CNT138T;
