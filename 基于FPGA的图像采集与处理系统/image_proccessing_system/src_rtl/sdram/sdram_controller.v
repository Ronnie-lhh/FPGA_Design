// *********************************************************************************
// 文件名: sdram_controller.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.13
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: sdram_controller
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)SDRAM控制器     
//            2)驱动模块
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
module sdram_controller
(
    // clock & reset
    input 			clk,		            //SDRAM控制器时钟, 100MHZ
	input 			rst_n,  		        //系统复位信号, 低电平有效

    // SDRAM控制器写端口
	input			sdram_wr_req,           //写SDRAM请求信号
    output			sdram_wr_ack,           //写SDRAM响应信号
	input  [23 : 0] sdram_wr_addr,          //写SDRAM的地址
	input  [ 9 : 0]	sdram_wr_burst_len,     //写SDRAM的数据突发长度
	input  [15 : 0]	sdram_din,              //写入SDRAM的数据

    // SDRAM控制器读端口	                    
	input			sdram_rd_req,           //读SDRAM请求信号
    output 			sdram_rd_ack,           //读SDRAM响应信号
	input  [23 : 0]	sdram_rd_addr,          //读SDRAM的地址
	input  [ 9 : 0] sdram_rd_burst_len,     //读SDRAM的数据突发长度
	output [15 : 0] sdram_dout,             //从SDRAM中读出的数据

    output          sdram_init_done,        //SDRAM 初始化完成标志

    // FPGA与SDRAM硬件接口                   
    output          sdram_cke,              //SDRAM 时钟有效信号
    output          sdram_cs_n,             //SDRAM 片选信号
    output          sdram_ras_n,            //SDRAM 行地址选通信号
    output          sdram_cas_n,            //SDRAM 列地址选通信号
    output          sdram_we_n,             //SDRAM 写允许
    output [ 1 : 0] sdram_ba,               //SDRAM L-Bank地址线
    output [12 : 0] sdram_addr,             //SDRAM 地址总线
    inout  [15 : 0] sdram_data	            //SDRAM 数据总线
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
   
   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    wire   [4 : 0] sdram_init_state;        //SDRAM 初始化状态
    wire   [3 : 0] sdram_work_state;        //SDRAM 工作状态
    wire   [9 : 0] cnt_clk;                 //时钟计数器
    wire           sdram_rd_wr_ctrl;        //SDRAM读/写控制信号, 写(0), 读(1)
	
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// 结构化描述 Moudle Instantiate
// ---------------------------------------------------------------------------------
    // SDRAM 状态控制模块
    sdram_state_ctrl    U_sdram_state_ctrl
    (
        // clock & reset
        .clk                            (clk),
        .rst_n                          (rst_n),

        .sdram_wr_req                   (sdram_wr_req),
        .sdram_rd_req                   (sdram_rd_req),
        .sdram_wr_ack                   (sdram_wr_ack),
        .sdram_rd_ack                   (sdram_rd_ack),
        .sdram_wr_burst_len             (sdram_wr_burst_len),
        .sdram_rd_burst_len             (sdram_rd_burst_len),
        .sdram_init_done                (sdram_init_done),

        .sdram_init_state               (sdram_init_state),
        .sdram_work_state               (sdram_work_state),
        .cnt_clk                        (cnt_clk),
        .sdram_rd_wr_ctrl               (sdram_rd_wr_ctrl)
    );
    
    // SDRAM命令控制模块
    sdram_cmd       U_sdram_cmd
    (
        // clock & reset
        .clk                            (clk),
        .rst_n                          (rst_n),

        // input signal
        .sys_wr_addr                    (sdram_wr_addr),
        .sys_rd_addr                    (sdram_rd_addr),
        .sdram_wr_burst_len             (sdram_wr_burst_len),
        .sdram_rd_burst_len             (sdram_rd_burst_len),

        .sdram_init_state               (sdram_init_state),
        .sdram_work_state               (sdram_work_state),
        .cnt_clk                        (cnt_clk),
        .sdram_rd_wr_ctrl               (sdram_rd_wr_ctrl),

        // output signal
        .sdram_cke                      (sdram_cke),
        .sdram_cs_n                     (sdram_cs_n),
        .sdram_ras_n                    (sdram_ras_n),
        .sdram_cas_n                    (sdram_cas_n),
        .sdram_we_n                     (sdram_we_n),
        .sdram_ba                       (sdram_ba),
        .sdram_addr                     (sdram_addr)
    );
    
    // SDRAM数据读写模块
    sdram_data      U_sdram_data
    (
        // clock & reset
        .clk		                    (clk),
        .rst_n 		                    (rst_n),

        .sdram_data_in                  (sdram_din),
        .sdram_data_out                 (sdram_dout),
        .sdram_work_state               (sdram_work_state),
        .cnt_clk                        (cnt_clk),
        
        // SDRAM芯片硬件接口
        .sdram_data                     (sdram_data)
    );
    
// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------
    
	
// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------

    
endmodule 