//数控分频模块的测试模块
`timescale 1ns/1ns

module SPKER_tb;
	reg clk;
	reg rst;
	reg[10:0] tn;
	wire spks;
	
	SPKER u1(.CLK(clk), .RST(rst), .TN(tn), .SPKS(spks));
	initial 
	begin
				clk=0;
				rst=1;
				tn=11'h7ff;	//简谱"0"
	#5000		rst=0;
	#100		rst=1;
	#25000	tn=11'h305;	//简谱"1"
	#25000	tn=11'h390;	//简谱"2"
	#25000	tn=11'h40c;	//简谱"3"
	#25000	tn=11'h45c;	//简谱"4"
	#25000	tn=11'h4ad;	//简谱"5"
	#25000	tn=11'h50a;	//简谱"6"
	#25000	tn=11'h55c;	//简谱"7"
	#25000	tn=11'h582;	//简谱"8"
	#25000	tn=11'h5c8;	//简谱"9"
	#25000	tn=11'h606;	//简谱"10"
	#25000	tn=11'h640;	//简谱"11"
	#25000	tn=11'h656;	//简谱"12"
	#25000	tn=11'h684;	//简谱"13"
	#25000	tn=11'h69a;	//简谱"14"
	#25000	tn=11'h6c0;	//简谱“15”
	#25000	$stop;
	end
	
	always #10 clk=~clk;
	
endmodule 
	