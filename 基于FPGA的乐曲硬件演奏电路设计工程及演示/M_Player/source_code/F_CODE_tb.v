//分频预置数查表电路的测试模块
`timescale 1ns/1ns

module F_CODE_tb;
	reg [3:0] inx;
	wire [15:0] display_num;
	wire [10:0] to;
	
	F_CODE u1(.INX(inx), .DISPLAY_NUM(display_num), .TO(to));
	initial 
	begin
				inx=0;
	#200		$stop;
	end
	
	always #10 inx=inx+1;
	
endmodule 