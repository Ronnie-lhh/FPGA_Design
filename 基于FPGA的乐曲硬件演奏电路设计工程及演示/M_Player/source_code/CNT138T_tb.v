//ROM地址发生器的测试模块
`timescale 1ns/1ns

module CNT138T_tb;
	reg clk;
	reg rst;
	reg load;
	wire[7:0] cnt8;
	
	CNT138T u1(.CLK(clk), .RST(rst), .LOAD(load), .CNT8(cnt8));
	initial 
	begin
				rst=1;
				clk=0;
				load=0;
	#100		rst=0;
	#20		rst=1;
	#3000		load=1;
	#3000		$stop;
	end
	
	always #10	clk=~clk;
	
endmodule 