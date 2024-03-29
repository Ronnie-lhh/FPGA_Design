// *********************************************************************************
// 文件名: lcd_test.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.19
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: lcd_test
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)LCD测试模块
//            2)在LCD屏幕上显示彩条
//             3)4.3寸LCD, 480*272
//              4)RGB888格式输出
// --------------------------------------------------------------------------------- 
// 变更描述:     
//    
// ---------------------------------------------------------------------------------
// 发布记录: 	 
//
// ---------------------------------------------------------------------------------
// *********************************************************************************


// ---------------------------------------------------------------------------------
// 引用文件 Include File
// --------------------------------------------------------------------------------- 

// ---------------------------------------------------------------------------------
// 仿真时间 Simulation Timescale
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// 常量参数 Constant Parameters
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// 模块定义 Module Define
// --------------------------------------------------------------------------------- 
module lcd_test
(
    // clock & reset
    input 			    sys_clk,	            //时钟信号
	input 			    key_rst_n,              //按键复位, 低电平有效
    
    // output signal
    // LCD 接口
    output              lcd_de,                 //LCD 数据输入使能信号
    output              lcd_hs,                 //LCD 行同步信号
    output              lcd_vs,                 //LCD 场同步信号
    output              lcd_bl,                 //LCD 背光控制信号
    output              lcd_rst,                //LCD 复位信号
    output              lcd_dclk,               //LCD 驱动时钟
    output     [ 7 : 0] lcd_r,                  //LCD RGB888红色数据
    output     [ 7 : 0] lcd_g,                  //LCD RGB888绿色数据
    output     [ 7 : 0] lcd_b                   //LCD RGB888蓝色数据
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------

   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    wire       [10 : 0] pixel_xpos;             //当前像素点横坐标
    wire       [10 : 0] pixel_ypos;             //当前像素点纵坐标
    wire       [10 : 0] h_disp;                 //LCD 水平分辨率
    wire       [10 : 0] v_disp;                 //LCD 垂直分辨率
    wire       [15 : 0] pixel_data;             //像素数据
    wire       [15 : 0] lcd_rgb565;             //LCD RGB565颜色数据
    
    wire                sys_clk_bufg;           //经IBUFG后输出的时钟
    wire                clk_12_5m;              //12.5MHz时钟
    wire                sys_rst_n;              //系统复位信号
    wire                locked;                 //PLL输出有效标志
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    //待PLL输出稳定之后, 停止系统复位
    assign sys_rst_n = key_rst_n & locked;
    
    //将RGB565格式配置为RGB888格式输出
    assign lcd_r = {lcd_rgb565[15 : 11], 3'b000};
    assign lcd_g = {lcd_rgb565[10 :  5], 2'b00};
    assign lcd_b = {lcd_rgb565[ 4 :  0], 3'b000};
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    

// ---------------------------------------------------------------------------------
// 结构化描述 Moudle Instantiate
// ---------------------------------------------------------------------------------
    // 输入全局缓冲
    IBUFG       U_IBUFG
    (
        .O                      (sys_clk_bufg),
        .I                      (sys_clk)
    );
    
    // PLL例化
    lcd_pll     U_lcd_pll
    (
        // clock & reset
        .clk_in                 (sys_clk_bufg),
        .areset                 (~key_rst_n),
        
        .clk_out1               (clk_12_5m),
        .locked                 (locked)
    );
    
    // LCD显示内容模块
    lcd_disp        U_lcd_disp
    (
        // clock & reset
        .lcd_clk                (clk_12_5m),
        .rst_n 	                (sys_rst_n),

        // input signal
        .pixel_xpos             (pixel_xpos),
        .pixel_ypos             (pixel_ypos),
        .h_disp                 (h_disp),
        .v_disp                 (v_disp),

        // output signal
        .pixel_data             (pixel_data)
    );
    
    // LCD控制驱动模块
    lcd_controller      U_lcd_controller
    (
        // clock & reset
        .lcd_clk                (clk_12_5m),
        .rst_n 	                (sys_rst_n),

        // input signal
        .pixel_data             (pixel_data),

        // output signal
        .pixel_xpos             (pixel_xpos),
        .pixel_ypos             (pixel_ypos),
        .lcd_rgb565             (lcd_rgb565),
        .h_disp                 (h_disp),
        .v_disp                 (v_disp),

        // LCD 接口
        .lcd_de                 (lcd_de),
        .lcd_hs                 (lcd_hs),
        .lcd_vs                 (lcd_vs),
        .lcd_bl                 (lcd_bl),
        .lcd_rst                (lcd_rst),
        .lcd_dclk               (lcd_dclk)
    );

// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------
    
	
// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------

    
endmodule 