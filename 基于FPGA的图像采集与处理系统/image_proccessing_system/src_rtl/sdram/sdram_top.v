// *********************************************************************************
// 文件名: sdram_top.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.13
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: sdram_top
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)SDRAM控制器顶层模块
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
module sdram_top
(
    // clock & reset
    input 			    ref_clk,	            //SDRAM控制器参考时钟
    input               out_clk,                //用于输出的相位偏移时钟
	input 			    rst_n,  		        //系统复位信号, 低电平有效

    // 用户写端口
    input               wr_clk,                 //写端口FIFO: 写时钟
    input               wr_en,                  //写端口FIFO: 写使能
    input      [15 : 0] wr_data,                //写端口FIFO: 写数据
    input      [23 : 0] wr_min_addr,            //写SDRAM的起始地址
    input      [23 : 0] wr_max_addr,            //写SDRAM的结束地址
    input      [ 9 : 0] wr_len,                 //写SDRAM的数据突发长度
    input               wr_load,                //写端口复位: 复位写地址, 清空写FIFO

    // 用户读端口                                
    input               rd_clk,                 //读端口FIFO: 读时钟
    input               rd_en,                  //读端口FIFO: 读使能
    output     [15 : 0] rd_data,                //读端口FIFO: 读数据
    input      [23 : 0] rd_min_addr,            //读SDRAM的起始地址
    input      [23 : 0] rd_max_addr,            //读SDRAM的结束地址
    input      [ 9 : 0] rd_len,                 //从SDRAM中读数据的突发长度
    input               rd_load,                //读端口复位: 复位读地址, 清空读FIFO

    // 用户控制端口                              
    input               sdram_read_valid,       //SDRAM 读使能
    input               sdram_pingpang_en,      //SDRAM 读写乒乓操作使能
    output              sdram_init_done,        //SDRAM 初始化完成标志

    // SDRAM芯片硬件接口                             
    output              sdram_clk,              //SDRAM 芯片时钟信号
    output              sdram_cke,              //SDRAM 时钟有效信号
    output              sdram_cs_n,             //SDRAM 片选信号
    output              sdram_ras_n,            //SDRAM 行地址选通信号
    output              sdram_cas_n,            //SDRAM 列地址选通信号
    output              sdram_we_n,             //SDRAM 写允许
    output     [ 1 : 0] sdram_ba,               //SDRAM L-Bank地址线
    output     [12 : 0] sdram_addr,             //SDRAM 地址总线
    output     [ 1 : 0] sdram_dqm,              //SDRAM 数据掩码
    inout      [15 : 0] sdram_data              //SDRAM 数据总线
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
 
 
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    wire                sdram_wr_req;           //SDRAM 写请求
    wire                sdram_wr_ack;           //SDRAM 写响应
    wire       [23 : 0] sdram_wr_addr;          //SDRAM 写地址
    wire       [15 : 0] sdram_din;              //写入SDRAM的数据
    
    wire                sdram_rd_req;           //SDRAM 读请求
    wire                sdram_rd_ack;           //SDRAM 读响应
    wire       [23 : 0] sdram_rd_addr;          //SDRAM 读地址
    wire       [15 : 0] sdram_dout;             //从SDRAM中读出的数据
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    assign sdram_clk = out_clk;                 //将相位偏移时钟输出给SDRAM芯片
    assign sdram_dqm = 2'b00;                   //读写过程中均不屏蔽数据线(不使用数据掩码)
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// 结构化描述 Moudle Instantiate
// ---------------------------------------------------------------------------------
    // SDRAM读写端口FIFO控制模块
    sdram_fifo_ctrl     U_sdram_fifo_ctrl
    (
        // clock & reset
        .clk_ref                    (ref_clk),
        .rst_n                      (rst_n),

        // 用户写端口
        .clk_write                  (wr_clk),
        .wrf_wrreq                  (wr_en),
        .wrf_din                    (wr_data),
        .wr_min_addr                (wr_min_addr),
        .wr_max_addr                (wr_max_addr),
        .wr_len                     (wr_len),
        .wr_load                    (wr_load),

        // 用户读端口
        .clk_read                   (rd_clk),
        .rdf_rdreq                  (rd_en),
        .rdf_dout                   (rd_data),
        .rd_min_addr                (rd_min_addr),
        .rd_max_addr                (rd_max_addr),
        .rd_len                     (rd_len),
        .rd_load                    (rd_load),

        // 用户控制端口
        .sdram_read_valid           (sdram_read_valid),
        .sdram_init_done            (sdram_init_done),
        .sdram_pingpang_en          (sdram_pingpang_en),

        // SDRAM控制器写端口
        .sdram_wr_req               (sdram_wr_req),
        .sdram_wr_ack               (sdram_wr_ack),
        .sdram_wr_addr              (sdram_wr_addr),
        .sdram_din                  (sdram_din),
           
        // SDRAM控制器读端口
        .sdram_rd_req               (sdram_rd_req),
        .sdram_rd_ack               (sdram_rd_ack),
        .sdram_rd_addr              (sdram_rd_addr),
        .sdram_dout                 (sdram_dout)
    );
    
    //SDRAM控制器
    sdram_controller        U_sdram_controller
    (
        // clock & reset
        .clk                        (ref_clk),
        .rst_n  		            (rst_n),

        // SDRAM控制器写端口
        .sdram_wr_req               (sdram_wr_req),
        .sdram_wr_ack               (sdram_wr_ack),
        .sdram_wr_addr              (sdram_wr_addr),
        .sdram_wr_burst_len         (wr_len),
        .sdram_din                  (sdram_din),

        // SDRAM控制器读端口
        .sdram_rd_req               (sdram_rd_req),
        .sdram_rd_ack               (sdram_rd_ack),
        .sdram_rd_addr              (sdram_rd_addr),
        .sdram_rd_burst_len         (rd_len),
        .sdram_dout                 (sdram_dout),

        .sdram_init_done            (sdram_init_done),

        // FPGA与SDRAM硬件接口
        .sdram_cke                  (sdram_cke),
        .sdram_cs_n                 (sdram_cs_n),
        .sdram_ras_n                (sdram_ras_n),
        .sdram_cas_n                (sdram_cas_n),
        .sdram_we_n                 (sdram_we_n),
        .sdram_ba                   (sdram_ba),
        .sdram_addr                 (sdram_addr),
        .sdram_data	                (sdram_data)
    );


// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------
    
	
// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------

    
endmodule