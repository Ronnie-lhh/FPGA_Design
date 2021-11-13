// *********************************************************************************
// 文件名: i2c_ov5640_rgb565_cfg.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.18
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: i2c_ov5640_rgb565_cfg
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)OV5640寄存器配置模块
//            2)通过IIC配置成RGB565格式
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
module i2c_ov5640_rgb565_cfg
#(
    // parameter passing
    parameter CMOS_H_PIXEL  = 13'd480,          //CMOS水平方向像素个数
    parameter CMOS_V_PIXEL  = 13'd272,          //CMOS垂直方向像素个数
    parameter TOTAL_H_PIXEL = 13'd1800,         //水平总像素大小
    parameter TOTAL_V_PIXEL = 13'd1000,         //垂直总像素大小
    parameter CMOS_HV_SIZE  = 24'd130560        //CMOS输出图像的大小, CMOS_H_PIXEL * CMOS_V_PIXEL
                                                //用于配置写SDRAM的最大地址
)
(
    // clock & reset
    input 			    clk,		            //时钟信号
	input 			    rst_n,  		        //复位信号, 低电平有效

    // input signal
    input               i2c_done,               //I2C一个寄存器配置完成信号
    input      [ 7 : 0] i2c_rd_data,            //I2C读出的数据
    
    // output signal                       
    output reg          i2c_exec,               //I2C触发执行信号
    output reg          i2c_init_done,          //I2C初始化完成信号(所有寄存器配置完成)
    output              i2c_rw_ctrl,            //I2C读写控制信号, 读(1)/写(0)
    output reg [23 : 0] i2c_data                //I2C要配置的地址与数据, 地址(高16位)/数据(低8位)
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
   localparam REG_NUM = 10'd248;                //总共需要配置的寄存器个数
   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    reg        [14 : 0] start_20ms_cnt;         //上电等待20ms延时计数器
    reg        [ 9 : 0] init_reg_cnt;           //寄存器配置个数计数器
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 

    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    //OV5640上电到开始配置IIC需至少等待20ms
    //cam_scl配置成250KHz, 输入的clk为1MHz, 周期为1us, 20000*1us = 20ms
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            start_20ms_cnt <= 15'd0;
        end
        else if(start_20ms_cnt < 15'd20000)
        begin
            start_20ms_cnt <= start_20ms_cnt + 15'd1;
        end
        else
        begin
            start_20ms_cnt <= start_20ms_cnt;
        end
    end
    
    //寄存器配置个数计数
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            init_reg_cnt <= 10'd0;
        end
        else if(i2c_exec)
        begin
            init_reg_cnt <= init_reg_cnt + 10'd1;
        end
        else
        begin
            init_reg_cnt <= init_reg_cnt;
        end
    end
    
    //I2C触发执行信号
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            i2c_exec <= 1'b0;
        end
        else if(start_20ms_cnt == 15'd19999)
        begin
            i2c_exec <= 1'b1;
        end        
        else if(i2c_done && (init_reg_cnt < REG_NUM))
        begin
            i2c_exec <= 1'b1;
        end
        else
        begin
            i2c_exec <= 1'b0;
        end
    end
    
    //配置I2C读写控制信号
    // always @(posedge clk or negedge rst_n)
    // begin
        // if(!rst_n)
        // begin
            // i2c_rw_ctrl <= 1'b1;                //读
        // end
        // else if(init_reg_cnt == 10'd2)
        // begin
            // i2c_rw_ctrl <= 1'b0;                //写
        // end
        // else
        // begin
            // i2c_rw_ctrl <= i2c_rw_ctrl;
        // end
    // end
    
    //I2C初始化完成信号
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            i2c_init_done <= 1'b0;
        end
        else if(i2c_done && (init_reg_cnt == REG_NUM))
        begin
            i2c_init_done <= 1'b1;
        end
        else
        begin
            i2c_init_done <= i2c_init_done;
        end
    end
    
    //配置寄存器地址与数据
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            i2c_data <= 24'd0;
        end
        else
        begin
            case(init_reg_cnt)
                            //先对寄存器进行软件复位, 使寄存器恢复初始值
                            //寄存器软件复位后, 需要延时1ms才能配置其它寄存器
                // 10'd0  : i2c_data <= {16'h300a, 8'h00};
                // 10'd1  : i2c_data <= {16'h300b, 8'h00};
                10'd0  : i2c_data <= {16'h3008, 8'h82};    //Bit[7]: 复位  Bit[6]: 电源休眠
                10'd1  : i2c_data <= {16'h3008, 8'h02};    //正常工作模式
                10'd2  : i2c_data <= {16'h3103, 8'h02};    //Bit[1]: 1 PLL Clock
                            //引脚输入/输出控制 FREX/VSYNC/HREF/PCLK/D[9:6]
                10'd3  : i2c_data <= {8'h30, 8'h17, 8'hff};
                            //引脚输入/输出控制 D[5:0]/GPIO1/GPIO0
                10'd4  : i2c_data <= {16'h3018, 8'hff};
                10'd5  : i2c_data <= {16'h3037, 8'h13};    //PLL分频控制
                10'd6  : i2c_data <= {16'h3108, 8'h01};    //系统根分频器
                10'd7  : i2c_data <= {16'h3630, 8'h36};
                10'd8  : i2c_data <= {16'h3631, 8'h0e};
                10'd9  : i2c_data <= {16'h3632, 8'he2};
                10'd10 : i2c_data <= {16'h3633, 8'h12};
                10'd11 : i2c_data <= {16'h3621, 8'he0};
                10'd12 : i2c_data <= {16'h3704, 8'ha0};
                10'd13 : i2c_data <= {16'h3703, 8'h5a};
                10'd14 : i2c_data <= {16'h3715, 8'h78};
                10'd15 : i2c_data <= {16'h3717, 8'h01};
                10'd16 : i2c_data <= {16'h370b, 8'h60};
                10'd17 : i2c_data <= {16'h3705, 8'h1a};
                10'd18 : i2c_data <= {16'h3905, 8'h02};
                10'd19 : i2c_data <= {16'h3906, 8'h10};
                10'd20 : i2c_data <= {16'h3901, 8'h0a};
                10'd21 : i2c_data <= {16'h3731, 8'h12};
                10'd22 : i2c_data <= {16'h3600, 8'h08};    //VCM控制, 用于自动聚焦
                10'd23 : i2c_data <= {16'h3601, 8'h33};    //VCM控制, 用于自动聚焦
                10'd24 : i2c_data <= {16'h302d, 8'h60};    //系统控制
                10'd25 : i2c_data <= {16'h3620, 8'h52};
                10'd26 : i2c_data <= {16'h371b, 8'h20};
                10'd27 : i2c_data <= {16'h471c, 8'h50};
                10'd28 : i2c_data <= {16'h3a13, 8'h43};    //AEC(自动曝光控制)
                10'd29 : i2c_data <= {16'h3a18, 8'h00};    //AEC 增益上限
                10'd30 : i2c_data <= {16'h3a19, 8'hf8};    //AEC 增益上限
                10'd31 : i2c_data <= {16'h3635, 8'h13};
                10'd32 : i2c_data <= {16'h3636, 8'h03};
                10'd33 : i2c_data <= {16'h3634, 8'h40};
                10'd34 : i2c_data <= {16'h3622, 8'h01};
                10'd35 : i2c_data <= {16'h3c01, 8'h34};
                10'd36 : i2c_data <= {16'h3c04, 8'h28};
                10'd37 : i2c_data <= {16'h3c05, 8'h98};
                10'd38 : i2c_data <= {16'h3c06, 8'h00};    //light meter 1 阈值[15:8]
                10'd39 : i2c_data <= {16'h3c07, 8'h08};    //light meter 1 阈值[7:0]
                10'd40 : i2c_data <= {16'h3c08, 8'h00};    //light meter 2 阈值[15:8]
                10'd41 : i2c_data <= {16'h3c09, 8'h1c};    //light meter 2 阈值[7:0]
                10'd42 : i2c_data <= {16'h3c0a, 8'h9c};    //sample number[15:8]
                10'd43 : i2c_data <= {16'h3c0b, 8'h40};    //sample number[7:0]
                10'd44 : i2c_data <= {16'h3810, 8'h00};    //Timing Hoffset[11:8]
                10'd45 : i2c_data <= {16'h3811, 8'h10};    //Timing Hoffset[7:0]
                10'd46 : i2c_data <= {16'h3812, 8'h00};    //Timing Voffset[10:8]
                10'd47 : i2c_data <= {16'h3708, 8'h64};
                10'd48 : i2c_data <= {16'h4001, 8'h02};    //BLC(黑电平校准)补偿起始行号
                10'd49 : i2c_data <= {16'h4005, 8'h1a};    //BLC(黑电平校准)补偿始终更新
                10'd50 : i2c_data <= {16'h3000, 8'h00};    //系统块复位控制
                10'd51 : i2c_data <= {16'h3004, 8'hff};    //时钟使能控制
                10'd52 : i2c_data <= {16'h4300, 8'h61};    //格式控制 RGB565
                10'd53 : i2c_data <= {16'h501f, 8'h01};    //ISP RGB
                10'd54 : i2c_data <= {16'h440e, 8'h00};
                10'd55 : i2c_data <= {16'h5000, 8'ha7};    //ISP控制
                10'd56 : i2c_data <= {16'h3a0f, 8'h30};    //AEC控制; stable range in high
                10'd57 : i2c_data <= {16'h3a10, 8'h28};    //AEC控制; stable range in low
                10'd58 : i2c_data <= {16'h3a1b, 8'h30};    //AEC控制; stable range out high
                10'd59 : i2c_data <= {16'h3a1e, 8'h26};    //AEC控制; stable range out low
                10'd60 : i2c_data <= {16'h3a11, 8'h60};    //AEC控制; fast zone high
                10'd61 : i2c_data <= {16'h3a1f, 8'h14};    //AEC控制; fast zone low
                            //LENC(镜头校正)控制 16'h5800~16'h583d
                10'd62 : i2c_data <= {16'h5800, 8'h23};
                10'd63 : i2c_data <= {16'h5801, 8'h14};
                10'd64 : i2c_data <= {16'h5802, 8'h0f};
                10'd65 : i2c_data <= {16'h5803, 8'h0f};
                10'd66 : i2c_data <= {16'h5804, 8'h12};
                10'd67 : i2c_data <= {16'h5805, 8'h26};
                10'd68 : i2c_data <= {16'h5806, 8'h0c};
                10'd69 : i2c_data <= {16'h5807, 8'h08};
                10'd70 : i2c_data <= {16'h5808, 8'h05};
                10'd71 : i2c_data <= {16'h5809, 8'h05};
                10'd72 : i2c_data <= {16'h580a, 8'h08};
                10'd73 : i2c_data <= {16'h580b, 8'h0d};
                10'd74 : i2c_data <= {16'h580c, 8'h08};
                10'd75 : i2c_data <= {16'h580d, 8'h03};
                10'd76 : i2c_data <= {16'h580e, 8'h00};
                10'd77 : i2c_data <= {16'h580f, 8'h00};
                10'd78 : i2c_data <= {16'h5810, 8'h03};
                10'd79 : i2c_data <= {16'h5811, 8'h09};
                10'd80 : i2c_data <= {16'h5812, 8'h07};
                10'd81 : i2c_data <= {16'h5813, 8'h03};
                10'd82 : i2c_data <= {16'h5814, 8'h00};
                10'd83 : i2c_data <= {16'h5815, 8'h01};
                10'd84 : i2c_data <= {16'h5816, 8'h03};
                10'd85 : i2c_data <= {16'h5817, 8'h08};
                10'd86 : i2c_data <= {16'h5818, 8'h0d};
                10'd87 : i2c_data <= {16'h5819, 8'h08};
                10'd88 : i2c_data <= {16'h581a, 8'h05};
                10'd89 : i2c_data <= {16'h581b, 8'h06};
                10'd90 : i2c_data <= {16'h581c, 8'h08};
                10'd91 : i2c_data <= {16'h581d, 8'h0e};
                10'd92 : i2c_data <= {16'h581e, 8'h29};
                10'd93 : i2c_data <= {16'h581f, 8'h17};
                10'd94 : i2c_data <= {16'h5820, 8'h11};
                10'd95 : i2c_data <= {16'h5821, 8'h11};
                10'd96 : i2c_data <= {16'h5822, 8'h15};
                10'd97 : i2c_data <= {16'h5823, 8'h28};
                10'd98 : i2c_data <= {16'h5824, 8'h46};
                10'd99 : i2c_data <= {16'h5825, 8'h26};
                10'd100: i2c_data <= {16'h5826, 8'h08};
                10'd101: i2c_data <= {16'h5827, 8'h26};
                10'd102: i2c_data <= {16'h5828, 8'h64};
                10'd103: i2c_data <= {16'h5829, 8'h26};
                10'd104: i2c_data <= {16'h582a, 8'h24};
                10'd105: i2c_data <= {16'h582b, 8'h22};
                10'd106: i2c_data <= {16'h582c, 8'h24};
                10'd107: i2c_data <= {16'h582d, 8'h24};
                10'd108: i2c_data <= {16'h582e, 8'h06};
                10'd109: i2c_data <= {16'h582f, 8'h22};
                10'd110: i2c_data <= {16'h5830, 8'h40};
                10'd111: i2c_data <= {16'h5831, 8'h42};
                10'd112: i2c_data <= {16'h5832, 8'h24};
                10'd113: i2c_data <= {16'h5833, 8'h26};
                10'd114: i2c_data <= {16'h5834, 8'h24};
                10'd115: i2c_data <= {16'h5835, 8'h22};
                10'd116: i2c_data <= {16'h5836, 8'h22};
                10'd117: i2c_data <= {16'h5837, 8'h26};
                10'd118: i2c_data <= {16'h5838, 8'h44};
                10'd119: i2c_data <= {16'h5839, 8'h24};
                10'd120: i2c_data <= {16'h583a, 8'h26};
                10'd121: i2c_data <= {16'h583b, 8'h28};
                10'd122: i2c_data <= {16'h583c, 8'h42};
                10'd123: i2c_data <= {16'h583d, 8'hce};
                            //AWB(自动白平衡控制) 16'h5180~16'h519e
                10'd124: i2c_data <= {16'h5180, 8'hff};
                10'd125: i2c_data <= {16'h5181, 8'hf2};
                10'd126: i2c_data <= {16'h5182, 8'h00};
                10'd127: i2c_data <= {16'h5183, 8'h14};
                10'd128: i2c_data <= {16'h5184, 8'h25};
                10'd129: i2c_data <= {16'h5185, 8'h24};
                10'd130: i2c_data <= {16'h5186, 8'h09};
                10'd131: i2c_data <= {16'h5187, 8'h09};
                10'd132: i2c_data <= {16'h5188, 8'h09};
                10'd133: i2c_data <= {16'h5189, 8'h75};
                10'd134: i2c_data <= {16'h518a, 8'h54};
                10'd135: i2c_data <= {16'h518b, 8'he0};
                10'd136: i2c_data <= {16'h518c, 8'hb2};
                10'd137: i2c_data <= {16'h518d, 8'h42};
                10'd138: i2c_data <= {16'h518e, 8'h3d};
                10'd139: i2c_data <= {16'h518f, 8'h56};
                10'd140: i2c_data <= {16'h5190, 8'h46};
                10'd141: i2c_data <= {16'h5191, 8'hf8};
                10'd142: i2c_data <= {16'h5192, 8'h04};
                10'd143: i2c_data <= {16'h5193, 8'h70};
                10'd144: i2c_data <= {16'h5194, 8'hf0};
                10'd145: i2c_data <= {16'h5195, 8'hf0};
                10'd146: i2c_data <= {16'h5196, 8'h03};
                10'd147: i2c_data <= {16'h5197, 8'h01};
                10'd148: i2c_data <= {16'h5198, 8'h04};
                10'd149: i2c_data <= {16'h5199, 8'h12};
                10'd150: i2c_data <= {16'h519a, 8'h04};
                10'd151: i2c_data <= {16'h519b, 8'h00};
                10'd152: i2c_data <= {16'h519c, 8'h06};
                10'd153: i2c_data <= {16'h519d, 8'h82};
                10'd154: i2c_data <= {16'h519e, 8'h38};
                            //Gamma(伽马)控制 16'h5480~16'h5490
                10'd155: i2c_data <= {16'h5480, 8'h01};
                10'd156: i2c_data <= {16'h5481, 8'h08};
                10'd157: i2c_data <= {16'h5482, 8'h14};
                10'd158: i2c_data <= {16'h5483, 8'h28};
                10'd159: i2c_data <= {16'h5484, 8'h51};
                10'd160: i2c_data <= {16'h5485, 8'h65};
                10'd161: i2c_data <= {16'h5486, 8'h71};
                10'd162: i2c_data <= {16'h5487, 8'h7d};
                10'd163: i2c_data <= {16'h5488, 8'h87};
                10'd164: i2c_data <= {16'h5489, 8'h91};
                10'd165: i2c_data <= {16'h548a, 8'h9a};
                10'd166: i2c_data <= {16'h548b, 8'haa};
                10'd167: i2c_data <= {16'h548c, 8'hb8};
                10'd168: i2c_data <= {16'h548d, 8'hcd};
                10'd169: i2c_data <= {16'h548e, 8'hdd};
                10'd170: i2c_data <= {16'h548f, 8'hea};
                10'd171: i2c_data <= {16'h5490, 8'h1d};
                            //CMX(彩色矩阵控制) 16'h5381~16'h538b
                10'd172: i2c_data <= {16'h5381, 8'h1e};
                10'd173: i2c_data <= {16'h5382, 8'h5b};
                10'd174: i2c_data <= {16'h5383, 8'h08};
                10'd175: i2c_data <= {16'h5384, 8'h0a};
                10'd176: i2c_data <= {16'h5385, 8'h7e};
                10'd177: i2c_data <= {16'h5386, 8'h88};
                10'd178: i2c_data <= {16'h5387, 8'h7c};
                10'd179: i2c_data <= {16'h5388, 8'h6c};
                10'd180: i2c_data <= {16'h5389, 8'h10};
                10'd181: i2c_data <= {16'h538a, 8'h01};
                10'd182: i2c_data <= {16'h538b, 8'h98};
                            //SDE(特殊数码效果)控制 16'h5580~16'h558b
                10'd183: i2c_data <= {16'h5580, 8'h06};
                10'd184: i2c_data <= {16'h5583, 8'h40};
                10'd185: i2c_data <= {16'h5584, 8'h10};
                10'd186: i2c_data <= {16'h5589, 8'h10};
                10'd187: i2c_data <= {16'h558a, 8'h00};
                10'd188: i2c_data <= {16'h558b, 8'hf8};
                10'd189: i2c_data <= {16'h501d, 8'h40};    //ISP MISC
                            //CIP(颜色插值)控制 (16'h5300~16'h530c)
                10'd190: i2c_data <= {16'h5300, 8'h08};
                10'd191: i2c_data <= {16'h5301, 8'h30};
                10'd192: i2c_data <= {16'h5302, 8'h10};
                10'd193: i2c_data <= {16'h5303, 8'h00};
                10'd194: i2c_data <= {16'h5304, 8'h08};
                10'd195: i2c_data <= {16'h5305, 8'h30};
                10'd196: i2c_data <= {16'h5306, 8'h08};
                10'd197: i2c_data <= {16'h5307, 8'h16};
                10'd198: i2c_data <= {16'h5309, 8'h08};
                10'd199: i2c_data <= {16'h530a, 8'h30};
                10'd200: i2c_data <= {16'h530b, 8'h04};
                10'd201: i2c_data <= {16'h530c, 8'h06};
                10'd202: i2c_data <= {16'h5025, 8'h00};
                            //系统时钟分频 Bit[7:4]:系统时钟分频 input clock = 24Mhz, PCLK = 48Mhz
                10'd203: i2c_data <= {16'h3035, 8'h11};
                10'd204: i2c_data <= {16'h3036, 8'h3c};    //PLL倍频
                10'd205: i2c_data <= {16'h3c07, 8'h08};
                            //时序控制 16'h3800~16'h3821
                10'd206: i2c_data <= {16'h3820, 8'h46};
                10'd207: i2c_data <= {16'h3821, 8'h01};
                10'd208: i2c_data <= {16'h3814, 8'h31};
                10'd209: i2c_data <= {16'h3815, 8'h31};
                10'd210: i2c_data <= {16'h3800, 8'h00};
                10'd211: i2c_data <= {16'h3801, 8'h00};
                10'd212: i2c_data <= {16'h3802, 8'h00};
                10'd213: i2c_data <= {16'h3803, 8'h04};
                10'd214: i2c_data <= {16'h3804, 8'h0a};
                10'd215: i2c_data <= {16'h3805, 8'h3f};
                10'd216: i2c_data <= {16'h3806, 8'h07};
                10'd217: i2c_data <= {16'h3807, 8'h9b};
                
                            //设置输出像素个数
                            //DVP 输出水平像素点数高4位
                10'd218: i2c_data <= {16'h3808, {4'd0, CMOS_H_PIXEL[11 : 8]}};
                            //DVP 输出水平像素点数低8位
                10'd219: i2c_data <= {16'h3809, CMOS_H_PIXEL[7 : 0]};
                            //DVP 输出垂直像素点数高3位
                10'd220: i2c_data <= {16'h380a, {5'd0, CMOS_V_PIXEL[10 : 8]}};
                            //DVP 输出垂直像素点数低8位
                10'd221: i2c_data <= {16'h380b, CMOS_V_PIXEL[7 : 0]};
                            //水平总像素大小高5位
                10'd222: i2c_data <= {16'h380c, {3'd0, TOTAL_H_PIXEL[12 : 8]}};
                            //水平总像素大小低8位
                10'd223: i2c_data <= {16'h380d, TOTAL_H_PIXEL[7 : 0]};
                            //垂直总像素大小高5位
                10'd224: i2c_data <= {16'h380e, {3'd0, TOTAL_V_PIXEL[12 : 8]}};
                            //垂直总像素大小低8位
                10'd225: i2c_data <= {16'h380f, TOTAL_V_PIXEL[7 : 0]};
                
                10'd226: i2c_data <= {16'h3813, 8'h06};
                10'd227: i2c_data <= {16'h3618, 8'h00};
                10'd228: i2c_data <= {16'h3612, 8'h29};
                10'd229: i2c_data <= {16'h3709, 8'h52};
                10'd230: i2c_data <= {16'h370c, 8'h03};
                10'd231: i2c_data <= {16'h3a02, 8'h17};    //60Hz max exposure 
                10'd232: i2c_data <= {16'h3a03, 8'h10};    //60Hz max exposure
                10'd233: i2c_data <= {16'h3a14, 8'h17};    //50Hz max exposure
                10'd234: i2c_data <= {16'h3a15, 8'h10};    //50Hz max exposure
                10'd235: i2c_data <= {16'h4004, 8'h02};    //BLC(背光) 2 lines
                10'd236: i2c_data <= {16'h4713, 8'h03};    //JPEG mode 3
                10'd237: i2c_data <= {16'h4407, 8'h04};    //量化标度
                10'd238: i2c_data <= {16'h460c, 8'h22};        
                10'd239: i2c_data <= {16'h4837, 8'h22};    //DVP CLK divider
                10'd240: i2c_data <= {16'h3824, 8'h02};    //DVP CLK divider
                10'd241: i2c_data <= {16'h5001, 8'ha3};    //ISP 控制
                10'd242: i2c_data <= {16'h3b07, 8'h0a};    //帧曝光模式  
                            //彩条测试使能    
                10'd243: i2c_data <= {16'h503d, 8'h00};    //8'h00:正常模式, 8'h80:彩条显示
                            //测试闪光灯功能
                10'd244: i2c_data <= {16'h3016, 8'h02};
                10'd245: i2c_data <= {16'h301c, 8'h02};
                10'd246: i2c_data <= {16'h3019, 8'h02};    //打开闪光灯
                10'd247: i2c_data <= {16'h3019, 8'h00};    //关闭闪光灯
                            //只读存储器, 防止在case中没有列举的情况, 之前的寄存器被重复改写
                default: i2c_data <= {16'h300a, 8'h00};   //器件ID高8位
            endcase
        end
    end
    
    /*
    //配置寄存器地址与数据
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            i2c_data <= 24'd0;
        end
        else
        begin
            case(init_reg_cnt)
                10'd0  : i2c_data <= {16'h3103, 8'h11};// system clock from pad, bit[1]
                10'd1  : i2c_data <= {16'h3008, 8'h82};// software reset, bit[7]// delay 5ms 
                10'd2  : i2c_data <= {16'h3008, 8'h42};// software power down, bit[6]
                10'd3  : i2c_data <= {16'h3103, 8'h03};// system clock from PLL, bit[1]
                10'd4  : i2c_data <= {16'h3017, 8'hff};// FREX, Vsync, HREF, PCLK, D[9:6] output enable
                10'd5  : i2c_data <= {16'h3018, 8'hff};// D[5:0], GPIO[1:0] output enable
                10'd6  : i2c_data <= {16'h3034, 8'h1A};// MIPI 10-bit
                10'd7  : i2c_data <= {16'h3037, 8'h13};// PLL root divider, bit[4], PLL pre-divider, bit[3:0]
                10'd8  : i2c_data <= {16'h3108, 8'h01};// PCLK root divider, bit[5:4], SCLK2x root divider, bit[3:2] // SCLK root divider, bit[1:0] 
                10'd9  : i2c_data <= {16'h3630, 8'h36};
                10'd10 : i2c_data <= {16'h3631, 8'h0e};
                10'd11 : i2c_data <= {16'h3632, 8'he2};
                10'd12 : i2c_data <= {16'h3633, 8'h12};
                10'd13 : i2c_data <= {16'h3621, 8'he0};
                10'd14 : i2c_data <= {16'h3704, 8'ha0};
                10'd15 : i2c_data <= {16'h3703, 8'h5a};
                10'd16 : i2c_data <= {16'h3715, 8'h78};
                10'd17 : i2c_data <= {16'h3717, 8'h01};
                10'd18 : i2c_data <= {16'h370b, 8'h60};
                10'd19 : i2c_data <= {16'h3705, 8'h1a};
                10'd20 : i2c_data <= {16'h3905, 8'h02};
                10'd21 : i2c_data <= {16'h3906, 8'h10};
                10'd22 : i2c_data <= {16'h3901, 8'h0a};
                10'd23 : i2c_data <= {16'h3731, 8'h12};
                10'd24 : i2c_data <= {16'h3600, 8'h08};// VCM control
                10'd25 : i2c_data <= {16'h3601, 8'h33};// VCM control
                10'd26 : i2c_data <= {16'h302d, 8'h60};// system control
                10'd27 : i2c_data <= {16'h3620, 8'h52};
                10'd28 : i2c_data <= {16'h371b, 8'h20};
                10'd29 : i2c_data <= {16'h471c, 8'h50};
                10'd30 : i2c_data <= {16'h3a13, 8'h43};// pre-gain = 1.047x
                10'd31 : i2c_data <= {16'h3a18, 8'h00};// gain ceiling
                10'd32 : i2c_data <= {16'h3a19, 8'hf8};// gain ceiling = 15.5x
                10'd33 : i2c_data <= {16'h3635, 8'h13};
                10'd34 : i2c_data <= {16'h3636, 8'h03};
                10'd35 : i2c_data <= {16'h3634, 8'h40};
                10'd36 : i2c_data <= {16'h3622, 8'h01};// 50/60Hz detection     50/60Hz 
                10'd37 : i2c_data <= {16'h3c01, 8'h34};// Band auto, bit[7]
                10'd38 : i2c_data <= {16'h3c04, 8'h28};// threshold low sum	 
                10'd39 : i2c_data <= {16'h3c05, 8'h98};// threshold high sum
                10'd40 : i2c_data <= {16'h3c06, 8'h00};// light meter 1 threshold[15:8]
                10'd41 : i2c_data <= {16'h3c07, 8'h08};// light meter 1 threshold[7:0]
                10'd42 : i2c_data <= {16'h3c08, 8'h00};// light meter 2 threshold[15:8]
                10'd43 : i2c_data <= {16'h3c09, 8'h1c};// light meter 2 threshold[7:0]
                10'd44 : i2c_data <= {16'h3c0a, 8'h9c};// sample number[15:8]
                10'd45 : i2c_data <= {16'h3c0b, 8'h40};// sample number[7:0]
                10'd46 : i2c_data <= {16'h3810, 8'h00};// Timing Hoffset[11:8]
                10'd47 : i2c_data <= {16'h3811, 8'h10};// Timing Hoffset[7:0]
                10'd48 : i2c_data <= {16'h3812, 8'h00};// Timing Voffset[10:8] 
                10'd49 : i2c_data <= {16'h3708, 8'h64};
                10'd50 : i2c_data <= {16'h4001, 8'h02};// BLC start from line 2
                10'd51 : i2c_data <= {16'h4005, 8'h1a};// BLC always update
                10'd52 : i2c_data <= {16'h3000, 8'h00};// enable blocks
                10'd53 : i2c_data <= {16'h3004, 8'hff};// enable clocks 
                10'd54 : i2c_data <= {16'h300e, 8'h58};// MIPI power down, DVP enable
                10'd55 : i2c_data <= {16'h302e, 8'h00};
                10'd56 : i2c_data <= {16'h4300, 8'h61};// RGB565
                10'd57 : i2c_data <= {16'h501f, 8'h01};// ISP RGB 
                10'd58 : i2c_data <= {16'h440e, 8'h00};
                10'd59 : i2c_data <= {16'h5000, 8'ha7};// Lenc on, raw gamma on, BPC on, WPC on, CIP on // AEC target
                10'd60 : i2c_data <= {16'h3a0f, 8'h30};// stable range in high
                10'd61 : i2c_data <= {16'h3a10, 8'h28};// stable range in low
                10'd62 : i2c_data <= {16'h3a1b, 8'h30};// stable range out high
                10'd63 : i2c_data <= {16'h3a1e, 8'h26};// stable range out low
                10'd64 : i2c_data <= {16'h3a11, 8'h60};// fast zone high
                10'd65 : i2c_data <= {16'h3a1f, 8'h14};// fast zone low// Lens correction for
                10'd66 : i2c_data <= {16'h5800, 8'h23};
                10'd67 : i2c_data <= {16'h5801, 8'h14};
                10'd68 : i2c_data <= {16'h5802, 8'h0f};
                10'd69 : i2c_data <= {16'h5803, 8'h0f};
                10'd70 : i2c_data <= {16'h5804, 8'h12};
                10'd71 : i2c_data <= {16'h5805, 8'h26};
                10'd72 : i2c_data <= {16'h5806, 8'h0c};
                10'd73 : i2c_data <= {16'h5807, 8'h08};
                10'd74 : i2c_data <= {16'h5808, 8'h05};
                10'd75 : i2c_data <= {16'h5809, 8'h05};
                10'd76 : i2c_data <= {16'h580a, 8'h08};
                10'd77 : i2c_data <= {16'h580b, 8'h0d};
                10'd78 : i2c_data <= {16'h580c, 8'h08};
                10'd79 : i2c_data <= {16'h580d, 8'h03};
                10'd80 : i2c_data <= {16'h580e, 8'h00};
                10'd81 : i2c_data <= {16'h580f, 8'h00};
                10'd82 : i2c_data <= {16'h5810, 8'h03};
                10'd83 : i2c_data <= {16'h5811, 8'h09};
                10'd84 : i2c_data <= {16'h5812, 8'h07};
                10'd85 : i2c_data <= {16'h5813, 8'h03};
                10'd86 : i2c_data <= {16'h5814, 8'h00};
                10'd87 : i2c_data <= {16'h5815, 8'h01};
                10'd88 : i2c_data <= {16'h5816, 8'h03};
                10'd89 : i2c_data <= {16'h5817, 8'h08};
                10'd90 : i2c_data <= {16'h5818, 8'h0d};
                10'd91 : i2c_data <= {16'h5819, 8'h08};
                10'd92 : i2c_data <= {16'h581a, 8'h05};
                10'd93 : i2c_data <= {16'h581b, 8'h06};
                10'd94 : i2c_data <= {16'h581c, 8'h08};
                10'd95 : i2c_data <= {16'h581d, 8'h0e};
                10'd96 : i2c_data <= {16'h581e, 8'h29};
                10'd97 : i2c_data <= {16'h581f, 8'h17};
                10'd98 : i2c_data <= {16'h5820, 8'h11};
                10'd99 : i2c_data <= {16'h5821, 8'h11};
                10'd100: i2c_data <= {16'h5822, 8'h15};
                10'd101: i2c_data <= {16'h5823, 8'h28};
                10'd102: i2c_data <= {16'h5824, 8'h46};
                10'd103: i2c_data <= {16'h5825, 8'h26};
                10'd104: i2c_data <= {16'h5826, 8'h08};
                10'd105: i2c_data <= {16'h5827, 8'h26};
                10'd106: i2c_data <= {16'h5828, 8'h64};
                10'd107: i2c_data <= {16'h5829, 8'h26};
                10'd108: i2c_data <= {16'h582a, 8'h24};
                10'd109: i2c_data <= {16'h582b, 8'h22};
                10'd110: i2c_data <= {16'h582c, 8'h24};
                10'd111: i2c_data <= {16'h582d, 8'h24};
                10'd112: i2c_data <= {16'h582e, 8'h06};
                10'd113: i2c_data <= {16'h582f, 8'h22};
                10'd114: i2c_data <= {16'h5830, 8'h40};
                10'd115: i2c_data <= {16'h5831, 8'h42};
                10'd116: i2c_data <= {16'h5832, 8'h24};
                10'd117: i2c_data <= {16'h5833, 8'h26};
                10'd118: i2c_data <= {16'h5834, 8'h24};
                10'd119: i2c_data <= {16'h5835, 8'h22};
                10'd120: i2c_data <= {16'h5836, 8'h22};
                10'd121: i2c_data <= {16'h5837, 8'h26};
                10'd122: i2c_data <= {16'h5838, 8'h44};
                10'd123: i2c_data <= {16'h5839, 8'h24};
                10'd124: i2c_data <= {16'h583a, 8'h26};
                10'd125: i2c_data <= {16'h583b, 8'h28};
                10'd126: i2c_data <= {16'h583c, 8'h42};
                10'd127: i2c_data <= {16'h583d, 8'hce};// lenc BR offset
                10'd128: i2c_data <= {16'h5180, 8'hff};// AWB B block
                10'd129: i2c_data <= {16'h5181, 8'hf2};// AWB control 
                10'd130: i2c_data <= {16'h5182, 8'h00};// [7:4] max local counter, [3:0] max fast counter
                10'd131: i2c_data <= {16'h5183, 8'h14};// AWB advanced 
                10'd132: i2c_data <= {16'h5184, 8'h25};
                10'd133: i2c_data <= {16'h5185, 8'h24};
                10'd134: i2c_data <= {16'h5186, 8'h09};
                10'd135: i2c_data <= {16'h5187, 8'h09};
                10'd136: i2c_data <= {16'h5188, 8'h09};
                10'd137: i2c_data <= {16'h5189, 8'h75};
                10'd138: i2c_data <= {16'h518a, 8'h54};
                10'd139: i2c_data <= {16'h518b, 8'he0};
                10'd140: i2c_data <= {16'h518c, 8'hb2};
                10'd141: i2c_data <= {16'h518d, 8'h42};
                10'd142: i2c_data <= {16'h518e, 8'h3d};
                10'd143: i2c_data <= {16'h518f, 8'h56};
                10'd144: i2c_data <= {16'h5190, 8'h46};
                10'd145: i2c_data <= {16'h5191, 8'hf8};// AWB top limit
                10'd146: i2c_data <= {16'h5192, 8'h04};// AWB bottom limit
                10'd147: i2c_data <= {16'h5193, 8'h70};// red limit
                10'd148: i2c_data <= {16'h5194, 8'hf0};// green limit
                10'd149: i2c_data <= {16'h5195, 8'hf0};// blue limit
                10'd150: i2c_data <= {16'h5196, 8'h03};// AWB control
                10'd151: i2c_data <= {16'h5197, 8'h01};// local limit 
                10'd152: i2c_data <= {16'h5198, 8'h04};
                10'd153: i2c_data <= {16'h5199, 8'h12};
                10'd154: i2c_data <= {16'h519a, 8'h04};
                10'd155: i2c_data <= {16'h519b, 8'h00};
                10'd156: i2c_data <= {16'h519c, 8'h06};
                10'd157: i2c_data <= {16'h519d, 8'h82};
                10'd158: i2c_data <= {16'h519e, 8'h38};// AWB control
                10'd159: i2c_data <= {16'h5480, 8'h01};// Gamma bias plus on, bit[0] 
                10'd160: i2c_data <= {16'h5481, 8'h08};
                10'd161: i2c_data <= {16'h5482, 8'h14};
                10'd162: i2c_data <= {16'h5483, 8'h28};
                10'd163: i2c_data <= {16'h5484, 8'h51};
                10'd164: i2c_data <= {16'h5485, 8'h65};
                10'd165: i2c_data <= {16'h5486, 8'h71};
                10'd166: i2c_data <= {16'h5487, 8'h7d};
                10'd167: i2c_data <= {16'h5488, 8'h87};
                10'd168: i2c_data <= {16'h5489, 8'h91};
                10'd169: i2c_data <= {16'h548a, 8'h9a};
                10'd170: i2c_data <= {16'h548b, 8'haa};
                10'd171: i2c_data <= {16'h548c, 8'hb8};
                10'd172: i2c_data <= {16'h548d, 8'hcd};
                10'd173: i2c_data <= {16'h548e, 8'hdd};
                10'd174: i2c_data <= {16'h548f, 8'hea};
                10'd175: i2c_data <= {16'h5490, 8'h1d};// color matrix  
                10'd176: i2c_data <= {16'h5381, 8'h1e};// CMX1 for Y
                10'd177: i2c_data <= {16'h5382, 8'h5b};// CMX2 for Y
                10'd178: i2c_data <= {16'h5383, 8'h08};// CMX3 for Y
                10'd179: i2c_data <= {16'h5384, 8'h0a};// CMX4 for U
                10'd180: i2c_data <= {16'h5385, 8'h7e};// CMX5 for U
                10'd181: i2c_data <= {16'h5386, 8'h88};// CMX6 for U
                10'd182: i2c_data <= {16'h5387, 8'h7c};// CMX7 for V
                10'd183: i2c_data <= {16'h5388, 8'h6c};// CMX8 for V
                10'd184: i2c_data <= {16'h5389, 8'h10};// CMX9 for V
                10'd185: i2c_data <= {16'h538a, 8'h01};// sign[9]
                10'd186: i2c_data <= {16'h538b, 8'h98};// sign[8:1] // UV adjust   
                10'd187: i2c_data <= {16'h5580, 8'h06};// saturation on, bit[1]
                10'd188: i2c_data <= {16'h5583, 8'h40};
                10'd189: i2c_data <= {16'h5584, 8'h10};
                10'd190: i2c_data <= {16'h5589, 8'h10};
                10'd191: i2c_data <= {16'h558a, 8'h00};
                10'd192: i2c_data <= {16'h558b, 8'hf8};
                10'd193: i2c_data <= {16'h501d, 8'h40};// enable manual offset of contrast
                10'd194: i2c_data <= {16'h5300, 8'h08};// CIP sharpen MT threshold 1
                10'd195: i2c_data <= {16'h5301, 8'h30};// CIP sharpen MT threshold 2
                10'd196: i2c_data <= {16'h5302, 8'h10};// CIP sharpen MT offset 1
                10'd197: i2c_data <= {16'h5303, 8'h00};// CIP sharpen MT offset 2
                10'd198: i2c_data <= {16'h5304, 8'h08};// CIP DNS threshold 1
                10'd199: i2c_data <= {16'h5305, 8'h30};// CIP DNS threshold 2
                10'd200: i2c_data <= {16'h5306, 8'h08};// CIP DNS offset 1
                10'd201: i2c_data <= {16'h5307, 8'h16};// CIP DNS offset 2 
                10'd202: i2c_data <= {16'h5309, 8'h08};// CIP sharpen TH threshold 1
                10'd203: i2c_data <= {16'h530a, 8'h30};// CIP sharpen TH threshold 2
                10'd204: i2c_data <= {16'h530b, 8'h04};// CIP sharpen TH offset 1
                10'd205: i2c_data <= {16'h530c, 8'h06};// CIP sharpen TH offset 2
                10'd206: i2c_data <= {16'h5025, 8'h00};
                10'd207: i2c_data <= {16'h3008, 8'h02};// wake up from standby, bit[6]
                10'd208: i2c_data <= {16'h3035, 8'h11};// PLL
                10'd209: i2c_data <= {16'h3036, 8'h46};// PLL
                10'd210: i2c_data <= {16'h3c07, 8'h08};// light meter 1 threshold [7:0]
                10'd211: i2c_data <= {16'h3820, 8'h47};// Sensor flip off, ISP flip on
                10'd212: i2c_data <= {16'h3821, 8'h01};// Sensor mirror on, ISP mirror on, H binning on
                10'd213: i2c_data <= {16'h3814, 8'h31};// X INC 
                10'd214: i2c_data <= {16'h3815, 8'h31};// Y INC
                10'd215: i2c_data <= {16'h3800, 8'h00};// HS: X address start high byte
                10'd216: i2c_data <= {16'h3801, 8'h00};// HS: X address start low byte
                10'd217: i2c_data <= {16'h3802, 8'h00};// VS: Y address start high byte
                10'd218: i2c_data <= {16'h3803, 8'h04};// VS: Y address start high byte 
                10'd219: i2c_data <= {16'h3804, 8'h0a};// HW (HE)         
                10'd220: i2c_data <= {16'h3805, 8'h3f};// HW (HE)
                10'd221: i2c_data <= {16'h3806, 8'h07};// VH (VE)         
                10'd222: i2c_data <= {16'h3807, 8'h9b};// VH (VE)      
                10'd223: i2c_data <= {16'h3808, 8'h01};// DVPHO           //480
                10'd224: i2c_data <= {16'h3809, 8'he0};// DVPHO
                10'd225: i2c_data <= {16'h380a, 8'h01};// DVPVO           //272
                10'd226: i2c_data <= {16'h380b, 8'h10};// DVPVO
                10'd227: i2c_data <= {16'h380c, 8'h07};// HTS            //Total horizontal size 
                10'd228: i2c_data <= {16'h380d, 8'h68};// HTS
                10'd229: i2c_data <= {16'h380e, 8'h03};// VTS            //total vertical size
                10'd230: i2c_data <= {16'h380f, 8'hd8};// VTS 
                10'd231: i2c_data <= {16'h3813, 8'h06};// Timing Voffset 
                10'd232: i2c_data <= {16'h3618, 8'h00};
                10'd233: i2c_data <= {16'h3612, 8'h29};
                10'd234: i2c_data <= {16'h3709, 8'h52};
                10'd235: i2c_data <= {16'h370c, 8'h03}; 
                10'd236: i2c_data <= {16'h3a02, 8'h17};// 60Hz max exposure, night mode 5fps
                10'd237: i2c_data <= {16'h3a03, 8'h10};// 60Hz max exposure // banding filters are calculated automatically in camera driver
                10'd238: i2c_data <= {16'h3a14, 8'h17};// 50Hz max exposure, night mode 5fps
                10'd239: i2c_data <= {16'h3a15, 8'h10};// 50Hz max exposure     
                10'd240: i2c_data <= {16'h4004, 8'h02};// BLC 2 lines 
                10'd241: i2c_data <= {16'h3002, 8'h1c};// reset JFIFO, SFIFO, JPEG
                10'd242: i2c_data <= {16'h3006, 8'hc3};// disable clock of JPEG2x, JPEG
                10'd243: i2c_data <= {16'h4713, 8'h03};// JPEG mode 3
                10'd244: i2c_data <= {16'h4407, 8'h04};// Quantization scale 
                10'd245: i2c_data <= {16'h460b, 8'h35};
                10'd246: i2c_data <= {16'h460c, 8'h22};
                10'd247: i2c_data <= {16'h4837, 8'h22};// DVP CLK divider
                10'd248: i2c_data <= {16'h3824, 8'h02};// DVP CLK divider 
                10'd249: i2c_data <= {16'h5001, 8'ha3};// SDE on, scale on, UV average off, color matrix on, AWB on
                10'd250: i2c_data <= {16'h3503, 8'h00};// AEC/AGC on 
                10'd251: i2c_data <= {16'h3016, 8'h02};// Strobe output enable
                10'd252: i2c_data <= {16'h3b07, 8'h0a};// FREX strobe mode1		  
                10'd253: i2c_data <= {16'h3b00, 8'h83};// STROBE CTRL: strobe request ON, Strobe mode: LED3 
                10'd254: i2c_data <= {16'h3b00, 8'h00};// STROBE CTRL: strobe request OFF
                10'd255: i2c_data <= {16'h300a, 8'h00};
                default: i2c_data <= {16'h300a, 8'h00};
            endcase
        end
    end
    */    

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