// ********************************************************************************* 
// 文件名: matrix_gen_3x3_8b.v
// 创建人: 梁辉鸿
// 创建日期: 2021.3.25
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: matrix_gen_3x3_8b
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)3X3灰度矩阵生成模块
//            2)针对灰度图像数据, 8bit
//             3)使用2个双端口RAM(512 x 8)
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
module matrix_gen_3x3_8b
(
    // clock & reset
    input 			    clk,	                //时钟信号
    input               rst_n,                  //复位信号, 低电平有效

    // input signal
    input               ycbcr_vs,               //vsync信号
    input               ycbcr_hs,               //hsync信号
    input               ycbcr_de,               //data enable信号
    input      [ 7 : 0] ycbcr_y,                //灰度数据
    
    // output signal
    output              matrix_vs,              //vsync信号
    output              matrix_hs,              //hsync信号
    output              matrix_de,              //data enable信号
    output reg [ 7 : 0] matrix_p11,             //矩阵像素(1,1)
    output reg [ 7 : 0] matrix_p12,             //矩阵像素(1,2)
    output reg [ 7 : 0] matrix_p13,             //矩阵像素(1,3)
    output reg [ 7 : 0] matrix_p21,             //矩阵像素(2,1)
    output reg [ 7 : 0] matrix_p22,             //矩阵像素(2,2)
    output reg [ 7 : 0] matrix_p23,             //矩阵像素(2,3)
    output reg [ 7 : 0] matrix_p31,             //矩阵像素(3,1)
    output reg [ 7 : 0] matrix_p32,             //矩阵像素(3,2)
    output reg [ 7 : 0] matrix_p33              //矩阵像素(3,3)
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------

   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    reg        [ 7 : 0] row3_data;              //3x3矩阵第3行数据
    reg        [ 1 : 0] ycbcr_vs_d;             //场同步信号的二级寄存
    reg        [ 1 : 0] ycbcr_hs_d;             //行同步信号的二级寄存
    reg        [ 1 : 0] ycbcr_de_d;             //数据有效使能信号的二级寄存
    
    wire       [ 7 : 0] row1_data;              //3x3矩阵第1行数据
    wire       [ 7 : 0] row2_data;              //3x3矩阵第2行数据
    wire                ycbcr_hs_d0;            //行同步信号的一级寄存
    wire                ycbcr_de_d0;            //数据有效使能信号的一级寄存
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// ---------------------------------------------------------------------------------    
    // 控制信号的延时寄存
    assign  ycbcr_hs_d0 = ycbcr_hs_d[0];
    assign  ycbcr_de_d0 = ycbcr_de_d[0];
    assign  matrix_vs   = ycbcr_vs_d[1];
    assign  matrix_hs   = ycbcr_hs_d[1];
    assign  matrix_de   = ycbcr_de_d[1];

// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    // 当前数据放在第3行
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            row3_data <= 8'd0;
        end
        else if(ycbcr_de)
        begin
            row3_data <= ycbcr_y;
        end
        else
        begin
            row3_data <= row3_data;
        end
    end    
    
    // 将控制信号延迟2拍, 用于同步化处理
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            ycbcr_vs_d <= 2'd0;
            ycbcr_hs_d <= 2'd0;
            ycbcr_de_d <= 2'd0;
        end
        else
        begin
            ycbcr_vs_d <= {ycbcr_vs_d[0], ycbcr_vs};
            ycbcr_hs_d <= {ycbcr_hs_d[0], ycbcr_hs};
            ycbcr_de_d <= {ycbcr_de_d[0], ycbcr_de};
        end
    end    
    
    // 在同步化处理后的控制信号下, 输出3x3灰度矩阵
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            {matrix_p11, matrix_p12, matrix_p13} <= 24'd0;
            {matrix_p21, matrix_p22, matrix_p23} <= 24'd0;
            {matrix_p31, matrix_p32, matrix_p33} <= 24'd0;
        end
        else if(ycbcr_hs_d0)
        begin
            if(ycbcr_de_d0)
            begin
                {matrix_p11, matrix_p12, matrix_p13} <= {matrix_p12, matrix_p13, row1_data};
                {matrix_p21, matrix_p22, matrix_p23} <= {matrix_p22, matrix_p23, row2_data};
                {matrix_p31, matrix_p32, matrix_p33} <= {matrix_p32, matrix_p33, row3_data};
            end
            else
            begin
                {matrix_p11, matrix_p12, matrix_p13} <= {matrix_p11, matrix_p12, matrix_p13};
                {matrix_p21, matrix_p22, matrix_p23} <= {matrix_p21, matrix_p22, matrix_p23};
                {matrix_p31, matrix_p32, matrix_p33} <= {matrix_p31, matrix_p32, matrix_p33};
            end
        end
        else
        begin
            {matrix_p11, matrix_p12, matrix_p13} <= 24'd0;
            {matrix_p21, matrix_p22, matrix_p23} <= 24'd0;
            {matrix_p31, matrix_p32, matrix_p33} <= 24'd0;
        end
    end

// ---------------------------------------------------------------------------------
// 结构化描述 Moudle Instantiate
// ---------------------------------------------------------------------------------
    // 实现行移位存储的双端口RAM控制模块
    row_shift_ram_ctrl      U_row_shift_ram_ctrl
    (
        // clock & reset
        .clk                        (clk),
        .rst_n                      (rst_n),
    
        // input signal 
        .ycbcr_hs                   (ycbcr_hs),
        .ycbcr_de                   (ycbcr_de),
        .ycbcr_y                    (ycbcr_y),
    
        // output signal    
        .pre_row0                   (row2_data),
        .pre_row1                   (row1_data)
    );

// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------

	
// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------

    
endmodule