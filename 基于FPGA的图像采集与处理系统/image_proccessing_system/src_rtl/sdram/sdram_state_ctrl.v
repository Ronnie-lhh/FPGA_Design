// *********************************************************************************
// 文件名: sdram_state_ctrl.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.4
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: sdram_state_ctrl
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)SDRAM状态控制模块     
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
`include "sdram_para.v"                             //SDRAM参数定义模块

// ---------------------------------------------------------------------------------
// 仿真时间 Simulation Timescale
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// 常量参数 Constant Parameters
// ---------------------------------------------------------------------------------
    

// ---------------------------------------------------------------------------------
// 模块定义 Module Define
// --------------------------------------------------------------------------------- 
module sdram_state_ctrl
#(
    parameter TRP_CLK  = 10'd4,                     //预充电有效周期
    parameter TRFC_CLK = 10'd6,                     //自动刷新周期
    parameter TRSC_CLK = 10'd6,                     //模式寄存器设置时钟周期
    parameter TRCD_CLK = 10'd2,                     //行选通周期
    parameter TCL_CLK  = 10'd3,                     //列潜伏周期
    parameter TWR_CLK  = 10'd2                      //写入校正周期
)
(
    // clock & reset
    input               clk,                        //系统时钟
    input               rst_n,                      //复位信号, 低电平有效
    
    input               sdram_wr_req,               //写SDRAM请求信号
    input               sdram_rd_req,               //读SDRAM请求信号
    output              sdram_wr_ack,               //写SDRAM响应信号
    output              sdram_rd_ack,               //读SDRAM响应信号
    input      [9 : 0]  sdram_wr_burst_len,         //写SDRAM的数据突发长度(1~512个字节)
    input      [9 : 0]  sdram_rd_burst_len,         //读SDRAM的数据突发长度(1~256个字节)
    output              sdram_init_done,            //SDRAM初始化完成标志

    output reg [4 : 0]  sdram_init_state,           //SDRAM初始化状态
    output reg [3 : 0]  sdram_work_state,           //SDRAM工作状态
    output reg [9 : 0]  cnt_clk,                    //时钟计数器
    output reg          sdram_rd_wr_ctrl            //SDRAM读/写控制信号, 写(0), 读(1)
);



// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
   
   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    reg  [14 : 0] cnt_pw_200us;                     //SDRAM上电稳定期200us计数器
    reg  [10 : 0] cnt_refresh;                      //刷新计数寄存器
    reg           sdram_ref_req;                    //SDRAM自动刷新请求信号
    reg           cnt_rst_n;                        //延时计数器复位信号，低电平有效
    reg  [ 3 : 0] cnt_init_ar;                      //初始化过程自动刷新计数器
   
    wire          done_pw_200us;                    //上电后200us输入稳定期结束标志
    wire          sdram_ref_ack;                    //SDRAM自动刷新应答信号
	
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    //SDRAM上电后200us稳定期结束后,将标志信号拉高
    assign done_pw_200us = (cnt_pw_200us == 15'd20000);
    
    //SDRAM初始化完成标志
    assign sdram_init_done = (sdram_init_state == `I_DONE);
    
    //SDRAM自动刷新应答信号
    assign sdram_ref_ack = (sdram_work_state == `W_AR);
    
    //写SDRAM响应信号
    assign sdram_wr_ack = ((sdram_work_state == `W_TRCD) && ~sdram_rd_wr_ctrl) ||
                          ( sdram_work_state == `W_WRITE) ||
                          ((sdram_work_state == `W_WD) &&
                          ( cnt_clk < sdram_wr_burst_len - 2'd2));
   
   //读SDRAM响应信号
    assign sdram_rd_ack = (sdram_work_state == `W_RD) &&
                          (cnt_clk >= 10'd1) &&
                          (cnt_clk < sdram_rd_burst_len + 2'd1);
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    //上电后计时200us,等待SDRAM状态稳定
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cnt_pw_200us <= 15'd0;
        end
        else if(cnt_pw_200us < 15'd20000)
        begin
            cnt_pw_200us <= cnt_pw_200us + 15'd1;
        end
        else
        begin
            cnt_pw_200us <= cnt_pw_200us;
        end
    end

    //刷新计数器循环计数7812ns (60ms内完成全部8192行刷新操作)
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n) 
        begin
            cnt_refresh <= 11'd0;
        end
        else if(cnt_refresh < 11'd781)      //64ms/8192=7812ns
        begin
            cnt_refresh <= cnt_refresh + 15'd1;
        end
        else
        begin
            cnt_refresh <= 11'd0;
        end
    end
    
    //SDRAM刷新请求
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_ref_req <= 1'b0;
        end
        else if(cnt_refresh == 11'd780)     
        begin
            sdram_ref_req <= 1'b1;          //刷新计数器计时达7812ns时产生刷新请求
        end
        else if(sdram_ref_ack)
        begin
            sdram_ref_req <= 1'b0;          //收到刷新请求响应信号后取消刷新请求 
        end
        else
        begin
            sdram_ref_req <= sdram_ref_req;
        end
    end
    
    //时钟计数器
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cnt_clk <= 10'd0;
        end
        else if(!cnt_rst_n)
        begin
            cnt_clk <= 10'd0;               //在cnt_rst_n有效时时钟计数器清零
        end
        else
        begin
            cnt_clk <= cnt_clk + 10'd1;
        end
    end

    //初始化过程中对自动刷新操作计数
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cnt_init_ar <= 4'd0;
        end
        else if(sdram_init_state == `I_NOP)
        begin
            cnt_init_ar <= 4'd0;
        end
        else if(sdram_init_state == `I_AR)
        begin
            cnt_init_ar <= cnt_init_ar + 4'd1;
        end
        else
        begin
            cnt_init_ar <= cnt_init_ar;
        end
    end

    //SDRAM的初始化状态机, 初始化状态包括预充电、自动刷新、模式寄存器配置等操作
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_init_state <= `I_NOP;
        end
        else
        begin
            case(sdram_init_state)
                            //上电复位后200us结束则进入下一状态
                `I_NOP:  sdram_init_state <= done_pw_200us? `I_PRE : `I_NOP;
                            //预充电状态
                `I_PRE:  sdram_init_state <= `I_TRP;
                            //预充电等待状态, 等待TRP_CLK个时钟周期
                `I_TRP:  sdram_init_state <= (`end_trp)? `I_AR : `I_TRP;
                            //自动刷新状态
                `I_AR:   sdram_init_state <= `I_TRF;
                            //自动刷新等待状态, 等待TRC_CLK个时钟周期
                `I_TRF:  sdram_init_state <= (`end_trfc)? 
                                             //连续8次自动刷新操作
                                             ((cnt_init_ar == 4'd8)? `I_MRS : `I_AR) : `I_TRF;
                            //模式寄存器配置状态
                `I_MRS:  sdram_init_state <= `I_TRSC;
                            //模式寄存器配置等待状态, 等待TRSC_CLK个时钟周期
                `I_TRSC: sdram_init_state <= (`end_trfc)? `I_DONE : `I_TRSC;
                            //SDRAM初始化完成状态
                `I_DONE: sdram_init_state <= `I_DONE;
                                
                default: sdram_init_state <= `I_NOP;
            endcase
        end
    end
    
    //SDRAM的工作状态机,工作状态包括读、写以及自动刷新操作
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_work_state <= `W_IDLE;    //空闲状态
        end
        else
        begin
            case(sdram_work_state)
                                //定时自动刷新请求, 跳转到自动刷新状态
                `W_IDLE:    if(sdram_ref_req & sdram_init_done)
                             begin
                                sdram_work_state <= `W_AR;
                                sdram_rd_wr_ctrl <= 1'b1;
                             end
                                //写SDRAM请求, 跳转到行有效状态
                             else if(sdram_wr_req & sdram_init_done)
                             begin
                                sdram_work_state <= `W_ACTIVE;
                                sdram_rd_wr_ctrl <= 1'b0;
                             end
                                //读SDRAM请求, 跳转到行有效状态
                             else if(sdram_rd_req & sdram_init_done)
                             begin
                                sdram_work_state <= `W_ACTIVE;
                                sdram_rd_wr_ctrl <= 1'b1;
                             end
                                //无操作请求, 保持空闲状态
                             else
                             begin
                                sdram_work_state <= `W_IDLE;
                                sdram_rd_wr_ctrl <= 1'b1;
                             end
                                //行有效状态, 跳转到行有效等待状态
                `W_ACTIVE:  sdram_work_state <= `W_TRCD;
                                //行有效等待状态结束, 判断当前是读or写
                `W_TRCD:    if(`end_trcd)
                            begin
                                if(sdram_rd_wr_ctrl)    //读: 进入读操作状态
                                begin
                                    sdram_work_state <= `W_READ;
                                end
                                else                    //写: 进入写操作状态
                                begin
                                    sdram_work_state <= `W_WRITE;
                                end
                            end
                            else
                            begin
                                sdram_work_state <= `W_TRCD;
                            end
                                //读操作状态, 跳转到读潜伏期
                `W_READ:    sdram_work_state <= `W_CL;
                                //读潜伏期, 等待潜伏期结束, 跳转到读数据状态
                `W_CL:      sdram_work_state <= (`end_tcl)? `W_RD : `W_CL; 
                                //读数据状态, 等待读数据结束, 跳转到预充电状态
                `W_RD:      sdram_work_state <= (`end_tread)? `W_PRE : `W_RD;
                                //写操作状态, 跳转到写数据状态
                `W_WRITE:   sdram_work_state <= `W_WD;
                                //写数据状态, 等待写数据结束, 跳转到写回周期状态
                `W_WD:      sdram_work_state <= (`end_twrite)? `W_TWR : `W_WD;
                                //写回周期状态, 写回周期结束, 跳转到预充电状态
                `W_TWR:     sdram_work_state <= (`end_twr)? `W_PRE : `W_TWR;
                                //预充电状态, 跳转到预充电等待状态
                `W_PRE:     sdram_work_state <= `W_TRP;
                                //预充电等待状态, 预充电等待结束, 进入空闲状态
                `W_TRP:     sdram_work_state <= (`end_trp)? `W_IDLE : `W_TRP;
                                //自动刷新状态, 跳转到自动刷新等待状态
                `W_AR:      sdram_work_state <= `W_TRFC;
                                //自动刷新等待状态, 自动刷新等待结束, 进入空闲状态
                `W_TRFC:    sdram_work_state <= (`end_trfc)? `W_IDLE : `W_TRFC;

                 default:   sdram_work_state <= `W_IDLE;
            endcase
        end
    end
    
    //计数器控制逻辑
    always @(*)
    begin
        case(sdram_init_state)
                                //延时计数器清零(cnt_rst_n低电平复位)
            `I_NOP:   cnt_rst_n <= 1'b0;
                                //预充电状态, 延时计数器启动(cnt_rst_n高电平启动)
            `I_PRE:   cnt_rst_n <= 1'b1;
                                //等待预充电延时计数结束后, 清零计数器
            `I_TRP:   cnt_rst_n <= (`end_trp)? 1'b0 : 1'b1;
                                //自动刷新状态, 延时计数器启动
            `I_AR:    cnt_rst_n <= 1'b1;
                                //等待自动刷新延时计数结束后, 清零计数器 
            `I_TRF:   cnt_rst_n <= (`end_trfc)? 1'b0 : 1'b1;
                                //模式寄存器配置状态, 延时计数器启动
            `I_MRS:   cnt_rst_n <= 1'b1;
                                //等待模式寄存器配置延时计数结束后, 清零计数器
            `I_TRSC:  cnt_rst_n <= (`end_trsc)? 1'b0 : 1'b1;
            
                                //初始化完成后, 判断SDRAM工作状态
            `I_DONE:  
                begin 
                    case(sdram_work_state)
                    
                        `W_IDLE:    cnt_rst_n <= 1'b0;
                                //行有效状态, 延时计数器启动
                        `W_ACTIVE:  cnt_rst_n <= 1'b1;
                                //行有效延时计数结束后, 清零计数器
                        `W_TRCD:    cnt_rst_n <= (`end_trcd)? 1'b0 : 1'b1;
                                //读潜伏期延时计数结束后, 清零计数器
                        `W_CL:	    cnt_rst_n <= (`end_tcl)? 1'b0 : 1'b1;
                                //读数据延时计数结束后, 清零计数器
                        `W_RD:	    cnt_rst_n <= (`end_tread)? 1'b0 : 1'b1;
                                //写数据延时计数结束后, 清零计数器
                        `W_WD:	    cnt_rst_n <= (`end_twrite)? 1'b0 : 1'b1; 
                                //写回周期延时计数结束后, 清零计数器
                        `W_TWR:	    cnt_rst_n <= (`end_twr)? 1'b0 : 1'b1;
                                //预充电等待延时计数结束后, 清零计数器
                        `W_TRP:	    cnt_rst_n <= (`end_trp)? 1'b0 : 1'b1;
                                //自动刷新等待延时计数结束后, 清零计数器
                        `W_TRFC:    cnt_rst_n <= (`end_trfc)? 1'b0 : 1'b1;
                        
                        default:    cnt_rst_n <= 1'b0;
                    endcase
                end
            
            default:  cnt_rst_n <= 1'b0;
        endcase
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


















