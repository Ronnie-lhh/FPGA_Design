//蜂鸣器驱动电路模块
module beep_controller(CLK, BEEP);
	input CLK;
	output BEEP;
	reg Q=0;
	
	always @(posedge CLK)
	begin
		Q=~Q;
	end
	assign BEEP=Q;
	
endmodule 
