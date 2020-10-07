//挡板生成模块--通过S7、S8按键改变挡板大小，通过左右移动信号实现左右移动
module block(iCLK,iRST_n,iMOVE_RIGHT,iMOVE_LEFT,key_num,block_X1,block_X2);

`include  "LTM_Param.h"

	input iCLK,iRST_n;
	input iMOVE_RIGHT;   		//挡板右移信号
	input iMOVE_LEFT;  			//挡板左移信号
	input [15:0]key_num;      	//按下S7、S8按键，改变挡板大小
	output [10:0] block_X1;		//挡板最左端位置
	output [10:0] block_X2;		//挡板最右端位置

	reg [7:0]block_X;   //挡板大小的中间变量，表示挡板一半大小
	wire [10:0]block_center; //挡板中点坐标X轴位置变量

	reg [10:0]block_center_add,block_center_sub; //挡板中点坐标位置增减变量，含义为挡板左右移动

	always@(posedge iCLK or negedge iRST_n) //实现挡板大小改变	
		begin
			if(!iRST_n) 
				block_X<=100;				//挡板默认长度为100
			else 
				begin
					if(key_num[3:0]==4'h6)	
						begin
							if(block_X==200) block_X<=block_X;		//挡板达到最大长度200，不再增长					
							else block_X<=block_X+5;					//每按一次S7键，挡板长度+5
						end
					else if(key_num[3:0]==4'h7)
						begin 
							if(block_X==10) block_X<=block_X;		//挡板达到最小长度10，不再减短
							else block_X<=block_X-5;					//每按一次S8键，挡板长度-5
						end
					else 
						block_X<=block_X;
				end
		end
	 
	assign block_X1=block_center-block_X;
	assign block_X2=block_center+block_X;
	 
	assign block_center=Ball_X_Center+block_center_add-block_center_sub;
	 
	always@(posedge iCLK or negedge iRST_n) //挡板右移
		begin
			if(!iRST_n) block_center_add=0;  //中心位置增量为 0
			else if(iMOVE_RIGHT)       		//判断右移信号是否到来
				begin
					if(block_center>Ball_X_Max-block_X)  		//判断是否到最右
						block_center_add<=block_center_add; 	//是，则中心保持不变
					else
						block_center_add<=block_center_add+10; //否，则右移 10
				end
			else block_center_add<=block_center_add;			//无右移信号，坐标值不变
		end
	 
	always@(posedge iCLK or negedge iRST_n) //挡板左移
		begin
			if(!iRST_n) block_center_sub<=0;	//中心位置减量为0
			else if(iMOVE_LEFT)					//判断左移信号是否到来
				begin
					if(block_center<Ball_X_Min+block_X)			//判断是否到最左
						block_center_sub<=block_center_sub;		//是，则中心保持不变
					else
						block_center_sub<=block_center_sub+10;	//否，则左移10
				end
			else block_center_sub<=block_center_sub;		//无左移信号，坐标值不变
		end
 
endmodule

