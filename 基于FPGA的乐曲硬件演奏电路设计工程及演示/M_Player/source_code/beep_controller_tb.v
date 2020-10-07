//蜂鸣器驱动电路的测试模块
`timescale 1ns/1ns

module beep_controller_tb;
	reg clk;
	wire beep;
	
	beep_controller	u1(.CLK(clk), .BEEP(beep));
	initial 
	begin
			clk=0;
	#50	clk=~clk;
	#5		clk=~clk;
	#50	clk=~clk;
	#5		clk=~clk;
	#50	clk=~clk;
	#5		clk=~clk;
	#50	clk=~clk;
	#5		clk=~clk;
	#50	clk=~clk;
	#5		clk=~clk;
	#20	$stop;
	end
	
endmodule 