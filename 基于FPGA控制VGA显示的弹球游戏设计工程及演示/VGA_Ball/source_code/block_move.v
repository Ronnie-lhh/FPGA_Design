//挡板键控模块--按下按键S13、S14，输出左移和右移信号
module block_move(iCLK,iRST_n,key_num,oMOVE_LEFT,oMOVE_RIGHT);
	input iCLK,iRST_n;
	input [15:0]key_num;		//按键输入信号
	output oMOVE_LEFT;   	//挡板左移输出信号
	output oMOVE_RIGHT;  	//挡板右移输出信号

	reg oMOVE_LEFT;
	reg oMOVE_RIGHT;

	always@(posedge iCLK or negedge iRST_n) // 实现挡板左移和右移信号的产生
		begin
			if(!iRST_n) 
				begin  
					oMOVE_LEFT<=1'b0;       //默认无效输出
					oMOVE_RIGHT<=1'b0;  
				end
			else
				begin
					if(key_num[3:0]==4'hC)		//按下S13键，挡板左移
						begin
							oMOVE_LEFT<=1'b1;
							oMOVE_RIGHT<=1'b0;
						end
					else if(key_num[3:0]==4'hD)	//按下S14键，挡板右移
						begin
							oMOVE_LEFT<=1'b0;
							oMOVE_RIGHT<=1'b1;
						end
					else
						begin
							oMOVE_LEFT<=1'b0;
							oMOVE_RIGHT<=1'b0;
						end
				end
		end
		
endmodule 