// *********************************************************************************
// 文件名: sdram_data.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.9
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: sdram_data
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)SDRAM数据读写模块
// 
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
`include "sdram_para.v"                     //包含SDRAM参数定义模块

// ---------------------------------------------------------------------------------
// 仿真时间 Simulation Timescale
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// 常量参数 Constant Parameters
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// 模块定义 Module Define
// --------------------------------------------------------------------------------- 
module sdram_data
(
    // clock & reset
    input 			clk,		            //SDRAM控制器时钟
	input 			rst_n,  		        //系统复位信号, 低电平有效

    input  [15 : 0] sdram_data_in,          //写入SDRAM中的数据
    output [15 : 0] sdram_data_out,         //从SDRAM中读出的数据
    input  [ 3 : 0] sdram_work_state,       //SDRAM工作状态寄存器
    input  [ 9 : 0] cnt_clk,                //时钟计数
    
    // SDRAM芯片硬件接口
    inout  [15 : 0] sdram_data              //SDRAM数据总线
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
   
   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    reg             sdram_out_en;           //SDRAM数据总线输出使能
    reg    [15 : 0] sdram_din_r;            //寄存写入SDRAM中的数据
    reg    [15 : 0] sdram_dout_r;           //寄存从SDRAM中读取的数据
	
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    //SDRAM双向数据线作为输入时保持高阻态
    assign sdram_data = sdram_out_en? sdram_din_r : 16'hzzzz;
    
    //输出SDRAM中读取的数据
    assign sdram_data_out = sdram_dout_r;
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    //SDRAM数据总线输出使能
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_out_en <= 1'b0;
        end
        //向SDRAM中写数据时, 输出使能拉高
        else if((sdram_work_state == `W_WRITE) || (sdram_work_state == `W_WD))
        begin
            sdram_out_en <= 1'b1;
        end
        else
        begin
            sdram_out_en <= 1'b0;
        end
    end
    
    //将待写入数据送到SDRAM数据总线上
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_din_r <= 16'b0;
        end
        else if((sdram_work_state == `W_WRITE) || (sdram_work_state == `W_WD))
        begin
            sdram_din_r <= sdram_data_in;       //寄存要写入SDRAM的数据
        end
        else
        begin
            sdram_din_r <= sdram_din_r;
        end
    end
    
    //读数据时, 寄存SDRAM数据线上的数据
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_dout_r <= 16'd0;
        end
        else if(sdram_work_state == `W_RD)
        begin
            sdram_dout_r <= sdram_data;         //寄存从SDRAM中读出的数据
        end
        else 
        begin
            sdram_dout_r <= sdram_dout_r;
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