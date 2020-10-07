//pll分频的测试模块
`timescale 1ns/1ns

module pll_controller_tb;
	reg inclk_25m;
	reg areset;
	wire clk0_1m;
	wire clk1_2k;
	wire rst;
	
	pll_controller	u1(.areset(!areset), .inclk0(inclk_25m), .c0(clk0_1m), .c1(clk1_2k), .locked(rst));
	initial
	begin
				inclk_25m=0;
				areset=1;
	#1000		areset=0;
	#200		areset=1;
	end

	always #20	inclk_25m=~inclk_25m;
endmodule	