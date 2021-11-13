// *********************************************************************************
// 文件名: cmos_capture_data.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.18
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: cmos_capture_data
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)CMOS数据采集模块
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

// ---------------------------------------------------------------------------------
// 仿真时间 Simulation Timescale
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// 常量参数 Constant Parameters
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// 模块定义 Module Define
// --------------------------------------------------------------------------------- 
module cmos_capture_data
(
    // clock & reset
	input 			    rst_n,  		        //复位信号, 低电平有效

    // 摄像头接口
    input               cam_pclk,               //CMOS数据像素时钟
    input               cam_vsync,              //CMOS场同步信号
    input               cam_href,               //CMOS行同步信号
    input      [ 7 : 0] cam_data,               //CMOS数据
    
    // 用户接口
    output              cmos_frame_vsync,       //CMOS帧有效信号
    output              cmos_frame_href,        //CMOS行有效信号
    output              cmos_frame_valid,       //CMOS数据有效使能信号
    output     [15 : 0] cmos_frame_data         //CMOS有效数据
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
    //寄存器全部配置完成后, 先等待10帧图像
    //待寄存器配置生效后再开始采集图像
    localparam WAIT_FRAME = 4'd10;              //寄存器数据稳定等待的帧个数

// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    reg                 cam_vsync_d0;           //CMOS场同步信号寄存
    reg                 cam_vsync_d1;           //CMOS场同步信号寄存
    reg                 cam_href_d0;            //CMOS行同步信号寄存
    reg                 cam_href_d1;            //CMOS行同步信号寄存
    reg                 frame_val_flag;         //帧有效标志
    reg        [ 3 : 0] cmos_ps_cnt;            //等待帧数稳定计数器

    reg                 byte_flag;              //8位转16位控制信号
    reg                 byte_flag_d0;           //8位转16位控制信号寄存
    reg        [ 7 : 0] cam_data_d0;            //CMOS数据寄存
    reg        [15 : 0] cmos_data_8_16_t;       //用于8位转16位的临时寄存器
    
    wire                pos_vsync;              //场同步信号上升沿标志
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    //采输入场同步信号的上升沿
    assign pos_vsync = (~cam_vsync_d1) & (cam_vsync_d0);
    
    //输出帧有效信号
    assign cmos_frame_vsync = frame_val_flag? cam_vsync_d1 : 1'b0;
    //输出行有效信号
    assign cmos_frame_href  = frame_val_flag? cam_href_d1  : 1'b0;
    //输出数据有效使能信号
    assign cmos_frame_valid = frame_val_flag? byte_flag_d0 : 1'b0;
    //输出数据
    assign cmos_frame_data  = frame_val_flag? cmos_data_8_16_t : 16'd0; 
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    //采输入场同步信号的上升沿
    always @(posedge cam_pclk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cam_vsync_d0 <= 1'b0;
            cam_vsync_d1 <= 1'b0;
            cam_href_d0  <= 1'b0;
            cam_href_d1  <= 1'b0;
        end
        else
        begin
            cam_vsync_d0 <= cam_vsync;
            cam_vsync_d1 <= cam_vsync_d0;
            cam_href_d0  <= cam_href;
            cam_href_d1  <= cam_href_d0;
        end
    end
    
    //对帧数进行计数
    always @(posedge cam_pclk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cmos_ps_cnt <= 4'd0;
        end
        else if(pos_vsync && (cmos_ps_cnt < WAIT_FRAME))
        begin
            cmos_ps_cnt <= cmos_ps_cnt + 4'd1;
        end
        else
        begin
            cmos_ps_cnt <= cmos_ps_cnt;
        end
    end    
    
    //帧有效标志
    always @(posedge cam_pclk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            frame_val_flag <= 1'b0;
        end
        else if((cmos_ps_cnt == WAIT_FRAME) && pos_vsync)
        begin
            frame_val_flag <= 1'b1;
        end
        else
        begin
            frame_val_flag <= frame_val_flag;
        end
    end    
    
    //8位数据转16位RGB565数据
    always @(posedge cam_pclk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cmos_data_8_16_t <= 16'd0;
            cam_data_d0 <= 8'd0;
            byte_flag <= 1'b0;
        end
        else if(cam_href)
        begin
            byte_flag <= ~byte_flag;
            cam_data_d0 <= cam_data;
            if(byte_flag)
            begin
                cmos_data_8_16_t <= {cam_data_d0, cam_data};
            end
            else
            begin
                cmos_data_8_16_t <= cmos_data_8_16_t;
            end
        end
        else
        begin
            byte_flag <= 1'b0;
            cam_data_d0 <= 8'd0;
            cmos_data_8_16_t <= cmos_data_8_16_t;
        end
    end    
    
    //产生输出数据有效信号(cmos_frame_valid)
    always @(posedge cam_pclk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            byte_flag_d0 <= 1'b0;
        end
        else
        begin
            byte_flag_d0 <= byte_flag;
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