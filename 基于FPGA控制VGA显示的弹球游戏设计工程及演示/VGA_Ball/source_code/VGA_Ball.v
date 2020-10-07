//基于FPGA的VGA显示弹球的游戏设计
//***********键控说明***********************************
//		 S1					 增大x方向的速度
//		 S2					 减小x方向的速度
//		 S3					 增大y方向的速度
//		 S4					 减小y方向的速度
//		 S5					 切换到上一个背景颜色
//		 S6					 切换到下一个背景颜色
//		 S7					 增大挡板的大小
//		 S8					 减小挡板的大小
//		 S13					 控制挡板左移
//		 S14					 控制挡板右移
//		 S9					 开始游戏
//		 RESET				 重启游戏，回到游戏启动页面
//	SW3 SW4 SW5 SW6		 输入弹球的半径，调整弹球大小
//*******************************************************

module VGA_Ball(
		input ext_clk_25m,	//外部输入25MHz时钟信号
		input ext_rst_n,		//外部输入复位信号，低电平有效
		input [3:0]switch,	//拨码开关输入弹球半径大小
		input [3:0]key_v,		//4个列按键输入，未按下为高电平，按下后为低电平
		output [3:0]key_h,	//4个行按键输出
		output vga_r,			//可见显示区的R分量
		output vga_g,			//可见显示区的G分量
		output vga_b,			//可见显示区的B分量
		output vga_hsy,		//行同步信号
		output vga_vsy			//场同步信号
		);
	
	//-------------------------------------
	//键值采集和消抖模块--产生键控指令
	wire [15:0]key_num;	

	arykeyscan		arykeyscan_inst(
						.clk(ext_clk_25m),				//时钟信号
						.rst_n(ext_rst_n),		//复位信号，低电平有效
						.key_v(key_v),				//4个按键输入，未按下为高电平，按下后为低电平
						.key_h(key_h),				//4个行按键输出
						.display_num(key_num)	//产生键控指令
						);
						
	//--------------------------------------
	//背景颜色选择模块--产生背景选择信号
	wire [15:0]iDISPLAY_MODE;
	
	Background_Color	Background_Color_inst(
							.iCLK(ext_clk_25m),
							.iRST_n(ext_rst_n),
							.key_num(key_num),
							.oBackground_set(iDISPLAY_MODE)
							);
	
	//-----------------------------------------
	//颜色产生模块--产生球色、挡板色、背景色（可选）
	wire [7:0]Ball_S;
	wire [10:0]block_X1;
	wire [10:0]block_X2;
	wire [10:0]Ball_X;
	wire [9:0]Ball_Y;
	
	color_gen	color_gen_inst(
					.iCLK(ext_clk_25m),
					.iRST_n(ext_rst_n),
					.Ball_X(Ball_X),
					.Ball_Y(Ball_Y),
					.iVGA_X(oH_cnt),
					.iVGA_Y(oV_cnt),
					.Ball_S(Ball_S),
					.block_X1(block_X1),
					.block_X2(block_X2),
					.iDISPLAY_MODE(iDISPLAY_MODE),
					.oVGA_R(mred_ball),
					.oVGA_G(mgreen_ball),
					.oVGA_B(mblue_ball)
					);
	
	//----------------------------------------------
	//游戏启动模块--按下S9键开始游戏
	wire [1:0]iDISPLAY_PAGE;
	
	game_start		game_start_inst(
						.iCLK(ext_clk_25m),
						.iRST_n(ext_rst_n),
						.key_num(key_num),
						.oDISPLAY_PAGE(iDISPLAY_PAGE)
					   );
	
	//--------------------------------------------
	//弹球游戏运行模块--控制游戏启动、运行、结束的界面
	wire [3:0]ball_flag;
	wire mred_char,mgreen_char,mblue_char;	//游戏启动页面
	wire mred_ball,mgreen_ball,mblue_ball;	//游戏运行页面
	wire mred_over,mgreen_over,mblue_over;	//游戏结束页面
	wire mred,mgreen,mblue;						//实际输出
	
	state_run	state_run_inst(
					.iCLK(ext_clk_25m),
					.iRST_n(ext_rst_n),
					.iDISPLAY_PAGE(iDISPLAY_PAGE),
					.ball_flag(ball_flag),
					.mred_char(mred_char),
					.mgreen_char(mgreen_char),
					.mblue_char(mblue_char),
					.mred_ball(mred_ball),
					.mgreen_ball(mgreen_ball),
					.mblue_ball(mblue_ball),
					.mred_over(mred_over),
					.mgreen_over(mgreen_over),
					.mblue_over(mblue_over),
					.mred(mred),
					.mgreen(mgreen),
					.mblue(mblue)
					);
	
	//-----------------------------------------------
	//弹球生成模块--控制弹球大小、位置、位置更新、输出标志
	wire [3:0]oSpeed_X;
	wire [3:0]oSpeed_Y;
	
	Ball	Ball_inst(
			.iCLK(vga_vsy),
			.iRST_n(ext_rst_n),
			.Ball_S_in(switch),
			.X_Step(oSpeed_X),
			.Y_Step(oSpeed_Y),
			.block_X1(block_X1),
			.block_X2(block_X2),
			.Ball_X(Ball_X),
			.Ball_Y(Ball_Y),
			.Ball_S(Ball_S),
			.flag(ball_flag)
			);
	
	//-----------------------------------------------------------
	//弹球速度键控模块--通过S1、S2、S3、S4按键改变弹球在x和y方向的速度
	Ball_speed	Ball_speed_inst(
					.iCLK(ext_clk_25m),
					.iRST_n(ext_rst_n),
					.key_num(key_num),
					.oSpeed_X(oSpeed_X),
					.oSpeed_Y(oSpeed_Y)
					);
	
	//--------------------------------------------------------------
	//挡板生成模块--通过S7、S8按键改变挡板大小，通过左右移信号实现左右移动
	wire oMOVE_RIGHT;
	wire oMOVE_LEFT;
	
	block		block_inst(
				.iCLK(ext_clk_25m),
				.iRST_n(ext_rst_n),
				.iMOVE_RIGHT(oMOVE_RIGHT),
				.iMOVE_LEFT(oMOVE_LEFT),
				.key_num(key_num),
				.block_X1(block_X1),
				.block_X2(block_X2)
				);
	
	//-----------------------------------------------------------
	//挡板键控模块--按下按键S13、S14，输出左移和右移信号
	block_move		block_move_inst(
						.iCLK(ext_clk_25m),
						.iRST_n(ext_rst_n),
						.key_num(key_num),
						.oMOVE_LEFT(oMOVE_LEFT),
						.oMOVE_RIGHT(oMOVE_RIGHT)
						);
	
	//-----------------------------------------------
	//“游戏开始”字符产生模块--游戏启动页面
	color_gen_char1	color_gen_char1_inst(
							.iVGA_X(oH_cnt),
							.iVGA_Y(oV_cnt),
							.oVGA_R(mred_char),
							.oVGA_G(mgreen_char),
							.oVGA_B(mblue_char)
							);
							
	//-----------------------------------------------
	//“游戏结束”字符产生模块--游戏结束页面
	color_gen_char2	color_gen_char2_inst(
							.iVGA_X(oH_cnt),
							.iVGA_Y(oV_cnt),
							.oVGA_R(mred_over),
							.oVGA_G(mgreen_over),
							.oVGA_B(mblue_over)
							);
	
	//--------------------------------------------------------------------------
	//VGA时序控制模块--完成时序扫描，输出LCD显示的RGB数值及水平和垂直方向的同步信号
	wire [10:0]oH_cnt;	//行计数器--VGA扫描点的x坐标
	wire [9:0]oV_cnt;		//列计数器--VGA扫描点的y坐标
	
	vga_controller		vga_controller_inst(
							.iCLK(ext_clk_25m),
							.iRST_n(ext_rst_n),
							.iR(mred),
							.iG(mgreen),
							.iB(mblue),
							.oVGA_R(vga_r),
							.oVGA_G(vga_g),
							.oVGA_B(vga_b),
							.oVGA_HS(vga_hsy),
							.oVGA_VS(vga_vsy),
							.oH_cnt(oH_cnt),
							.oV_cnt(oV_cnt)
							);

endmodule 