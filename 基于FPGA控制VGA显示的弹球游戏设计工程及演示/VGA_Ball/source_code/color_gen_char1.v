//“游戏开始”字符产生模块--游戏启动页面
module color_gen_char1(iVGA_X,iVGA_Y,oVGA_R,oVGA_G,oVGA_B);
	input [10:0]iVGA_X;   	//行列扫描对应点坐标值
	input [9:0]iVGA_Y ;   	
	output reg oVGA_R;
	output reg oVGA_G;
	output reg oVGA_B;

	`include "Begin.h"  		//包含的头文件为所显示字符的点阵数值
		  
	always@(iVGA_X or iVGA_Y)
		begin
			if((iVGA_Y<CHAR_START_Y)||(iVGA_Y>(CHAR_START_Y+CHAR_Y-1))||(iVGA_X<CHAR_START_X)||
			(iVGA_X>(CHAR_START_X+CHAR_X-1)))   //非字符显示区域，输出相应的颜色
				begin
					oVGA_R=1'b0;
					oVGA_G=1'b0;
					oVGA_B=1'b1;
				end
			else     //在字符显示区域显示相应的颜色
				begin 
					case(iVGA_Y)  //case 语句判断显示的行数，实现字符的点阵输出
		
					231: 
					begin
						oVGA_R={1{charline_a0[CHAR_START_X+CHAR_X-iVGA_X-1]}}; //R分量的值为字模点阵的值，用红色字体显示
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					232: 
					begin
						oVGA_R={1{charline_a1[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					233: 
					begin
						oVGA_R={1{charline_a2[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					234: 
					begin
						oVGA_R={1{charline_a3[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					235: 
					begin
						oVGA_R={1{charline_a4[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					236: 
					begin
						oVGA_R={1{charline_a5[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					237: 
					begin
						oVGA_R={1{charline_a6[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					238: 
					begin
						oVGA_R={1{charline_a7[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					239: 
					begin
						oVGA_R={1{charline_a8[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					240: 
					begin
						oVGA_R={1{charline_a9[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					241: 
					begin
						oVGA_R={1{charline_a10[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					242: 
					begin
						oVGA_R={1{charline_a11[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					243: 
					begin
						oVGA_R={1{charline_a12[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					244: 
					begin
						oVGA_R={1{charline_a13[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					245: 
					begin
						oVGA_R={1{charline_a14[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					246: 
					begin
						oVGA_R={1{charline_a15[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					247: 
					begin
						oVGA_R={1{charline_a16[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					248: 
					begin
						oVGA_R={1{charline_a17[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					249: 
					begin
						oVGA_R={1{charline_a18[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					250: 
					begin
						oVGA_R={1{charline_a19[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					251: 
					begin
						oVGA_R={1{charline_a20[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					252: 
					begin
						oVGA_R={1{charline_a21[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					253: 
					begin
						oVGA_R={1{charline_a22[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					254: 
					begin
						oVGA_R={1{charline_a23[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					255: 
					begin
						oVGA_R={1{charline_a24[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					256: 
					begin
						oVGA_R={1{charline_a25[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					257: 
					begin
						oVGA_R={1{charline_a26[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					258: 
					begin
						oVGA_R={1{charline_a27[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					259: 
					begin
						oVGA_R={1{charline_a28[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					260: 
					begin
						oVGA_R={1{charline_a29[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					261: 
					begin
						oVGA_R={1{charline_a30[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					262: 
					begin
						oVGA_R={1{charline_a31[CHAR_START_X+CHAR_X-iVGA_X-1]}};
						oVGA_G={1{1'b0}};
						oVGA_B={1{1'b0}};
					end
					
					endcase
				end
		end
		
endmodule
	
	
	
   