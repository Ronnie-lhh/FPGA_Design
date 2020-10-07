library verilog;
use verilog.vl_types.all;
entity rom_controller is
    port(
        address         : in     vl_logic_vector(7 downto 0);
        clock           : in     vl_logic;
        q               : out    vl_logic_vector(3 downto 0)
    );
end rom_controller;
