// ********************************************************************************* 
// 文件名: video_image_processor.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.25
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: video_image_processor
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)图像处理算法的封装顶层模块  
//            2)RGB转YCbCr, 二值化, 中值滤波, Sobel边缘检测
//             3)根据按键指令切换显示各种算法处理结果
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
parameter   GRAY_THRESHOLD = 8'd60;             //二值化处理的自定阈值
parameter   SOBEL_THRESHOLD = 11'd35;           //Sobel自定阈值

// ---------------------------------------------------------------------------------
// 模块定义 Module Define
// --------------------------------------------------------------------------------- 
module video_image_processor
(
    // clock & reset
    input 			    clk,	                //时钟信号
    input               rst_n,                  //复位信号, 低电平有效

    // input signal
    input      [ 3 : 0] key_cmd,                //按键指令
    
    // 预处理图像接口
    input               pre_img_vs,             //预处理图像场同步信号
    input               pre_img_hs,             //预处理图像行同步信号
    input               pre_img_de,             //预处理图像数据有效使能信号
    input      [15 : 0] pre_img_data,           //预处理图像数据, RGB565格式
    
    // output signal
    // 处理后图像接口
    output reg          proc_img_vs,            //处理后图像场同步信号
    output reg          proc_img_hs,            //处理后图像行同步信号
    output reg          proc_img_de,            //处理后图像数据有效使能信号
    output reg [15 : 0] proc_img_data           //处理后图像数据, YCbCr格式
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
    // 切换各种算法处理的按键命令
    localparam    GRAY_CMD = 4'b1110;           //灰度图像显示
    localparam     BIN_CMD = 4'b1101;           //图像二值化
    localparam  MEDIAN_CMD = 4'b1011;           //灰度图中值滤波
    localparam   SOBEL_CMD = 4'b0111;           //基于Sobel算子的边缘检测
   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    // RGB转YCbCr
    wire                ycbcr_vs;
    wire                ycbcr_hs;
    wire                ycbcr_de;
    wire       [ 7 : 0] ycbcr_y;
    wire       [ 7 : 0] ycbcr_cb;
    wire       [ 7 : 0] ycbcr_cr;
    
    // 二值化
    wire                bin_vs;
    wire                bin_hs;
    wire                bin_de;
    wire       [ 7 : 0] bin_y;
    
    // 中值滤波
    wire                median_vs;
    wire                median_hs;
    wire                median_de;
    wire       [ 7 : 0] median_y;
    
    // Sobel边缘检测
    wire                sobel_vs;
    wire                sobel_hs;
    wire                sobel_de;
    wire       [ 7 : 0] sobel_y;
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// ---------------------------------------------------------------------------------    


// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    // 根据按键指令切换显示各种算法处理结果
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            proc_img_vs   <=  1'b0;
            proc_img_hs   <=  1'b0;
            proc_img_de   <=  1'b0;
            proc_img_data <= 16'd0;
        end
        else
        begin
            case(key_cmd)
                            //灰度图像显示
                GRAY_CMD: 
                    begin
                        proc_img_vs   <= ycbcr_vs;
                        proc_img_hs   <= ycbcr_hs;
                        proc_img_de   <= ycbcr_de;
                        proc_img_data <= {ycbcr_y[7 : 3], ycbcr_y[7 : 2], ycbcr_y[7 : 3]};
                    end
                            //图像二值化
                BIN_CMD:
                    begin
                        proc_img_vs   <= bin_vs;
                        proc_img_hs   <= bin_hs;
                        proc_img_de   <= bin_de;
                        proc_img_data <= {bin_y[7 : 3], bin_y[7 : 2], bin_y[7 : 3]};
                    end
                            //灰度图中值滤波
                MEDIAN_CMD:
                    begin
                        proc_img_vs   <= median_vs;
                        proc_img_hs   <= median_hs;
                        proc_img_de   <= median_de;
                        proc_img_data <= {median_y[7 : 3], median_y[7 : 2], median_y[7 : 3]};
                    end
                            //基于Sobel算子的边缘检测
                SOBEL_CMD:
                    begin
                        proc_img_vs   <= sobel_vs;
                        proc_img_hs   <= sobel_hs;
                        proc_img_de   <= sobel_de;
                        proc_img_data <= {sobel_y[7 : 3], sobel_y[7 : 2], sobel_y[7 : 3]};
                    end
                            //不做图像处理, 单纯为图像实时采集输出
                default:
                    begin
                        proc_img_vs   <= pre_img_vs;
                        proc_img_hs   <= pre_img_hs;
                        proc_img_de   <= pre_img_de;
                        proc_img_data <= pre_img_data;
                    end
            endcase
        end
    end

// ---------------------------------------------------------------------------------
// 结构化描述 Moudle Instantiate
// ---------------------------------------------------------------------------------
    // RGB转YCbCr
    proc_rgb2ycbcr      U_proc_rgb2ycbcr
    (
        // clock & reset
        .clk                        (clk),
        .rst_n                      (rst_n),
    
        // input signal 
        // 图像处理前的数据接口   
        .rgb565_vs                  (pre_img_vs),
        .rgb565_hs                  (pre_img_hs),
        .rgb565_de                  (pre_img_de),
        .rgb565_r                   (pre_img_data[15 : 11]),
        .rgb565_g                   (pre_img_data[10 :  5]),
        .rgb565_b                   (pre_img_data[ 4 :  0]),
    
        // output signal    
        //图像处理后的数据接口    
        .ycbcr_vs                   (ycbcr_vs),
        .ycbcr_hs                   (ycbcr_hs),
        .ycbcr_de                   (ycbcr_de),
        .ycbcr_y                    (ycbcr_y),
        .ycbcr_cb                   (ycbcr_cb),
        .ycbcr_cr                   (ycbcr_cr)
    );
    
    // 二值化处理
    proc_binarization
    #(
        // prameter passing
        .GRAY_THRESHOLD             (GRAY_THRESHOLD)
    )   
    U_proc_binarization 
    (   
        // clock & reset    
        .clk                        (clk),
        .rst_n  	                (rst_n),
    
        // input signal 
        // 图像处理前的数据接口   
        .ycbcr_vs                   (ycbcr_vs),
        .ycbcr_hs                   (ycbcr_hs),
        .ycbcr_de                   (ycbcr_de),
        .ycbcr_y                    (ycbcr_y),
    
        // output signal    
        // 图像处理后的数据接口   
        .bin_vs                     (bin_vs),
        .bin_hs                     (bin_hs),
        .bin_de                     (bin_de),
        .bin_y                      (bin_y)
    );
    
    // 灰度图中值滤波
    proc_gray_median_filter      U_proc_gray_median_filter
    (
        // clock & reset
        .clk                        (clk),
        .rst_n                      (rst_n),

        // input signal
        // 图像处理前的数据接口
        .ycbcr_vs                   (ycbcr_vs),
        .ycbcr_hs                   (ycbcr_hs),
        .ycbcr_de                   (ycbcr_de),
        .ycbcr_y                    (ycbcr_y),

        // output signal
        // 图像处理后的数据接口
        .median_vs                  (median_vs),
        .median_hs                  (median_hs),
        .median_de                  (median_de),
        .median_y                   (median_y)
    );
    
    // 基于Sobel算子的边缘检测
    proc_sobel_edge_detector
    #(
        // parameter passing
        .SOBEL_THRESHOLD            (SOBEL_THRESHOLD)
    )
    U_proc_sobel_edge_detector
    (
        // clock & reset
        .clk                        (clk),
        .rst_n                      (rst_n),

        // input signal
        // 图像处理前的数据接口
        .ycbcr_vs                   (ycbcr_vs),
        .ycbcr_hs                   (ycbcr_hs),
        .ycbcr_de                   (ycbcr_de),
        .ycbcr_y                    (ycbcr_y),

        // output signal
        // 图像处理后的数据接口
        .sobel_vs                   (sobel_vs),
        .sobel_hs                   (sobel_hs),
        .sobel_de                   (sobel_de),
        .sobel_y                    (sobel_y)
    );

// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------

	
// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------

    
endmodule