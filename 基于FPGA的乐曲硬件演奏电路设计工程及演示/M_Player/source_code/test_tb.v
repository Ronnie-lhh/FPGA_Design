//联合测试的测试仿真模块
`timescale 1ns/1ns

module test_tb;
	reg clk_4;
	reg clk_1m;
	reg rst;
	reg load;
	wire[15:0] display_num;
	wire spks;
	
	test u1(.clk_4(clk_4), .clk_1m(clk_1m), .rst(rst), .load(load), .display_num(display_num), .spks(spks));
	initial 
	begin
				clk_4=0;
				clk_1m=0;
				rst=1;
				load=0;
	#1000		rst=0;
	#1000		rst=1;
	end 
	
	always #125000000 clk_4=~clk_4;
	always #500			clk_1m=~clk_1m;
	
endmodule 