//采集4X4矩阵按键的键值，输出到数码管的末位，数码管每新输入一位数据，都会将原有数据右移一位
module piano(
			input ext_clk_25m,	//外部输入25MHz时钟信号
			input ext_rst_n,	//外部输入复位信号，低电平有效
			input[3:0] key_v,	//4个列按键输入，未按下为高电平，按下后为低电平
			output[3:0] key_h,	//4个行按键输出
			output[3:0] dtube_cs_n,	//7段数码管位选信号
			output[7:0] dtube_data,	//7段数码管段选信号（包括小数点为8段）
         output beep,//蜂鸣器
			output H//高音led指示			
    		);
			
wire key;	//所有按键值相与的结果，用于按键触发判断
assign key = key_v[0] & key_v[1] & key_v[2] & key_v[3];

//-------------------------------------
//键值采集，产生数码管显示数据
wire[15:0] display_num;	//数码管显示数据，[15:12]--数码管千位，[11:8]--数码管百位，[7:4]--数码管十位，[3:0]--数码管个位

arykeyscan		arykeyscan_inst(
					.clk(ext_clk_25m),		//时钟信号
					.rst_n(sys_rst_n),	//复位信号，低电平有效
					.key_v(key_v),	//4个按键输入，未按下为高电平，按下后为低电平
					.key_h(key_h),	//4个行按键输出
					.display_num(display_num)
		    	);


//-------------------------------------
//4位数码管显示驱动															

seg7		seg7_inst(
				.clk(ext_clk_25m),		//时钟信号
				.rst_n(sys_rst_n),	//复位信号，低电平有效
				.display_num(display_num),	
				.dtube_cs_n(dtube_cs_n),	//7段数码管位选信号
				.dtube_data(dtube_data)		//7段数码管段选信号（包括小数点为8段）
		);
		
//------------------------------------------------------------------------------
//PLL例化
wire clk_1m;	//PLL输出1MHz时钟
wire sys_rst_n;	//PLL输出的locked信号，作为FPGA内部的复位信号，低电平复位，高电平正常工作

pll_controller	pll_controller_inst (
	.areset ( !ext_rst_n ),
	.inclk0 ( ext_clk_25m ),
	.c0 ( clk_1m ),
	.locked ( sys_rst_n )
	);
	
//----------------------------------------------------------------------------
wire[3:0] CODE;
wire[10:0] TO;

F_CODE F_CODE_inst(
       .INX(display_num[3:0]),
       .CODE(CODE),
       .H(H),
       .TO(TO)
	);
	
//--------------------------------------
wire SPKS;

SPKER SPKER_inst(
      .CLK(clk_1m),
      .TN(TO),
      .SPKS(SPKS)
	);	
	
//--------------------------------------------
wire Q;

DFF1 DFF_inst(
       .CLK(SPKS),
       .Q(Q)
   );
	
assign beep=(~key)&Q; 

endmodule
