//存储乐谱码ROM的测试模块
`timescale 1ns/1ns

module rom_controller_tb;
	reg[7:0] address;
	reg clk;
	wire[3:0] q;
	
	rom_controller 	u1(.address(address), .clock(clk), .q(q));
	initial 
	begin
			clk=0;
			address=0;
	end
	
	always #10  clk=~clk;
	always #100 address=address+1;
	
endmodule
	