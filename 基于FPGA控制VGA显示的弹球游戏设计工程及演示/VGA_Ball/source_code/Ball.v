//弹球生成模块--控制弹球大小、位置、位置更新、输出标志
module Ball(iCLK,iRST_n,Ball_S_in,X_Step,Y_Step,block_X1,block_X2,Ball_X,Ball_Y,Ball_S,flag);
	
	`include "LTM_Param.h"

	input iCLK,iRST_n;
	input [3:0]Ball_S_in;
	input [3:0]X_Step;
	input [3:0]Y_Step;
	input [10:0]block_X1;
	input [10:0]block_X2;
	output [10:0]Ball_X;
	output [9:0]Ball_Y;
	output [7:0]Ball_S;
	output [3:0]flag;
	
	//中间变量
	(*keep*)wire[7:0]Ball_S; 
	reg [10:0]X;       //球在x轴的增量
	reg [10:0]Ball_X;  //球在x轴的位置
	reg [9:0]Y;			 //球在y轴的增量
	reg [9:0]Ball_Y;	 //球在y轴的位置
	reg [3:0]flag;		 //标志位
	
	assign Ball_S={3'b000,Ball_S_in,1'b1}; //球大小的赋值，最小1个像素
	
	always@(posedge iCLK or negedge iRST_n)  //球的x轴坐标位置的输出
		begin
			if(!iRST_n) // 异步复位
				begin 
					Ball_X<=Ball_X_Center; //球的默认位置在屏中央
					X<=0;                  //x方向移动速度为0
					flag[1:0]<=2'b00;		  //标志位的默认输出
				end     						
			else if(Ball_Y+Ball_S>=Ball_Y_Max) //球没有被挡板挡住,掉下去了
				begin 
					X<=11'b0;                    //球掉到底部，x轴方向速度为0
					flag[1:0]<=2'b11;				  //输出标志位
				end         
			else 
				begin
					if(Ball_X+Ball_S>=Ball_X_Max)			//球到达最右边
						begin 
							X<=~{7'b0000000,X_Step}+11'b1;      //x轴步进变为负
							flag[1:0]<=2'b01; 				//输出标志位
						end   
					else 
						begin
							if(Ball_X-Ball_S<=Ball_X_Min) //球到达最左边
								begin 
									X<={7'b0000000,X_Step};			//x轴步进变为正
									flag[1:0]<=2'b10;			//输出标志位
								end
							else 
								begin 
									X<=(X==11'b0)?((Ball_X<block_X2-20)?(~{7'b0000000,X_Step}+11'b1):({7'b0000000,X_Step})):X;  //判断球在中间位置时，让球动起来
								end
						end
						
					Ball_X<=Ball_X+X; //更新弹球X轴位置
				end 
		end 
 
	always@(posedge iCLK or negedge iRST_n)	//球的y轴坐标位置的输出
		begin 
			if(!iRST_n) 
				begin
					Ball_Y<=Ball_Y_Center;		//球的默认位置在屏中央
					Y<=0;								//y方向移动速度为0
					flag[3:2]<=2'b00; 			//标志位的默认输出
				end
	      else 
				begin
					if((Ball_Y+Ball_S>=390)&&(Ball_Y+Ball_S<=400)&&(Ball_X>block_X1)&&(Ball_X<=block_X2))	//球被挡板挡住
						begin
							Y<=~{6'b000000,Y_Step}+10'b1;		//y轴步进变为负
							flag[3:2]<=2'b01;					//输出相应标志位
						end
					else if(Ball_Y+Ball_S>=Ball_Y_Max) 	//球没有被挡板挡住，掉下去了
						begin
							Y<=0;									//球掉到底部，y轴方向速度为0
							flag[3:2]<=2'b11;					//输出标志位
						end
					else 
						begin
							if(Ball_Y-Ball_S<=Ball_Y_Min) //球碰到顶部
								begin
									Y<={6'b000000,Y_Step};	//y轴步进变为正
									flag[3:2]<=2'b10; 		//输出标志位
								end
							else 
								begin
									Y<=((Ball_Y==Ball_Y_Center)&&(Y==10'b0))?{6'b000000,Y_Step}:Y; 		//判断球在中间位置时，让球动起来
								end
						end
						
					Ball_Y<=Ball_Y+Y;  //更新弹球Y轴位置
				end
		end
		
endmodule
		