// ********************************************************************************* 
// 文件名: median_filter_3x3.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.25
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: median_filter_3x3
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)3x3矩阵的中值滤波器
//            2)中值滤波算法如下:
//**********************************************************************************
//              FPGA Median Fliter Sort Order
//      Pixel  --  Sort1 -- Sort2  --  Sort3
//  [ P1 P2 P3 ]  [ Max1     Mid1      Min1 ]
//  [ P4 P5 P6 ]  [ Max2     Mid2      Min2 ]  [ Max_min Mid_mid Min_max ]  Mid_result
//  [ P7 P8 P9 ]  [ Max3     Mid3      Min3 ]
//**********************************************************************************
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
module median_filter_3x3
(
    // clock & reset
    input 			    clk,	                //时钟信号
    input               rst_n,                  //复位信号, 低电平有效

    // input signal
    input               matrix_vs,              //vsync信号
    input               matrix_hs,              //hsync信号
    input               matrix_de,              //data enable信号
    input      [ 7 : 0] matrix_p11,             //滤波前的矩阵像素(1,1)
    input      [ 7 : 0] matrix_p12,             //滤波前的矩阵像素(1,2)
    input      [ 7 : 0] matrix_p13,             //滤波前的矩阵像素(1,3)
    input      [ 7 : 0] matrix_p21,             //滤波前的矩阵像素(2,1)
    input      [ 7 : 0] matrix_p22,             //滤波前的矩阵像素(2,2)
    input      [ 7 : 0] matrix_p23,             //滤波前的矩阵像素(2,3)
    input      [ 7 : 0] matrix_p31,             //滤波前的矩阵像素(3,1)
    input      [ 7 : 0] matrix_p32,             //滤波前的矩阵像素(3,2)
    input      [ 7 : 0] matrix_p33,             //滤波前的矩阵像素(3,3)
    
    // output signal
    output              median_vs,              //vsync信号
    output              median_hs,              //hsync信号
    output              median_de,              //data enable信号
    output     [ 7 : 0] median_y                //滤波后的中值像素数据
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------

   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    // 控制信号的三级寄存
    reg        [ 2 : 0] matrix_vs_d;
    reg        [ 2 : 0] matrix_hs_d;
    reg        [ 2 : 0] matrix_de_d;
    
    // 第一次排序
    wire       [ 7 : 0] max_data1;              //矩阵第一行排序后的最大值
    wire       [ 7 : 0] mid_data1;              //矩阵第一行排序后的中间值
    wire       [ 7 : 0] min_data1;              //矩阵第一行排序后的最小值
    wire       [ 7 : 0] max_data2;              //矩阵第二行排序后的最大值
    wire       [ 7 : 0] mid_data2;              //矩阵第二行排序后的中间值
    wire       [ 7 : 0] min_data2;              //矩阵第二行排序后的最小值
    wire       [ 7 : 0] max_data3;              //矩阵第三行排序后的最大值
    wire       [ 7 : 0] mid_data3;              //矩阵第三行排序后的中间值
    wire       [ 7 : 0] min_data3;              //矩阵第三行排序后的最小值
    // 第二次排序
    wire       [ 7 : 0] max_min_data;           //矩阵三行最大值中的最小值
    wire       [ 7 : 0] mid_mid_data;           //矩阵三行中间值中的中间值
    wire       [ 7 : 0] min_max_data;           //矩阵三行最小值中的最大值
    // 第三次排序
    wire       [ 7 : 0] mid_result;             //对第二次排序的结果再取中间值
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// ---------------------------------------------------------------------------------    
    // 控制信号延迟3拍
    assign  median_vs = matrix_vs_d[2];
    assign  median_hs = matrix_hs_d[2];
    assign  median_de = matrix_de_d[2];
    
    // 滤波后的中值像素灰度数据
    assign  median_y = mid_result;

// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    // 将控制信号延迟3拍, 用于同步化处理 (三次排序需要3个时钟周期)
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            matrix_vs_d <= 3'd0;
            matrix_hs_d <= 3'd0;
            matrix_de_d <= 3'd0;
        end
        else
        begin
            matrix_vs_d <= {matrix_vs_d[1 : 0], matrix_vs};
            matrix_hs_d <= {matrix_hs_d[1 : 0], matrix_hs};
            matrix_de_d <= {matrix_de_d[1 : 0], matrix_de};
        end
    end

// ---------------------------------------------------------------------------------
// 结构化描述 Moudle Instantiate
// ---------------------------------------------------------------------------------
    // 第一次排序--取矩阵第一行的最大值、中间值、最小值
    // [ Max1     Mid1      Min1 ]
    sort3       U1_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (matrix_p11),
        .data2                      (matrix_p12),
        .data3                      (matrix_p13),

        // output signal
        .max_data                   (max_data1),
        .mid_data                   (mid_data1),
        .min_data                   (min_data1)
    );
    
    // 第一次排序--取矩阵第二行的最大值、中间值、最小值
    // [ Max2     Mid2      Min2 ]
    sort3       U2_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (matrix_p21),
        .data2                      (matrix_p22),
        .data3                      (matrix_p23),

        // output signal
        .max_data                   (max_data2),
        .mid_data                   (mid_data2),
        .min_data                   (min_data2)
    );
    
    // 第一次排序--取矩阵第三行的最大值、中间值、最小值
    // [ Max3     Mid3      Min3 ]
    sort3       U3_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (matrix_p31),
        .data2                      (matrix_p32),
        .data3                      (matrix_p33),

        // output signal
        .max_data                   (max_data3),
        .mid_data                   (mid_data3),
        .min_data                   (min_data3)
    );
    
    // 第二次排序--取矩阵三行最大值中的最小值
    // [ Max_min
    sort3       U4_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (max_data1),
        .data2                      (max_data2),
        .data3                      (max_data3),

        // output signal
        .max_data                   (),
        .mid_data                   (),
        .min_data                   (max_min_data)
    );
    
    // 第二次排序--取矩阵三行中间值中的中间值
    // Mid_mid
    sort3       U5_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (mid_data1),
        .data2                      (mid_data2),
        .data3                      (mid_data3),

        // output signal
        .max_data                   (),
        .mid_data                   (mid_mid_data),
        .min_data                   ()
    );
    
    // 第二次排序--取矩阵三行最小值中的最大值
    // Min_max ]
    sort3       U6_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (min_data1),
        .data2                      (min_data2),
        .data3                      (min_data3),

        // output signal
        .max_data                   (min_max_data),
        .mid_data                   (),
        .min_data                   ()
    );

    // 第三次排序--对第二次排序的结果再取中间值
    sort3       U7_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (max_min_data),
        .data2                      (mid_mid_data),
        .data3                      (min_max_data),

        // output signal
        .max_data                   (),
        .mid_data                   (mid_result),
        .min_data                   ()
    );
    
// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------

	
// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------

    
endmodule