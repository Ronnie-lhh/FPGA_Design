// ********************************************************************************* 
// 文件名: ov5640_sdram_lcd_proc.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.27
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: ov5640_sdram_lcd_proc
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)图像实时采集处理系统的顶层模块   
//            2)OV5640摄像头采集, IIC配置, SDRAM存储, 输出RGB888到LCD显示
//             3)灰度图显示, 图像二值化, 灰度图中值滤波, Sobel边缘检测
//              4)根据按键输入切换显示各种算法处理结果
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
parameter   SLAVE_ADDR    = 7'h3c;              //OV5640的器件地址为7'h3c
parameter   BIT_CTRL      = 1'b1;               //OV5640的字节地址为16位, 8位(0)/16位(1)
parameter   CLK_FREQ      = 27'd100_000_000;    //i2c_controller模块的驱动时钟频率
parameter   I2C_FREQ      = 18'd250_000;        //I2C的SCL时钟频率, 不超过400KHz

parameter   CMOS_H_PIXEL  = 13'd480;            //CMOS水平方向像素个数
parameter   CMOS_V_PIXEL  = 13'd272;            //CMOS垂直方向像素个数
parameter   TOTAL_H_PIXEL = 13'd1800;           //水平总像素大小
parameter   TOTAL_V_PIXEL = 13'd1000;           //垂直总像素大小
parameter   CMOS_HV_SIZE  = 24'd130560;         //CMOS输出图像的大小, CMOS_H_PIXEL * CMOS_V_PIXEL
                                                //用于配置写SDRAM的最大地址

// ---------------------------------------------------------------------------------
// 模块定义 Module Define
// --------------------------------------------------------------------------------- 
module ov5640_sdram_lcd_proc
(
    // clock & reset
    input 			    sys_clk,	            //系统时钟信号, 50MHz
    input               key_rst_n,              //按键复位信号, 低电平有效
    
    // 按键接口
    input      [ 3 : 0] key,                    //按键输入, 控制切换显示多种图像处理结果

    // 摄像头接口
    input               cam_pclk,               //CMOS 数据像素时钟
    input               cam_vsync,              //CMOS 场同步信号
    input               cam_href,               //CMOS 行同步信号
    input      [ 7 : 0] cam_data,               //CMOS 数据
    output              cam_xclk,               //CMOS 外部时钟
    output              cam_rst_n,              //CMOS 硬件复位信号, 低电平有效
    output              cam_pwdn,               //CMOS 电源休眠模式选择信号
    output              cam_scl,                //CMOS SCCB_SCL线
    inout               cam_sda,                //CMOS SCCB_SDA线
    
    // SDRAM接口
    output              sdram_clk,              //SDRAM 芯片时钟信号
    output              sdram_cke,              //SDRAM 时钟有效信号
    output              sdram_cs_n,             //SDRAM 片选信号
    output              sdram_ras_n,            //SDRAM 行地址选通信号
    output              sdram_cas_n,            //SDRAM 列地址选通信号
    output              sdram_we_n,             //SDRAM 写允许
    output     [ 1 : 0] sdram_ba,               //SDRAM L-Bank地址线
    output     [12 : 0] sdram_addr,             //SDRAM 地址总线
    output     [ 1 : 0] sdram_dqm,              //SDRAM 数据掩码
    inout      [15 : 0] sdram_data,             //SDRAM 数据总线
    
    // LCD接口
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
    wire                sys_clk_bufg;           //经IBUFG后输出的系统时钟, 50MHz
    wire                clk_100m_sdram;         //SDRAM操作时钟, 100MHz
    wire                clk_100m_sdram_shift;   //SDRAM相位偏移时钟, 100MHz, 偏移-75度
    wire                clk_100m_lcd;           //LCD顶层模块时钟, 100MHz
    wire                clk_10m_lcd;            //LCD驱动时钟, 10MHz
    wire                clk_24m_cmos;           //CMOS外部时钟, 24MHz
    wire                locked;                 //PLL稳定输出标志
    wire                sys_rst_n;              //系统复位信号
    wire                sys_init_done;          //系统初始化完成(SDRAM初始化+摄像头初始化)
    
    wire                i2c_dri_clk;            //I2C驱动时钟
    wire                i2c_exec;               //I2C触发执行信号
    wire                i2c_rw_ctrl;            //I2C读写控制信号, 读(1)/写(0)
    wire                i2c_done;               //I2C一个寄存器配置完成信号
    wire       [ 7 : 0] i2c_rd_data;            //I2C读出的数据
    wire       [23 : 0] i2c_data;               //I2C要配置的地址与数据, 地址(高16位)/数据(低8位)
    wire                cam_init_done;          //摄像头初始化完成信号
    
    wire                lcd_data_req;           //LCD请求像素点颜色数据输入
    wire       [15 : 0] pixel_data;             //用于LCD显示的RGB565格式的像素点数据
    wire                sdram_init_done;        //SDRAM初始化完成
    
    wire                cmos_frame_vsync;       //CMOS帧有效信号
    wire                cmos_frame_href;        //CMOS行有效信号
    wire                cmos_frame_valid;       //CMOS数据有效使能信号
    wire       [15 : 0] cmos_frame_data;        //CMOS有效数据, RGB565格式
    
    wire                proc_cmos_frame_vsync;  //经图像处理后的CMOS帧有效信号
    wire                proc_cmos_frame_href;   //经图像处理后的CMOS行有效信号
    wire                proc_cmos_frame_valid;  //经图像处理后的CMOS数据有效使能信号
    wire       [15 : 0] proc_cmos_frame_data;   //经图像处理后的CMOS图像数据
    
    wire       [ 3 : 0] key_cmd;                //根据按键输入产生的指令
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// ---------------------------------------------------------------------------------    
    //待PLL输出稳定之后, 停止系统复位
    assign  sys_rst_n = key_rst_n & locked;
    
    //系统初始化完成：SDRAM和摄像头都初始化完成
    //避免在SDRAM初始化过程中向里面写入数据
    assign  sys_init_done = sdram_init_done & cam_init_done;
    
    //电源休眠模式选择, 正常模式(0)/电源休眠模式(1)
    assign  cam_pwdn = 1'b0;
    
    //不对摄像头硬件复位, 固定高电平
    assign  cam_rst_n = 1'b1;
    
    //CMOS外部时钟, 24MHz
    assign  cam_xclk = clk_24m_cmos;
    
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
    
    // PLL 例化
    sys_pll     U_sys_pll
    (
        // clock & reset
        .clk_in                 (sys_clk_bufg),
        .areset                 (~key_rst_n),

        .clk_out1               (clk_100m_sdram),
        .clk_out2               (clk_100m_sdram_shift),
        .clk_out3               (clk_100m_lcd),
        .clk_out4               (clk_10m_lcd),
        .clk_out5               (clk_24m_cmos),
        .locked                 (locked)
    );
    
    // LCD 顶层模块例化
    lcd_top     U_lcd_top
    (
        // clock & reset
        .clk	                (clk_100m_lcd),
        .lcd_clk                (clk_10m_lcd),
        .rst_n                  (sys_rst_n),

        // input signal
        .pixel_data             (pixel_data),

        // output signal
        .lcd_data_req           (lcd_data_req),

        // LCD 接口
        .lcd_de                 (lcd_de),
        .lcd_hs                 (lcd_hs),
        .lcd_vs                 (lcd_vs),
        .lcd_bl                 (lcd_bl),
        .lcd_rst                (lcd_rst),
        .lcd_dclk               (lcd_dclk),
        .lcd_r                  (lcd_r),
        .lcd_g                  (lcd_g),
        .lcd_b                  (lcd_b)
    );
    
    // IIC 配置模块
    i2c_ov5640_rgb565_cfg
    #(
        // parameter passing
        .CMOS_H_PIXEL           (CMOS_H_PIXEL),
        .CMOS_V_PIXEL           (CMOS_V_PIXEL),
        .TOTAL_H_PIXEL          (TOTAL_H_PIXEL),
        .TOTAL_V_PIXEL          (TOTAL_V_PIXEL),
        .CMOS_HV_SIZE           (CMOS_HV_SIZE)
    )
    U_i2c_ov5640_rgb565_cfg
    (
        // clock & reset
        .clk	                (i2c_dri_clk),
        .rst_n  		        (sys_rst_n),

        // input signal
        .i2c_done               (i2c_done),
        .i2c_rd_data            (i2c_rd_data),

        // output signal
        .i2c_exec               (i2c_exec),
        .i2c_init_done          (cam_init_done),
        .i2c_rw_ctrl            (i2c_rw_ctrl),
        .i2c_data               (i2c_data)
    );
    
    // IIC 驱动模块
    i2c_controller
    #(
        // parameter passing
        .SLAVE_ADDR             (SLAVE_ADDR),
        .CLK_FREQ               (CLK_FREQ),
        .I2C_FREQ               (I2C_FREQ)
    )
    U_i2c_controller
    (
        // clock & reset
        .clk                    (clk_100m_lcd),
        .rst_n	                (sys_rst_n),

        // i2c interface
        .i2c_exec               (i2c_exec),
        .bit_ctrl               (BIT_CTRL),
        .i2c_rw_ctrl            (i2c_rw_ctrl),
        .i2c_addr               (i2c_data[23 : 8]),
        .i2c_wr_data            (i2c_data[ 7 : 0]),
        .i2c_rd_data            (i2c_rd_data),
        .i2c_done               (i2c_done),
        .scl                    (cam_scl),
        .sda                    (cam_sda),

        // user interface
        .clk_dri                (i2c_dri_clk)
    );
    
    // CMOS图像数据采集模块
    cmos_capture_data       U_cmos_capture_data
    (
        // clock & reset
        .rst_n  		        (sys_rst_n & sys_init_done),    //系统初始化完成后再开始采集数据

        // 摄像头接口
        .cam_pclk               (cam_pclk),
        .cam_vsync              (cam_vsync),
        .cam_href               (cam_href),
        .cam_data               (cam_data),

        // 用户接口
        .cmos_frame_vsync       (cmos_frame_vsync),
        .cmos_frame_href        (cmos_frame_href),
        .cmos_frame_valid       (cmos_frame_valid),
        .cmos_frame_data        (cmos_frame_data)
    );
    
    // 按键指令控制模块
    key_ctrl        U_key_ctrl
    (
        // clock & reset
        .clk                    (cam_pclk),
        .rst_n                  (sys_rst_n),

        // input signal
        .key                    (key),

        // output signal
        .key_cmd                (key_cmd)
    );
    
    // 图像处理算法模块
    video_image_processor       U_video_image_processor
    (
        // clock & reset
        .clk	                (cam_pclk),
        .rst_n                  (sys_rst_n),

        // input signal
        .key_cmd                (key_cmd),
        
        // 预处理图像接口
        .pre_img_vs             (cmos_frame_vsync),
        .pre_img_hs             (cmos_frame_href),
        .pre_img_de             (cmos_frame_valid),
        .pre_img_data           (cmos_frame_data),

        // output signal
        // 处理后图像接口
        .proc_img_vs            (proc_cmos_frame_vsync),
        .proc_img_hs            (proc_cmos_frame_href),
        .proc_img_de            (proc_cmos_frame_valid),
        .proc_img_data          (proc_cmos_frame_data)
    );
    
    // SDRAM 控制器顶层模块, 封装成FIFO接口
    // SDRAM 控制器地址组成, {bank_addr[1:0], row_addr[12:0], col_addr[8:0]}
    sdram_top       U_sdram_top
    (
        // clock & reset
        .ref_clk	            (clk_100m_sdram),
        .out_clk                (clk_100m_sdram_shift),
        .rst_n 		            (sys_rst_n),

        // 用户写端口
        .wr_clk                 (cam_pclk),
        .wr_en                  (proc_cmos_frame_valid),
        .wr_data                (proc_cmos_frame_data),
        .wr_min_addr            (24'd0),
        .wr_max_addr            (CMOS_HV_SIZE),
        .wr_len                 (10'd512),
        .wr_load                (~sys_rst_n),

        // 用户读端口
        .rd_clk                 (clk_10m_lcd),
        .rd_en                  (lcd_data_req),
        .rd_data                (pixel_data),
        .rd_min_addr            (24'd0),
        .rd_max_addr            (CMOS_HV_SIZE),
        .rd_len                 (10'd512),
        .rd_load                (~sys_rst_n),

        // 用户控制端口
        .sdram_read_valid       (1'b1),
        .sdram_pingpang_en      (1'b1),
        .sdram_init_done        (sdram_init_done),

        // SDRAM芯片硬件接口
        .sdram_clk              (sdram_clk),
        .sdram_cke              (sdram_cke),
        .sdram_cs_n             (sdram_cs_n),
        .sdram_ras_n            (sdram_ras_n),
        .sdram_cas_n            (sdram_cas_n),
        .sdram_we_n             (sdram_we_n),
        .sdram_ba               (sdram_ba),
        .sdram_addr             (sdram_addr),
        .sdram_dqm              (sdram_dqm),
        .sdram_data             (sdram_data)
    );    

// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------

	
// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------

    
endmodule