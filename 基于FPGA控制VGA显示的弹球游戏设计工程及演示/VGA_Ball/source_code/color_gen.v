//颜色产生模块--显示球色，挡板色，背景色（模式不同背景色可选）
module color_gen(iCLK,iRST_n,Ball_X,Ball_Y,iVGA_X,iVGA_Y,Ball_S,block_X1,block_X2,iDISPLAY_MODE,oVGA_R,oVGA_G,oVGA_B);

`include "LTM_Param.h"

	input iCLK, iRST_n;
	input [10:0]Ball_X;
	input [9:0]Ball_Y;
	input [10:0]iVGA_X; 
	input [9:0]iVGA_Y; 
	input [7:0]Ball_S;
	input [10:0]block_X1,block_X2;
	input [1:0]iDISPLAY_MODE;
	output reg oVGA_R;
	output reg oVGA_G;
	output reg oVGA_B;

	(*keep*)wire Ball_Show;
	wire[21:0]Delta_X2,Delta_Y2,R2;

	assign Delta_X2=(iVGA_X-Ball_X)*(iVGA_X-Ball_X);
	assign Delta_Y2=(iVGA_Y-Ball_Y)*(iVGA_Y-Ball_Y);
	assign R2=(Ball_S*Ball_S);
	assign Ball_Show =(Delta_X2+Delta_Y2)<=R2?1'b1:1'b0;

	always@(Ball_Show,iVGA_X,iVGA_Y,iDISPLAY_MODE)
		begin
			if(Ball_Show) //显示球
				begin
					oVGA_R=1'b1;
					oVGA_G=1'b1;
					oVGA_B=1'b1;
				end
			else 
				begin
					if((iVGA_X>=block_X1)&&(iVGA_X<=block_X2)&&(iVGA_Y>390)&&(iVGA_Y<405)) //挡板位置
						begin
							oVGA_R={1{1'b0}};
							oVGA_G={1{1'b0}};
							oVGA_B={1{1'b1}};
						end 
					else 
						begin
							if(iDISPLAY_MODE==2'b11)  //蓝绿色
								begin
									oVGA_R=1'b0;
									oVGA_G=1'b1;
									oVGA_B=1'b1;
								end
							else if(iDISPLAY_MODE==2'b10) //品红色
								begin
									oVGA_R=1'b1;
									oVGA_G=1'b0;
									oVGA_B=1'b1;
								end	  
							else if(iDISPLAY_MODE==2'b01) //黄色
								begin
									oVGA_R=1'b1;
									oVGA_G=1'b1;
									oVGA_B=1'b0;
								end	 
							else
								begin        //红色
									oVGA_R=1'b1;
									oVGA_G=1'b0;
									oVGA_B=1'b0; 
								end 
						end
				end 
		end

endmodule

 
