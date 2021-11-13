// *********************************************************************************
// 文件名: lcd_controller.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.19
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: lcd_controller
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)LCD控制驱动模块
//            2)RGB565格式输出
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
`define LCD_480_272

// ---------------------------------------------------------------------------------
// 模块定义 Module Define
// --------------------------------------------------------------------------------- 
module lcd_controller
(
    // clock & reset
    input 			    lcd_clk,                //时钟信号
	input 			    rst_n,  		        //复位信号, 低电平有效

    // input signal
    input      [15 : 0] pixel_data,             //像素数据
    
    // output signal   
    output     [10 : 0] pixel_xpos,             //当前像素点横坐标
    output     [10 : 0] pixel_ypos,             //当前像素点纵坐标
    output     [15 : 0] lcd_rgb565,             //LCD RGB565颜色数据
    output reg [10 : 0] h_disp,                 //LCD 水平分辨率
    output reg [10 : 0] v_disp,                 //LCD 垂直分辨率
    
    // LCD 接口
    output              lcd_de,                 //LCD 数据输入使能信号
    output              lcd_hs,                 //LCD 行同步信号
    output              lcd_vs,                 //LCD 场同步信号
    output reg          lcd_bl,                 //LCD 背光控制信号
    output reg          lcd_rst,                //LCD 复位信号
    output              lcd_dclk                //LCD 驱动时钟
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
`ifdef  LCD_480_272
    //4.3’  480*272  12.5MHz
    parameter   H_SYNC  = 11'd41;               //行同步
    parameter   H_BACK  = 11'd2;                //行显示后沿
    parameter   H_DISP  = 11'd480;              //行有效数据
    parameter   H_FRONT = 11'd2;                //行显示前沿
    parameter   H_TOTAL = 11'd525;              //行扫描周期
    parameter   HS_POL  = 1'b0;                 //行同步信号的极性, 1/0

    parameter   V_SYNC  = 11'd10;               //场同步
    parameter   V_BACK  = 11'd2;                //场显示后沿
    parameter   V_DISP  = 11'd272;              //场有效数据
    parameter   V_FRONT = 11'd2;                //场显示前沿
    parameter   V_TOTAL = 11'd286;              //场扫描周期
    parameter   VS_POL  = 1'b0;                 //场同步信号的极性, 1/0
`endif

// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    reg        [10 : 0] h_sync;                 //行同步
    reg        [10 : 0] h_back;                 //行显示后沿
    reg        [10 : 0] h_total;                //行扫描周期
    reg        [10 : 0] v_sync;                 //场同步
    reg        [10 : 0] v_back;                 //场显示后沿
    reg        [10 : 0] v_total;                //场扫描周期
    reg        [10 : 0] h_cnt;                  //行计数器
    reg        [10 : 0] v_cnt;                  //场计数器
    
    wire                lcd_en;                 //RGB565数据输出使能
    wire                data_req;               //像素点颜色数据输入请求
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    //RGB LCD 采用DE模式时, 行场同步信号需要拉高
    assign  lcd_hs = 1'b1;
    assign  lcd_vs = 1'b1;
    
    assign  lcd_dclk = lcd_clk;
    assign  lcd_de = lcd_en;
    
    //RGB565数据输出使能
    assign  lcd_en   = ((h_cnt >= h_sync + h_back) && 
                        (h_cnt < h_sync + h_back + h_disp) &&
                        (v_cnt >= v_sync + v_back) &&
                        (v_cnt < v_sync + v_back + v_disp))? 1'b1 : 1'b0;
    
    //像素点颜色数据输入请求
    assign  data_req = ((h_cnt >= h_sync + h_back - 11'd1) && 
                        (h_cnt < h_sync + h_back + h_disp - 11'd1) &&
                        (v_cnt >= v_sync + v_back) &&
                        (v_cnt < v_sync + v_back + v_disp))? 1'b1 : 1'b0;
    
    //像素点坐标
    assign  pixel_xpos = data_req? (h_cnt - (h_sync + h_back - 1'b1)) : 11'd0;
    assign  pixel_ypos = data_req? (v_cnt - (v_sync + v_back - 1'b1)) : 11'd0;
    
    //RGB565数据输出
    assign  lcd_rgb565 = lcd_en? pixel_data : 16'd0;
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    //行场时序参数
    always @(posedge lcd_clk)
    begin
        h_sync  <=  H_SYNC;
        h_back  <=  H_BACK;
        h_disp  <=  H_DISP;
        h_total <=  H_TOTAL;
        v_sync  <=  V_SYNC;
        v_back  <=  V_BACK;
        v_disp  <=  V_DISP;
        v_total <=  V_TOTAL;
    end
    
    //行计数器对像素时钟计数
    always @(posedge lcd_clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            h_cnt <= 11'd0;
        end
        else if(h_cnt == h_total - 11'd1)
        begin
            h_cnt <= 11'd0;
        end
        else
        begin
            h_cnt <= h_cnt + 11'd1;
        end
    end
    
    //场计数器对行计数
    always @(posedge lcd_clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            v_cnt <= 11'd0;
        end
        else if(h_cnt == h_total - 11'd1)
        begin
            if(v_cnt == v_total - 11'd1)
            begin
                v_cnt <= 11'd0;
            end 
            else
            begin
                v_cnt <= v_cnt + 11'd1;
            end
        end
        else
        begin
            v_cnt <= v_cnt;
        end
    end
    
    //行同步信号
    // always @(posedge lcd_clk or negedge rst_n)
    // begin
        // if(!rst_n)
        // begin
            // lcd_hs <= 1'b0;
        // end
        // else if(h_cnt == H_FRONT - 11'd1)           //行同步信号开始
        // begin
            // lcd_hs <= HS_POL;
        // end
        // else if(h_cnt == H_FRONT + H_SYNC - 11'd1)  //行同步信号结束
        // begin
            // lcd_hs <= ~lcd_hs;
        // end
        // else
        // begin
            // lcd_hs <= lcd_hs;
        // end
    // end
    
    //场同步信号
    // always @(posedge lcd_clk or negedge rst_n)
    // begin
        // if(!rst_n)
        // begin
            // lcd_vs <= 1'b0;
        // end
        // else if((v_cnt == V_FRONT - 11'd1) && (h_cnt == H_FRONT - 11'd1))               //场同步信号开始
        // begin
            // lcd_vs <= VS_POL;
        // end
        // else if((v_cnt == V_FRONT + V_SYNC - 11'd1) && (h_cnt == H_FRONT - 11'd1))      //场同步信号结束
        // begin
            // lcd_vs <= ~lcd_vs;
        // end
        // else
        // begin
            // lcd_vs <= lcd_vs;
        // end
    // end
    
    //LCD复位信号和背光控制信号
    always @(posedge lcd_clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            lcd_rst <= 1'b0;
            lcd_bl  <= 1'b0;
        end
        else
        begin
            lcd_rst <= 1'b1;
            lcd_bl  <= 1'b1;
        end
    end

// ---------------------------------------------------------------------------------
// 结构化描述 Moudle Instantiate
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------
    

// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------


endmodule 