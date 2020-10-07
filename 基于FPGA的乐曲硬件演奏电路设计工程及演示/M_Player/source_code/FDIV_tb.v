//分频器的测试模块
`timescale 1ns/1ns

module FDIV_tb;
	reg clk;
	reg rst_n;
	wire pm;
	
	FDIV u1(.CLK(clk), .RST_N(rst_n), .PM(pm));
	initial 
	begin
				clk=0;
				rst_n=1;
	#1000		rst_n=0;
	#1000		rst_n=1;
	end
	
	always #250000	clk=~clk;
	
endmodule 