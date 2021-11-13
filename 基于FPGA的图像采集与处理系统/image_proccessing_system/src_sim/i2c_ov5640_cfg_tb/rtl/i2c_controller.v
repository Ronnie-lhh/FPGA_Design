// *********************************************************************************
// 文件名: i2c_controller.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.16
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: i2c_controller
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)IIC驱动模块
//            2)适用于使用IIC协议的应用场景
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
module i2c_controller
#(
    // parameter passing
    parameter   SLAVE_ADDR = 7'h3c,             //器件地址
    parameter   CLK_FREQ   = 27'd100_000_000,   //模块的驱动时钟频率
    parameter   I2C_FREQ   = 18'd250_000        //I2C的SCL时钟频率
)
(
    // clock & reset
    input 			    clk,		            //模块的驱动时钟
	input 			    rst_n,  		        //复位信号, 低电平有效

    // i2c interface
    input               i2c_exec,               //I2C触发执行信号
    input               bit_ctrl,               //字地址位控制(16b/8b)
    input               i2c_rw_ctrl,            //I2C读写控制信号, 读(1)/写(0)
    input      [15 : 0] i2c_addr,               //I2C器件内地址
    input      [ 7 : 0] i2c_wr_data,            //I2C要写的数据
    output reg [ 7 : 0] i2c_rd_data,            //I2C读出的数据
    output reg          i2c_done,               //I2C一次操作完成标志
    output reg          scl,                    //I2C的SCL时钟信号
    inout               sda,                    //I2C的SDA信号
    
    // user interface
    output reg          clk_dri                 //I2C操作的驱动时钟
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
   //有限状态机的状态定义
   localparam   S_IDLE      = 8'b00000001;      //空闲状态
   localparam   S_SLADDR    = 8'b00000010;      //发送器件地址
   localparam   S_ADDR16    = 8'b00000100;      //发送16位字地址
   localparam   S_ADDR8     = 8'b00001000;      //发送8位字地址
   localparam   S_WR_DATA   = 8'b00010000;      //写数据(8 bit)
   localparam   S_RD_ADDR   = 8'b00100000;      //发送器件地址读
   localparam   S_RD_DATA   = 8'b01000000;      //读数据(8 bit)
   localparam   S_STOP      = 8'b10000000;      //结束I2C操作

// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    reg                 sda_en;                 //SDA数据方向控制信号
    reg                 sda_out;                //SDA输出信号
    reg                 s_done;                 //状态结束标志
    reg                 wr_flag;                //写标志
    reg        [ 6 : 0] cnt;                    //时钟周期计数器
    reg        [ 7 : 0] cur_state;              //状态机当前状态
    reg        [ 7 : 0] nxt_state;              //状态机下一状态
    reg        [15 : 0] addr_t;                 //地址
    reg        [ 7 : 0] rd_data;                //读取的数据
    reg        [ 7 : 0] wr_data_t;              //I2C需写数据的临时寄存
    reg        [ 9 : 0] clk_cnt;                //分频时钟计数
	
    wire                sda_in;                 //SDA输入信号
    wire       [ 8 : 0] clk_div;                //模块驱动时钟的分频系数
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    //SDA控制
    assign sda     = sda_en? sda_out : 1'bz;         //当SDA为输入时, 输出拉至高阻
    assign sda_in  = sda;                            //SDA数据输入
    assign clk_div = (CLK_FREQ / I2C_FREQ) >> 2'd2;  //模块驱动时钟的分频系数
    
    //I2C读写控制信号固定为高电平, 只用到了I2C的写操作
    assign  i2c_rw_ctrl = 1'b0;
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    //生成I2C SCL的四倍频率的驱动时钟用于驱动I2C的操作
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            clk_dri <= 1'b1;
            clk_cnt <= 10'd0;
        end
        else if(clk_cnt == clk_div[8 : 1] - 9'd1)   //分频系数/2 - 1
        begin
            clk_cnt <= 10'd0;
            clk_dri <= ~clk_dri;
        end
        else 
        begin
            clk_cnt <= clk_cnt + 10'd1;
            clk_dri <= clk_dri;
        end
    end
    
    //(三段式状态机)同步时序描述状态转移
    always @(posedge clk_dri or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cur_state <= S_IDLE;
        end
        else 
        begin
            cur_state <= nxt_state;
        end
    end
    
    //组合逻辑判断状态转移条件
    always @(*)
    begin
        case(cur_state)
                        //空闲状态
            S_IDLE:
                begin
                    if(i2c_exec)
                    begin 
                        nxt_state = S_SLADDR;
                    end
                    else
                    begin
                        nxt_state = S_IDLE;
                    end
                end
                        //发送器件地址
            S_SLADDR:
                begin
                    if(s_done)            //当前状态执行完成
                    begin
                        if(bit_ctrl)      //判断是16位还是8位字地址
                        begin
                            nxt_state = S_ADDR16;
                        end
                        else
                        begin
                            nxt_state = S_ADDR8;
                        end
                    end
                    else 
                    begin
                        nxt_state = S_SLADDR;
                    end
                end
                        //发送16位字地址
            S_ADDR16:
                begin
                    if(s_done)
                    begin
                        nxt_state = S_ADDR8;
                    end
                    else
                    begin
                        nxt_state = S_ADDR16;
                    end
                end
                        //发送8位字地址
            S_ADDR8:
                begin
                    if(s_done)
                    begin
                        if(!wr_flag)     //若写标志为低, 则写数据
                        begin
                            nxt_state = S_WR_DATA;
                        end
                        else             //若写标志为高, 则读数据
                        begin
                            nxt_state = S_RD_ADDR;
                        end
                    end
                    else
                    begin
                        nxt_state = S_ADDR8;
                    end
                end
                        //写数据(8 bit)
            S_WR_DATA:
                begin
                    if(s_done)
                    begin
                        nxt_state = S_STOP;
                    end
                    else
                    begin
                        nxt_state = S_WR_DATA;
                    end
                end
                        //发送器件地址读
            S_RD_ADDR:
                begin
                    if(s_done)
                    begin
                        nxt_state = S_RD_DATA;
                    end
                    else
                    begin
                        nxt_state = S_RD_ADDR;
                    end
                end
                        //读数据(8 bit)
            S_RD_DATA:
                begin
                    if(s_done)
                    begin
                        nxt_state = S_STOP;
                    end
                    else
                    begin
                        nxt_state = S_RD_DATA;
                    end
                end
                        //结束I2C操作
            S_STOP:
                begin
                    if(s_done)
                    begin
                        nxt_state = S_IDLE;
                    end
                    else
                    begin
                        nxt_state = S_STOP;
                    end
                end
                
            default:
                begin
                    nxt_state = S_IDLE;
                end
        endcase
    end
    
    //时序电路描述状态输出
    always @(posedge clk_dri or negedge rst_n)
    begin
        if(!rst_n)
        begin
            scl         <=  1'b1; 
            sda_out     <=  1'b1;
            sda_en      <=  1'b1;
            i2c_done    <=  1'b0;
            s_done      <=  1'b0;
            wr_flag     <=  1'b0;
            cnt         <=  7'd0;
            rd_data     <=  8'd0;
            i2c_rd_data <=  8'd0;
            wr_data_t   <=  8'd0;
            addr_t      <= 16'd0;
        end
        else
        begin
            s_done <= 1'b0;
            cnt    <= cnt + 7'd1;
            case(cur_state)
                            //空闲状态
                S_IDLE:
                    begin
                        scl         <= 1'b1;
                        sda_out     <= 1'b1;
                        sda_en      <= 1'b1;
                        i2c_done    <= 1'b0;
                        cnt         <= 7'd0;
                        if(i2c_exec)        //I2C触发执行
                        begin
                            wr_flag     <= i2c_rw_ctrl;
                            addr_t      <= i2c_addr;
                            wr_data_t   <= i2c_wr_data;
                        end
                        else 
                        begin
                            wr_flag     <= wr_flag;
                            addr_t      <= addr_t;
                            wr_data_t   <= wr_data_t;
                        end
                    end
                            //发送器件地址
                S_SLADDR:
                    begin
                        case(cnt)
                            7'd1 : sda_out <= 1'b0;             //开始I2C
                            7'd3 : scl <= 1'b0;
                            7'd4 : sda_out <= SLAVE_ADDR[6];    //发送器件地址
                            7'd5 : scl <= 1'b1;
                            7'd7 : scl <= 1'b0;
                            7'd8 : sda_out <= SLAVE_ADDR[5];
                            7'd9 : scl <= 1'b1;
                            7'd11: scl <= 1'b0;
                            7'd12: sda_out <= SLAVE_ADDR[4];
                            7'd13: scl <= 1'b1;
                            7'd15: scl <= 1'b0;
                            7'd16: sda_out <= SLAVE_ADDR[3];
                            7'd17: scl <= 1'b1;
                            7'd19: scl <= 1'b0;
                            7'd20: sda_out <= SLAVE_ADDR[2];
                            7'd21: scl <= 1'b1;
                            7'd23: scl <= 1'b0;
                            7'd24: sda_out <= SLAVE_ADDR[1];
                            7'd25: scl <= 1'b1;
                            7'd27: scl <= 1'b0;
                            7'd28: sda_out <= SLAVE_ADDR[0];
                            7'd29: scl <= 1'b1;
                            7'd31: scl <= 1'b0;
                            7'd32: sda_out <= 1'b0;             //发送读写标志位, 读(1)/写(0)
                            7'd33: scl <= 1'b1;
                            7'd35: scl <= 1'b0;
                            7'd36:                              //从机应答
                                begin
                                    sda_en  <= 1'b0;
                                    sda_out <= 1'b1;
                                end
                            7'd37: scl <= 1'b1;
                            7'd38: s_done <= 1'b1;              //当前状态执行完成
                            7'd39: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //时钟周期计数器清零
                                end
                            default: ; 
                        endcase
                    end
                            //发送16位字地址
                S_ADDR16:
                    begin
                        case(cnt)
                            7'd0 :                              //发送字地址
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= addr_t[15];
                                end
                            7'd1 : scl <= 1'b1;
                            7'd3 : scl <= 1'b0;
                            7'd4 : sda_out <= addr_t[14];
                            7'd5 : scl <= 1'b1;
                            7'd7 : scl <= 1'b0;
                            7'd8 : sda_out <= addr_t[13];
                            7'd9 : scl <= 1'b1;
                            7'd11: scl <= 1'b0;
                            7'd12: sda_out <= addr_t[12];
                            7'd13: scl <= 1'b1;
                            7'd15: scl <= 1'b0;
                            7'd16: sda_out <= addr_t[11];
                            7'd17: scl <= 1'b1;
                            7'd19: scl <= 1'b0;
                            7'd20: sda_out <= addr_t[10];
                            7'd21: scl <= 1'b1;
                            7'd23: scl <= 1'b0;
                            7'd24: sda_out <= addr_t[9];
                            7'd25: scl <= 1'b1;
                            7'd27: scl <= 1'b0;
                            7'd28: sda_out <= addr_t[8];
                            7'd29: scl <= 1'b1;
                            7'd31: scl <= 1'b0;
                            7'd32:                              //从机应答
                                begin
                                    sda_en  <= 1'b0;
                                    sda_out <= 1'b1;
                                end
                            7'd33: scl <= 1'b1;
                            7'd34: s_done <= 1'b1;              //当前状态执行完成
                            7'd35: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //时钟周期计数器清零
                                end
                            default: ; 
                        endcase
                    end
                            //发送8位字地址
                S_ADDR8:
                    begin
                        case(cnt)
                            7'd0 :                              //发送字地址
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= addr_t[7];
                                end
                            7'd1 : scl <= 1'b1;
                            7'd3 : scl <= 1'b0;
                            7'd4 : sda_out <= addr_t[6];
                            7'd5 : scl <= 1'b1;
                            7'd7 : scl <= 1'b0;
                            7'd8 : sda_out <= addr_t[5];
                            7'd9 : scl <= 1'b1;
                            7'd11: scl <= 1'b0;
                            7'd12: sda_out <= addr_t[4];
                            7'd13: scl <= 1'b1;
                            7'd15: scl <= 1'b0;
                            7'd16: sda_out <= addr_t[3];
                            7'd17: scl <= 1'b1;
                            7'd19: scl <= 1'b0;
                            7'd20: sda_out <= addr_t[2];
                            7'd21: scl <= 1'b1;
                            7'd23: scl <= 1'b0;
                            7'd24: sda_out <= addr_t[1];
                            7'd25: scl <= 1'b1;
                            7'd27: scl <= 1'b0;
                            7'd28: sda_out <= addr_t[0];
                            7'd29: scl <= 1'b1;
                            7'd31: scl <= 1'b0;
                            7'd32:                              //从机应答
                                begin
                                    sda_en  <= 1'b0;
                                    sda_out <= 1'b1;
                                end
                            7'd33: scl <= 1'b1;
                            7'd34: s_done <= 1'b1;              //当前状态执行完成
                            7'd35: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //时钟周期计数器清零
                                end
                            default: ; 
                        endcase
                    end
                            //写数据(8 bit)
                S_WR_DATA:
                    begin
                        case(cnt)
                            7'd0 :                              //I2C写8位数据
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= wr_data_t[7];
                                end
                            7'd1 : scl <= 1'b1;
                            7'd3 : scl <= 1'b0;
                            7'd4 : sda_out <= wr_data_t[6];
                            7'd5 : scl <= 1'b1;
                            7'd7 : scl <= 1'b0;
                            7'd8 : sda_out <= wr_data_t[5];
                            7'd9 : scl <= 1'b1;
                            7'd11: scl <= 1'b0;
                            7'd12: sda_out <= wr_data_t[4];
                            7'd13: scl <= 1'b1;
                            7'd15: scl <= 1'b0;
                            7'd16: sda_out <= wr_data_t[3];
                            7'd17: scl <= 1'b1;
                            7'd19: scl <= 1'b0;
                            7'd20: sda_out <= wr_data_t[2];
                            7'd21: scl <= 1'b1;
                            7'd23: scl <= 1'b0;
                            7'd24: sda_out <= wr_data_t[1];
                            7'd25: scl <= 1'b1;
                            7'd27: scl <= 1'b0;
                            7'd28: sda_out <= wr_data_t[0];
                            7'd29: scl <= 1'b1;
                            7'd31: scl <= 1'b0;
                            7'd32:                              //从机应答
                                begin
                                    sda_en  <= 1'b0;
                                    sda_out <= 1'b1;
                                end
                            7'd33: scl <= 1'b1;
                            7'd34: s_done <= 1'b1;              //当前状态执行完成
                            7'd35: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //时钟周期计数器清零
                                end
                            default: ; 
                        endcase
                    end
                            //发送器件地址读
                S_RD_ADDR:
                    begin
                        case(cnt)
                            7'd0 :
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= 1'b1;
                                end
                            7'd1 : scl <= 1'b1;
                            7'd2 : sda_out <= 1'b0;             //重新发送开始信号
                            7'd3 : scl <= 1'b0;
                            7'd4 : sda_out <= SLAVE_ADDR[6];    //发送器件地址
                            7'd5 : scl <= 1'b1;
                            7'd7 : scl <= 1'b0;
                            7'd8 : sda_out <= SLAVE_ADDR[5];
                            7'd9 : scl <= 1'b1;
                            7'd11: scl <= 1'b0;
                            7'd12: sda_out <= SLAVE_ADDR[4];
                            7'd13: scl <= 1'b1;
                            7'd15: scl <= 1'b0;
                            7'd16: sda_out <= SLAVE_ADDR[3];
                            7'd17: scl <= 1'b1;
                            7'd19: scl <= 1'b0;
                            7'd20: sda_out <= SLAVE_ADDR[2];
                            7'd21: scl <= 1'b1;
                            7'd23: scl <= 1'b0;
                            7'd24: sda_out <= SLAVE_ADDR[1];
                            7'd25: scl <= 1'b1;
                            7'd27: scl <= 1'b0;
                            7'd28: sda_out <= SLAVE_ADDR[0];
                            7'd29: scl <= 1'b1;
                            7'd31: scl <= 1'b0;
                            7'd32: sda_out <= 1'b1;             //发送读写标志位, 读(1)/写(0)
                            7'd33: scl <= 1'b1;
                            7'd35: scl <= 1'b0;
                            7'd36:                              //从机应答
                                begin
                                    sda_en  <= 1'b0;
                                    sda_out <= 1'b1;
                                end
                            7'd37: scl <= 1'b1;
                            7'd38: s_done <= 1'b1;              //当前状态执行完成
                            7'd39: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //时钟周期计数器清零
                                end
                            default: ; 
                        endcase
                    end
                            //读数据(8 bit)
                S_RD_DATA:
                    begin
                        case(cnt)
                            7'd0 : sda_en <= 1'b0;              //将SDA数据线切为输入
                            7'd1 : 
                                begin
                                    rd_data[7] <= sda_in;       //读取从机数据
                                    scl <= 1'b1;
                                end
                            7'd3 : scl <= 1'b0;
                            7'd5 : 
                                begin
                                    rd_data[6] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd7 : scl <= 1'b0;
                            7'd9 : 
                                begin
                                    rd_data[5] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd11: scl <= 1'b0;
                            7'd13: 
                                begin
                                    rd_data[4] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd15: scl <= 1'b0;
                            7'd17: 
                                begin
                                    rd_data[3] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd19: scl <= 1'b0;
                            7'd21: 
                                begin
                                    rd_data[2] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd23: scl <= 1'b0;
                            7'd25: 
                                begin
                                    rd_data[1] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd27: scl <= 1'b0;
                            7'd29: 
                                begin
                                    rd_data[0] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd31: scl <= 1'b0;
                            7'd32:                              //主机非应答
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= 1'b1;
                                end
                            7'd33: scl <= 1'b0;
                            7'd34: s_done <= 1'b1;              //当前状态执行完成
                            7'd35: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //时钟周期计数器清零
                                    i2c_rd_data <= rd_data;
                                end
                            default: ;
                        endcase
                    end
                            //结束I2C操作
                S_STOP:
                    begin
                        case(cnt)
                            7'd0 : 
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= 1'b0;
                                end
                            7'd1 : scl <= 1'b1;
                            7'd3 : sda_out <= 1'b1;             //发送结束信号
                            7'd15: s_done <= 1'b1;              //当前状态执行完成
                            7'd16: 
                                begin
                                    cnt <= 7'd0;                //时钟周期计数器清零
                                    i2c_done <= 1'b1;           //I2C一次操作完成
                                end
                            default: ;
                        endcase
                    end

                default: ;
                    // begin
                        // ;
                    // end
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