//乐曲演奏电路设计---实现“梁祝”乐曲的循环演奏
module M_Player(
			input ext_clk_25m, //外部输入25MHz时钟信号
			input ext_rst_n, //外部输入复位信号，低电平有效
			input switch0, //通过拨码开关控制CNT138T模块，手动选择切换歌曲“梁祝”和“欢乐颂”
			output[3:0] dtube_cs_n,	//7段数码管位选信号
			output[7:0] dtube_data,	//7段数码管段选信号（包括小数点为8段）	
			output beep		//蜂鸣器控制信号，1--响，0--不响	
		);
		
//----------------------------------------
//PLL例化
wire clk_2k;	//PLL输出2KHz时钟
wire clk_1m;	//PLL输出1MHz时钟
wire sys_rst_n;	//PLL输出的locked信号，作为FPGA内部的复位信号，低电平复位，高电平正常工作

pll_controller	pll_controller_inst (
	.areset ( !ext_rst_n ),
	.inclk0 ( ext_clk_25m ),
	.c0 ( clk_1m ),
	.c1 ( clk_2k ),
	.locked ( sys_rst_n )
	);
	
//-------------------------------------------------------------------
//2KHz时钟进行分频，产生一个4Hz频率的时钟使能，即满足乐曲0.25秒一个拍子的要求
wire clk_4;		//分频模块输出4Hz时钟

FDIV	FDIV_inst (
	.CLK( clk_2k ),
	.RST_N( sys_rst_n ),
	.PM( clk_4 )
	);
	
//--------------------------------------------------
//4Hz控制乐曲节拍，通过CNT138T实现MUSIC ROM读取地址递增
wire [7:0] rom_address;	//计数器模块输出ROM地址

CNT138T	CNT138T_inst (
	.CLK( clk_4 ),
	.RST( sys_rst_n ),
	.LOAD( switch0 ),
	.CNT8( rom_address )
	);

//------------------------------------------------
//ROM例化，乐谱码按地址存放于ROM中
wire [3:0] inx;	//ROM模块输出乐谱简码

rom_controller	rom_controller_inst (
	.address ( rom_address ),
	.clock ( clk_4 ),
	.q ( inx )
	);
	
//------------------------------------------------
//预置数查表模块根据输入的乐谱简码输出相应的分频预置数
wire [15:0] display_num;	//输出乐谱音符到数码管显示
wire [10:0] tn;	//输出预置数
	
F_CODE	F_CODE_inst (
	.INX( inx ),
	.DISPLAY_NUM( display_num ),
	.TO( tn )
	);

//----------------------------------
//数控分频模块——按预置数发声演奏
wire spks;
 
SPKER	SPKER_inst	(
	.CLK( clk_1m ),
	.RST( sys_rst_n ),
	.TN( tn ),
	.SPKS( spks )
	);

//-----------------------------------
//蜂鸣器发声驱动

beep_controller	beep_controller_inst(
	.CLK( spks ),
	.BEEP( beep )
	);
	
//----------------------------------------------------------------------------------------------
//4位数码管显示驱动：[15:12]数码管千位--“H”（低中高音标识符），[3:0]数码管个位--“CODE”（乐谱音符简码）

seg7	seg7_inst(
		.clk( ext_clk_25m ),	//时钟信号
		.rst_n( sys_rst_n ),	//复位信号，低电平有效
		.display_num( display_num ),		//显示数据	
		.dtube_cs_n( dtube_cs_n ),	//7段数码管位选信号
		.dtube_data( dtube_data )		//7段数码管段选信号（包括小数点为8段）
		);

	
endmodule 

