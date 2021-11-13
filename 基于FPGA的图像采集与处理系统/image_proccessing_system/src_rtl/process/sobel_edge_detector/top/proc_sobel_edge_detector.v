// ********************************************************************************* 
// 文件名: proc_sobel_edge_detector.v
// 创建人: 梁辉鸿
// 创建日期: 2021.3.26
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: proc_sobel_edge_detector
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)图像处理算法模块--基于Sobel算子的边缘检测
//            2)Sobel算子如下:
//**********************************************************************************
//                   Sobel                     *         Pixel
//         Gx                     Gy        
//  [  -1  0  +1  ]        [  -1  -2  -1  ]        [  Z1   Z2   Z3  ]
//  [  -2  0  +2  ]        [   0   0   0  ]        [  Z4   Z5   Z6  ]
//  [  -1  0  +1  ]        [  +1  +2  +1  ]        [  Z7   Z8   Z9  ]
//  检测垂直方向的边缘    检测水平方向的边缘
//
//               Gx = (Z7 + 2Z8 + Z9) - (Z1 + 2Z2 + Z3)
//               Gy = (Z3 + 2Z6 + Z9) - (Z1 + 2Z4 + Z7)
//               G  = √(Gx^2 + Gy^2)        //梯度大小
//               θ  = tan^(-1) (Gy / Gx)    //梯度方向
//               若G > 阈值, 则认定为边缘
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
module proc_sobel_edge_detector
#(
    // parameter passing
    parameter   SOBEL_THRESHOLD = 11'd250       //自定Sobel阈值, 范围为[0, 255]
)
(
    // clock & reset
    input 			    clk,	                //时钟信号
    input               rst_n,                  //复位信号, 低电平有效

    // input signal
    // 图像处理前的数据接口
    input               ycbcr_vs,               //vsync信号
    input               ycbcr_hs,               //hsync信号
    input               ycbcr_de,               //data enable信号
    input      [ 7 : 0] ycbcr_y,                //灰度数据

    // output signal
    // 图像处理后的数据接口
    output              sobel_vs,               //vsync信号
    output              sobel_hs,               //hsync信号
    output              sobel_de,               //data enable信号
    output     [ 7 : 0] sobel_y                 //Sobel边缘检测后的灰度数据
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------

   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    reg        [ 9 : 0] Gx_tmp1;                //第一列值
    reg        [ 9 : 0] Gx_tmp2;                //第三列值
    reg        [ 9 : 0] Gx_data;                //y方向的偏导数
    reg        [ 9 : 0] Gy_tmp1;                //第一行值
    reg        [ 9 : 0] Gy_tmp2;                //第三行值
    reg        [ 9 : 0] Gy_data;                //x方向的偏导数
    reg        [20 : 0] Gxy_square;             //Gx和Gy的平方和
    reg                 edge_flag;              //边缘检测结果, 边缘(1)/非边缘(0)
    
    reg        [ 3 : 0] matrix_vs_d;            //场同步信号的四级寄存
    reg        [ 3 : 0] matrix_hs_d;            //行同步信号的四级寄存
    reg        [ 3 : 0] matrix_de_d;            //数据有效使能信号的四级寄存
    
    wire       [10 : 0] sqrt_result;            //开方结果
    wire       [ 7 : 0] sobel_y_r;              //Sobel边缘检测后的灰度数据预存
    
    wire                matrix_vs;              //vsync信号
    wire                matrix_hs;              //hsync信号
    wire                matrix_de;              //data enable信号
    wire       [ 7 : 0] matrix_p11;             //矩阵像素(1,1)
    wire       [ 7 : 0] matrix_p12;             //矩阵像素(1,2)
    wire       [ 7 : 0] matrix_p13;             //矩阵像素(1,3)
    wire       [ 7 : 0] matrix_p21;             //矩阵像素(2,1)
    wire       [ 7 : 0] matrix_p22;             //矩阵像素(2,2)
    wire       [ 7 : 0] matrix_p23;             //矩阵像素(2,3)
    wire       [ 7 : 0] matrix_p31;             //矩阵像素(3,1)
    wire       [ 7 : 0] matrix_p32;             //矩阵像素(3,2)
    wire       [ 7 : 0] matrix_p33;             //矩阵像素(3,3)
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// ---------------------------------------------------------------------------------    
    // 控制信号延迟4个时钟周期
    assign  sobel_vs = matrix_vs_d[3];
    assign  sobel_hs = matrix_hs_d[3];
    assign  sobel_de = matrix_de_d[3];
    
    // Sobel边缘检测后的灰度数据预存, 边缘(黑色)/非边缘(白色)
    assign  sobel_y_r = edge_flag? 8'h00 : 8'hff;
    
    // Sobel边缘检测后的灰度数据
    assign  sobel_y = sobel_hs? sobel_y_r : 8'd0;

// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    // Step1 计算Gx, Gy
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            Gx_tmp1 <= 10'd0;
            Gx_tmp2 <= 10'd0;
            Gx_data <= 10'd0;
            
            Gy_tmp1 <= 10'd0;
            Gy_tmp2 <= 10'd0;
            Gy_data <= 10'd0;
        end
        else
        begin
            Gx_tmp1 <= {2'b00, matrix_p11} + {1'b0, matrix_p12, 1'b0} + {2'b00, matrix_p13};
            Gx_tmp2 <= {2'b00, matrix_p31} + {1'b0, matrix_p32, 1'b0} + {2'b00, matrix_p33};
            Gx_data <= (Gx_tmp1 >= Gx_tmp2)? (Gx_tmp1 - Gx_tmp2) : (Gx_tmp2 - Gx_tmp1);
            
            Gy_tmp1 <= {2'b00, matrix_p11} + {1'b0, matrix_p21, 1'b0} + {2'b00, matrix_p31};
            Gy_tmp2 <= {2'b00, matrix_p13} + {1'b0, matrix_p23, 1'b0} + {2'b00, matrix_p33};
            Gy_data <= (Gy_tmp1 >= Gy_tmp2)? (Gy_tmp1 - Gy_tmp2) : (Gy_tmp2 - Gy_tmp1);
        end
    end
    
    /*
    // Step1 计算Gx, Gy
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            Gx_tmp1 <= 10'd0;
            Gx_tmp2 <= 10'd0;
            Gx_data <= 10'd0;
            
            Gy_tmp1 <= 10'd0;
            Gy_tmp2 <= 10'd0;
            Gy_data <= 10'd0;
        end
        else
        begin
            Gx_tmp1 <= matrix_p11 + (matrix_p12 << 1) + matrix_p13;
            Gx_tmp2 <= matrix_p31 + (matrix_p32 << 1) + matrix_p33;
            Gx_data <= (Gx_tmp1 >= Gx_tmp2)? (Gx_tmp1 - Gx_tmp2) : (Gx_tmp2 - Gx_tmp1);
            
            Gy_tmp1 <= matrix_p11 + (matrix_p21 << 1) + matrix_p31;
            Gy_tmp2 <= matrix_p13 + (matrix_p23 << 1) + matrix_p33;
            Gy_data <= (Gy_tmp1 >= Gy_tmp2)? (Gy_tmp1 - Gy_tmp2) : (Gy_tmp2 - Gy_tmp1);
        end
    end
    */
    
    // Step2 计算Gx^2 + Gy^2
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            Gxy_square <= 21'd0;
        end
        else
        begin
            Gxy_square <= Gx_data * Gx_data + Gy_data + Gy_data;
        end
    end
    
    // Step3 开平方, 使用Xilinx的平方根IP核例化
    
    // Step4 将开方结果与预设阈值比较
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            edge_flag <= 1'b0;
        end
        else if(sqrt_result >= SOBEL_THRESHOLD)     //大于等于预设阈值, 检测到边缘
        begin
            edge_flag <= 1'b1;
        end
        else                                        //小于预设阈值, 非边缘
        begin
            edge_flag <= 1'b0;
        end
    end
    
    // 控制信号打4拍, 用作同步化处理
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            matrix_vs_d <= 4'd0;
            matrix_hs_d <= 4'd0;
            matrix_de_d <= 4'd0;
        end
        else
        begin
            matrix_vs_d <= {matrix_vs_d[2 : 0], matrix_vs};
            matrix_hs_d <= {matrix_hs_d[2 : 0], matrix_hs};
            matrix_de_d <= {matrix_de_d[2 : 0], matrix_de};
        end
    end

// ---------------------------------------------------------------------------------
// 结构化描述 Moudle Instantiate
// ---------------------------------------------------------------------------------
    // 3X3灰度矩阵生成模块
    matrix_gen_3x3_8b       U2_matrix_gen_3x3_8b
    (
        // clock & reset
        .clk	                        (clk),
        .rst_n                          (rst_n),
        
        // input signal
        .ycbcr_vs                       (ycbcr_vs),
        .ycbcr_hs                       (ycbcr_hs),
        .ycbcr_de                       (ycbcr_de),
        .ycbcr_y                        (ycbcr_y),

        // output signal
        .matrix_vs                      (matrix_vs),
        .matrix_hs                      (matrix_hs),
        .matrix_de                      (matrix_de),
        .matrix_p11                     (matrix_p11),
        .matrix_p12                     (matrix_p12),
        .matrix_p13                     (matrix_p13),
        .matrix_p21                     (matrix_p21),
        .matrix_p22                     (matrix_p22),
        .matrix_p23                     (matrix_p23),
        .matrix_p31                     (matrix_p31),
        .matrix_p32                     (matrix_p32),
        .matrix_p33                     (matrix_p33)
    );
    
    // 平方根IP核例化
    sqrt_ip     U_sqrt_ip
    (
        // clock & reset
        .clk                            (clk),
        
        .x_in                           (Gxy_square),
        .x_out                          (sqrt_result)
    );
    
// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------

	
// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------

    
endmodule