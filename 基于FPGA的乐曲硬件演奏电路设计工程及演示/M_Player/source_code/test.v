//联合测试仿真的顶层模块
module test(
		input clk_4,
		input clk_1m,
		input rst,
		input load,
		output[15:0] display_num,
		output spks		
		);

wire [7:0] rom_address;
		
CNT138T	uut_CNT138T (
	.CLK( clk_4 ),
	.RST( rst ),
	.LOAD(load),
	.CNT8( rom_address )
	);

wire [3:0] inx;

rom_controller	uut_rom_controller (
	.address ( rom_address ),
	.clock ( clk_4 ),
	.q ( inx )
	);

wire [10:0] tn;	
	
F_CODE	uut_F_CODE (
	.INX( inx ),
	.DISPLAY_NUM( display_num ),
	.TO( tn )
	);

 
SPKER	uut_SPKER	(
	.CLK( clk_1m ),
	.RST( rst ),
	.TN( tn ),
	.SPKS( spks )
	);
	
endmodule 