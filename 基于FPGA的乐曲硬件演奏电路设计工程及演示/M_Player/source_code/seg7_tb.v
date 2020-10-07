//数码管显示驱动的测试模块
`timescale 1ns/1ns

module seg7_tb;
	reg clk;
	reg rst;
	reg[15:0] display_num;
	wire[3:0] dtube_cs_n;
	wire[7:0] dtube_data;
	
	seg7	u1(.clk(clk), .rst_n(rst), .display_num(display_num), .dtube_cs_n(dtube_cs_n), .dtube_data(dtube_data));
	initial
	begin
				clk=0;
				rst=1;
				display_num=0;
	#500		rst=0;
	#500		rst=1;
	#5000		display_num=16'b0000_0000_0000_0111;   //显示数据“7”
	#5000		display_num=16'b0000_0000_0001_0101;	//显示数据“15”
	#5000		display_num=16'b0000_0010_0101_0111;	//显示数据“257”
	#5000		display_num=16'b0001_0000_0000_0110;	//显示数据“1006”
	#5000		display_num=16'b0010_0001_0101_0011;	//显示数据“2153”
	#5000		rst=0;
	#500		rst=1;
	#1000		$stop;
	end
	
	always #10	clk=~clk;
	
endmodule	