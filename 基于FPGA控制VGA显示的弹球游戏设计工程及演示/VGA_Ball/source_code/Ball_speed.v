//弹球速度键控模块--通过S1、S2、S3、S4按键改变弹球在x和y方向的速度
module Ball_speed(iCLK,iRST_n,key_num,oSpeed_X,oSpeed_Y);
	input iCLK,iRST_n;
	input [15:0]key_num;
	output [3:0]oSpeed_X;
	output [3:0]oSpeed_Y;
	
	reg [3:0]oSpeed_X;
	reg [3:0]oSpeed_Y;
	
	always@(posedge iCLK or negedge iRST_n)
		begin
			if(!iRST_n)
				begin
					oSpeed_X<=0;
					oSpeed_Y<=0;
				end
			else 
				begin
					if(key_num[3:0]==4'h0)		//按下S1按键时，增大x方向的速度
						oSpeed_X<=oSpeed_X+1;
					else if(key_num[3:0]==4'h1)	//按下S2按键时，减小x方向的速度
						begin
							if(oSpeed_X==0)	//当x方向速度为0时，将不会继续减小
								oSpeed_X<=oSpeed_X;
							else
								oSpeed_X<=oSpeed_X-1;
						end
					else if(key_num[3:0]==4'h2)	//按下S3按键时，增大y方向的速度
						oSpeed_Y<=oSpeed_Y+1;
					else if(key_num[3:0]==4'h3)	//按下S4按键时，减小y方向的速度
						begin
							if(oSpeed_Y==0)	//当y方向速度为0时，将不会继续减小
								oSpeed_Y<=oSpeed_Y;
							else
								oSpeed_Y<=oSpeed_Y-1;
						end
					else
						begin
							oSpeed_X<=oSpeed_X;
							oSpeed_Y<=oSpeed_Y;
						end
				end
		end
		
endmodule 

