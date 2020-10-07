//游戏启动模块--键控开始游戏
module game_start(iCLK, iRST_n, key_num, oDISPLAY_PAGE);
	input iCLK;
	input iRST_n;
	input [15:0]key_num;
	output [1:0]oDISPLAY_PAGE;
	
	reg [1:0]oDISPLAY_PAGE;
	
	always @(posedge iCLK or negedge iRST_n)
		begin
			if(!iRST_n) 
				oDISPLAY_PAGE<=2'b00;
			else if(key_num[3:0]==4'h8)		//按下按键S9后，进入游戏启动界面
				oDISPLAY_PAGE<=2'b11;
		end
		
endmodule 