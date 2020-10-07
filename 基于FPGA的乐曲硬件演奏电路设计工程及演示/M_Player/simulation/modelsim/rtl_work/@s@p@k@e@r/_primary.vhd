library verilog;
use verilog.vl_types.all;
entity SPKER is
    port(
        CLK             : in     vl_logic;
        RST             : in     vl_logic;
        TN              : in     vl_logic_vector(10 downto 0);
        SPKS            : out    vl_logic
    );
end SPKER;
