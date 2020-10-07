//弹球游戏运行模块--通过状态机控制游戏启动、运行、结束的界面
module state_run(iCLK,iRST_n,iDISPLAY_PAGE,ball_flag,mred_char,mgreen_char,mblue_char,
						mred_ball,mgreen_ball,mblue_ball,mred_over,mgreen_over,mblue_over,mred,mgreen,mblue);
	input iCLK,iRST_n;
	input [1:0]iDISPLAY_PAGE;
	input [3:0]ball_flag;
	input mred_char,mgreen_char,mblue_char;
	input mred_ball,mgreen_ball,mblue_ball;
	input mred_over,mgreen_over,mblue_over;
	output reg mred;
	output reg mgreen;
	output reg mblue;
	
	parameter S0=4'b0001, S1=4'b0010, S2=4'b0100;
	reg [1:0] current_state, next_state;
	
	always @(posedge iCLK or negedge iRST_n)
		begin
			if(!iRST_n)
				current_state<=S0;
			else
				current_state<=next_state;
		end

	always@(current_state or iDISPLAY_PAGE or ball_flag or iRST_n)
		begin
			case(current_state)
			S0: 
			begin    //S0状态下屏幕显示游戏开始的界面
				mred=mred_char;
				mgreen=mgreen_char;
				mblue=mblue_char;
				if(iDISPLAY_PAGE==2'b11)  //判断如果有按下游戏开始按键（S9），进入S1状态，游戏运行
					next_state=S1;
				else next_state=S0;  //否则一直处于S0起始界面
			end
			
			S1: 
			begin             // S1状态下屏幕显示游戏运行的弹球界面
				mred=mred_ball;
				mgreen=mgreen_ball;
				mblue=mblue_ball;
				if(ball_flag==4'b1111) //判断球运行的标志，如果掉到底部，进入S2状态，游戏结束
					next_state=S2;
				else
					next_state=S1;  //否则，在S1弹球运行界面
			end
			
			S2: 
			begin               //S2状态下屏幕显示游戏结束界面
				mred=mred_over;
				mgreen=mgreen_over;
				mblue=mblue_over;
				if(iRST_n) next_state=S2; //复位信号到来后，重新进入游戏开始界面
				else next_state=S0;
			end
			
			default: 
			begin       //default 默认S2状态
				next_state=S2;
				mred=mred_over;
				mgreen=mgreen_over;
				mblue=mblue_over;
			end
			endcase
		end
		
endmodule
	