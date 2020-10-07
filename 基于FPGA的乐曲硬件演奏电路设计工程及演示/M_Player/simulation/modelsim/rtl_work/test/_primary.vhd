library verilog;
use verilog.vl_types.all;
entity test is
    port(
        clk_4           : in     vl_logic;
        clk_1m          : in     vl_logic;
        rst             : in     vl_logic;
        load            : in     vl_logic;
        display_num     : out    vl_logic_vector(15 downto 0);
        spks            : out    vl_logic
    );
end test;
