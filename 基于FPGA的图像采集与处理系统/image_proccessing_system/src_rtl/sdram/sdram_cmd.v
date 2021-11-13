// *********************************************************************************
// 文件名: sdram_cmd.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.10
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: sdram_cmd
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)SDRAM命令控制模块
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
module sdram_cmd
(
    // clock & reset
    input 			    clk,		            //SDRAM控制器时钟
	input 			    rst_n,  		        //系统复位信号, 低电平有效

    // input signal
    input      [23 : 0] sys_wr_addr,            //写SDRAM时地址
    input      [23 : 0] sys_rd_addr,            //读SDRAM时地址
    input      [ 9 : 0] sdram_wr_burst_len,     //突发写SDRAM字节数
    input      [ 9 : 0] sdram_rd_burst_len,     //突发读SDRAM字节数
       
    input      [ 4 : 0] sdram_init_state,       //SDRAM初始化状态
    input      [ 3 : 0] sdram_work_state,       //SDRAM工作状态
    input      [ 9 : 0] cnt_clk,                //时钟计数器 
    input               sdram_rd_wr_ctrl,       //SDRAM读/写控制信号, 写(0), 读(1)
    
    // output signal                       
    output              sdram_cke,              //SDRAM时钟有效信号
    output              sdram_cs_n,             //SDRAM片选信号
    output              sdram_ras_n,            //SDRAM行地址选通脉冲
    output              sdram_cas_n,            //SDRAM列地址选通脉冲
    output              sdram_we_n,             //SDRAM写允许位
    output reg [ 1 : 0] sdram_ba,               //SDRAM的L-Bank地址线
    output reg [12 : 0] sdram_addr              //SDRAM地址总线
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
   
   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    reg        [ 4 : 0] sdram_cmd_r;            //SDRAM操作指令
	
    wire       [23 : 0] sys_addr;               //SDRAM读写地址
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    //SDRAM控制信号线赋值
    assign {sdram_cke, sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = sdram_cmd_r;
    
    //SDRAM读/写地址总线控制
    assign sys_addr = sdram_rd_wr_ctrl? sys_rd_addr : sys_wr_addr;
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    //SDRAM操作指令控制
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_cmd_r <= `CMD_INIT;
            sdram_ba <= 2'b11;
            sdram_addr <= 13'h1fff;
        end
        else
        begin
            case(sdram_init_state)
                            //初始化过程中, 以下状态不执行任何指令
                `I_NOP, `I_TRP, `I_TRF, `I_TRSC: 
                    begin
                        sdram_cmd_r <= `CMD_NOP;
                        sdram_ba    <= 2'b11;
                        sdram_addr  <= 13'h1fff;
                    end
                `I_PRE:     //预充电指令
                    begin
                        sdram_cmd_r <= `CMD_PRGE;
                        sdram_ba    <= 2'b11;
                        sdram_addr  <= 13'h1fff;
                    end
                `I_AR:      //自动刷新指令
                    begin
                        sdram_cmd_r <= `CMD_A_REF;
                        sdram_ba    <= 2'b11;
                        sdram_addr  <= 13'h1fff;
                    end
                `I_MRS:     //模式寄存器配置指令
                    begin
                        sdram_cmd_r <= `CMD_LMR;
                        sdram_ba    <= 2'b00;
                        sdram_addr  <=       //利用地址线配置模式寄存器, 可根据实际需要进行修改
                        {
                            3'b000,         //预留
                            1'b0,           //读写方式, A9=0, 突发读&突发写
                            2'b00,          //默认, {A8,A7}=00
                            3'b011,         //CAS潜伏期设置, 这里设置为3, {A6,A5,A4}=011
                            1'b0,           //突发传输方式, 这里设置为顺序, A3=0
                            3'b111          //突发长度, 这里设置为页突发, {A2,A1,A0}=011
                        };
                    end
                `I_DONE:    //SDRAM初始化完成
                    begin
                        case(sdram_work_state)
                                            //以下工作状态不执行任何指令
                            `W_IDLE, `W_TRCD, `W_CL, `W_TWR, `W_TRP, `W_TRFC:
                                begin
                                    sdram_cmd_r <= `CMD_NOP;
                                    sdram_ba    <= 2'b11;
                                    sdram_addr  <= 13'h1fff;
                                end
                            `W_ACTIVE:      //行有效指令
                                begin
                                    sdram_cmd_r <= `CMD_ACTIVE;
                                    sdram_ba    <= sys_addr[23 : 22];
                                    sdram_addr  <= sys_addr[21 : 9 ];
                                end
                            `W_READ:        //读操作指令
                                begin
                                    sdram_cmd_r <= `CMD_READ;
                                    sdram_ba    <= sys_addr[23 : 22];
                                    sdram_addr  <= {4'b0000, sys_addr[ 8 : 0 ]};
                                end
                            `W_RD:          
                                begin
                                    if(`end_rdburst)    //突发传输终止指令
                                    begin
                                        sdram_cmd_r <= `CMD_B_STOP;
                                    end
                                    else
                                    begin
                                        sdram_cmd_r <= `CMD_NOP;
                                        sdram_ba    <= 2'b11;
                                        sdram_addr  <= 13'h1fff;
                                    end
                                end
                            `W_WRITE:       //写操作指令
                                begin
                                    sdram_cmd_r <= `CMD_WRITE;
                                    sdram_ba    <= sys_addr[23 : 22];
                                    sdram_addr  <= {4'b0000, sys_addr[ 8 : 0 ]};
                                end
                            `W_WD:
                                begin
                                    if(`end_wrburst)    //突发传输终止指令
                                    begin
                                        sdram_cmd_r <= `CMD_B_STOP;
                                    end
                                    else
                                    begin
                                        sdram_cmd_r <= `CMD_NOP;
                                        sdram_ba    <= 2'b11;
                                        sdram_addr  <= 13'h1fff;
                                    end
                                end
                            `W_PRE:         //预充电指令
                                begin
                                    sdram_cmd_r <= `CMD_PRGE;
                                    sdram_ba    <= sys_addr[23 : 22];
                                    sdram_addr  <= 13'h0400;
                                end
                            `W_AR:          //自动刷新指令
                                begin
                                    sdram_cmd_r <= `CMD_A_REF;
                                    sdram_ba    <= 2'b11;
                                    sdram_addr  <= 13'h1fff;
                                end
                            default:
                                begin
                                    sdram_cmd_r <= `CMD_NOP;
                                    sdram_ba    <= 2'b11;
                                    sdram_addr  <= 13'h1fff;
                                end
                        endcase
                    end
                default:
                    begin
                        sdram_cmd_r <= `CMD_NOP;
                        sdram_ba    <= 2'b11;
                        sdram_addr  <= 13'h1fff;
                    end
            endcase
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