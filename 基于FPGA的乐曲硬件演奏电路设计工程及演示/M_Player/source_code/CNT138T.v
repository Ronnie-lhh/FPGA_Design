//乐曲长度控制计数器模块--音符数据ROM的地址发生器
module CNT138T(CLK, RST, LOAD, CNT8);
	input CLK;
	input RST;
	input LOAD;
	output[7:0] CNT8;
	reg[7:0] CNT;
	
	always @(posedge CLK or negedge RST)
	begin
		if (!RST) CNT<=8'b00000000;
		else   
		begin
			case (LOAD)
				0:  
				begin      
					if (CNT<=138) CNT<=CNT+1;
					else CNT=0;
				end 
				1:
				begin 
					if (CNT>=139&&CNT<=256) CNT<=CNT+1;
					else CNT=139;
				end
			endcase	
		end
	end
	assign CNT8=CNT;	
	
endmodule 
	
