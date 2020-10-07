//顶层模块（整个乐曲演奏电路）的测试模块
`timescale 1ns/1ns

module M_Player_tb;
	reg clk_25m;
	reg rst_n;
	reg switch;
	wire[3:0] dtube_cs_n;
	wire[7:0] dtube_data;
	wire beep;
	
	M_Player u1(.ext_clk_25m(clk_25m), .ext_rst_n(rst_n), .switch0(switch), .dtube_cs_n(dtube_cs_n), .dtube_data(dtube_data), .beep(beep));
	initial 
	begin
				clk_25m=0;
				rst_n=1;
				switch=0;
	#10000	rst_n=0;
	#100		rst_n=1;
	#200000	switch=1;
	end

	always #20 clk_25m=~clk_25m;
	
endmodule 