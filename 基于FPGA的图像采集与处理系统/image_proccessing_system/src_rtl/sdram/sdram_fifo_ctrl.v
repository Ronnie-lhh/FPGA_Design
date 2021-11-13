// *********************************************************************************
// 文件名: sdram_fifo_ctrl.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.8
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: sdram_fifo_ctrl
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)SDRAM读写端口FIFO控制模块    
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
module sdram_fifo_ctrl
(
    // clock & reset
    input 			     clk_ref,		         //SDRAM控制器时钟
	input 			     rst_n,  		         //系统复位信号, 低电平有效

    // 用户写端口
    input                clk_write,              //写端口FIFO: 写时钟 
    input                wrf_wrreq,              //写端口FIFO: 写请求 
    input       [15 : 0] wrf_din,                //写端口FIFO: 写数据 
    input       [23 : 0] wr_min_addr,            //写SDRAM的起始地址
    input       [23 : 0] wr_max_addr,            //写SDRAM的结束地址
    input       [ 9 : 0] wr_len,                 //写SDRAM的数据突发长度 
    input                wr_load,                //写端口复位: 复位写地址, 清空写FIFO 
    
    // 用户读端口
    input                clk_read,               //读端口FIFO: 读时钟
    input                rdf_rdreq,              //读端口FIFO: 读请求 
    output      [15 : 0] rdf_dout,               //读端口FIFO: 读数据
    input       [23 : 0] rd_min_addr,            //读SDRAM的起始地址
    input       [23 : 0] rd_max_addr,            //读SDRAM的结束地址
    input       [ 9 : 0] rd_len,                 //从SDRAM中读数据的突发长度 
    input                rd_load,                //读端口复位: 复位读地址, 清空读FIFO
    
    // 用户控制端口
    input                sdram_read_valid,       //SDRAM读使能
    input                sdram_init_done,        //SDRAM初始化完成标志
    input                sdram_pingpang_en,      //SDRAM读写乒乓操作使能
    
    // SDRAM控制器写端口
    output reg           sdram_wr_req,           //SDRAM写请求
    input                sdram_wr_ack,           //SDRAM写响应
    output reg  [23 : 0] sdram_wr_addr,          //SDRAM写地址
    output      [15 : 0] sdram_din,              //写入SDRAM中的数据 
                                                 
    // SDRAM控制器读端口                          
    output reg           sdram_rd_req,           //SDRAM读请求
    input                sdram_rd_ack,           //SDRAM读响应
    output reg  [23 : 0] sdram_rd_addr,          //SDRAM读地址 
    input       [15 : 0] sdram_dout              //从SDRAM中读出的数据 
);

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
   
   
// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    reg             wr_ack_r1;                   //SDRAM写响应寄存器    
    reg             wr_ack_r2;                   
    reg             rd_ack_r1;                   //SDRAM读响应寄存器    
	reg             rd_ack_r2;                   
    reg             wr_load_r1;                  //写端口复位寄存器     
    reg             wr_load_r2;                  
    reg             rd_load_r1;                  //读端口复位寄存器     
    reg             rd_load_r2;                  
    reg             read_valid_r1;               //SDRAM读使能寄存器    
    reg             read_valid_r2;               
    reg             sw_bank_en;                  //切换BANK使能信号
    reg             rw_bank_flag;                //读写BANK标志信号
    
    wire            wr_done_flag;                //sdram_wr_ack下降沿标志位 
    wire            rd_done_flag;                //sdram_rd_ack下降沿标志位 
    wire            wr_load_flag;                //wr_load上升沿标志位 
    wire            rd_load_flag;                //rd_load上升沿标志位 
    wire [9 : 0]    wrf_use;                     //写端口FIFO中的数据量
    wire [9 : 0]    rdf_use;                     //读端口FIFO中的数据量
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    //检测下降沿
    assign wr_done_flag = wr_ack_r2 & ~wr_ack_r1;
    assign rd_done_flag = rd_ack_r2 & ~rd_ack_r1;
    
    //检测上升沿
    assign wr_load_flag = ~wr_load_r2 & wr_load_r1;
    assign rd_load_flag = ~rd_load_r2 & rd_load_r1;
    
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    //寄存SDRAM写响应信号, 用于捕获sdram_wr_ack下降沿
    always @(posedge clk_ref or negedge rst_n)
    begin
        if(!rst_n)
        begin
            wr_ack_r1 <= 1'b0;
            wr_ack_r2 <= 1'b0;
        end
        else 
        begin
            wr_ack_r1 <= sdram_wr_ack;
            wr_ack_r2 <= wr_ack_r1;
        end
    end

    //寄存SDRAM读响应信号, 用于捕获sdram_rd_ack下降沿
    always @(posedge clk_ref or negedge rst_n) 
    begin
        if(!rst_n) 
        begin
            rd_ack_r1 <= 1'b0;
            rd_ack_r2 <= 1'b0;
        end
        else 
        begin
            rd_ack_r1 <= sdram_rd_ack;
            rd_ack_r2 <= rd_ack_r1;
        end
    end 

    //同步写端口复位信号, 用于捕获wr_load上升沿 (跨时钟域同步)
    always @(posedge clk_ref or negedge rst_n) 
    begin
        if(!rst_n) 
        begin
            wr_load_r1 <= 1'b0;
            wr_load_r2 <= 1'b0;
        end
        else 
        begin
            wr_load_r1 <= wr_load;
            wr_load_r2 <= wr_load_r1;
        end
    end

    //同步读端口复位信号, 用于捕获rd_load上升沿 (跨时钟域同步)
    always @(posedge clk_ref or negedge rst_n) 
    begin
        if(!rst_n) 
        begin
            rd_load_r1 <= 1'b0;
            rd_load_r2 <= 1'b0;
        end
        else 
        begin
            rd_load_r1 <= rd_load;
            rd_load_r2 <= rd_load_r1;
        end
    end
    
    //同步SDRAM读使能信号 (跨时钟域同步)
    always @(posedge clk_ref or negedge rst_n) 
    begin
        if(!rst_n) 
        begin
            read_valid_r1 <= 1'b0;
            read_valid_r2 <= 1'b0;
        end
        else 
        begin
            read_valid_r1 <= sdram_read_valid;
            read_valid_r2 <= read_valid_r1;
        end
    end

    //SDRAM写地址产生模块
    always @(posedge clk_ref or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_wr_addr <= 24'd0;
            sw_bank_en <= 1'b0;
            rw_bank_flag <= 1'b0;
        end
        //检测到写端口复位信号时, 写地址复位
        else if(wr_load_flag)       
        begin
            sdram_wr_addr <= wr_min_addr;
            sw_bank_en <= 1'b0;
            rw_bank_flag <= 1'b0;
        end
        //若突发写SDRAM结束, 更改写地址
        else if(wr_done_flag)
        begin
            //若SDRAM读写使能乒乓操作
            if(sdram_pingpang_en)
            begin
                //若未到达写SDRAM的结束地址, 则写地址累加
                if(sdram_wr_addr[22 : 0] < wr_max_addr - wr_len)
                begin
                    sdram_wr_addr <= sdram_wr_addr + wr_len;
                end
                //若到达写SDRAM的结束地址, 则切换BANK
                else
                begin
                    rw_bank_flag <= ~rw_bank_flag;
                    sw_bank_en <= 1'b1;             //拉高切换BANK使能信号
                end
            end
            
            //若不使能乒乓操作, 若未到达写SDRAM的结束地址, 则写地址累加
            else if(sdram_wr_addr < wr_max_addr - wr_len)
            begin
                sdram_wr_addr <= sdram_wr_addr + wr_len;
            end
            //若不使能乒乓操作, 若到达写SDRAM的结束地址, 则回到写起始地址
            else
            begin
                sdram_wr_addr <= wr_min_addr;
            end
        end
        //若切换BANK使能信号为高 (针对乒乓读写操作的情况)
        else if(sw_bank_en) 
        begin
            sw_bank_en <= 1'b0;         //拉低切换BANK使能信号
            //若读写BANK标志信号为0, 则切换为BANK0
            if(rw_bank_flag == 1'b0)
            begin
                sdram_wr_addr <= {1'b0, wr_min_addr[22 : 0]};
            end
            //若读写BANK标志信号为1, 则切换为BANK1
            else
            begin
                sdram_wr_addr <= {1'b1, wr_min_addr[22 : 0]};
            end
        end
        
        else
        begin
            sdram_wr_addr <= sdram_wr_addr;
            sw_bank_en <= sw_bank_en;
            rw_bank_flag <= rw_bank_flag;
        end
    end
    
    //SDRAM读地址产生模块
    always @(posedge clk_ref or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_rd_addr <= 24'd0;
        end
        //检测到读端口复位信号时，读地址复位
        else if(rd_load_flag)
        begin
            sdram_rd_addr <= rd_min_addr;
        end
        //突发读SDRAM结束, 更改读地址
        else if(rd_done_flag)
        begin
            //若SDRAM读写使能乒乓操作
            if(sdram_pingpang_en)
            begin
                //若未到达读SDRAM的结束地址, 则读地址累加
                if(sdram_rd_addr[22 : 0] < rd_max_addr - rd_len)
                begin
                    sdram_rd_addr <= sdram_rd_addr + rd_len;
                end
                //若到达读SDRAM的结束地址, 则回到读起始地址
                //读取没有正在写数据的BANK
                else
                begin
                    //根据rw_bank_flag的值切换读BANK地址
                    if(rw_bank_flag == 1'b0)
                    begin
                        sdram_rd_addr <= {1'b1, rd_min_addr[22 : 0]};
                    end
                    else 
                    begin
                        sdram_rd_addr <= {1'b0, rd_min_addr[22 : 0]};
                    end
                end
            end
            
            //若不使能乒乓操作, 若未到达读SDRAM的结束地址, 则读地址累加
            else if(sdram_rd_addr < rd_max_addr - rd_len)
            begin
                sdram_rd_addr <= sdram_rd_addr + rd_len;
            end
            //若不使能乒乓操作, 若到达读SDRAM的结束地址, 则回到读起始地址
            else
            begin
                sdram_rd_addr <= rd_min_addr;
            end
        end
        
        else
        begin
            sdram_rd_addr <= sdram_rd_addr;
        end
    end

    //SDRAM读写请求信号产生模块
    always @(posedge clk_ref or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_wr_req <= 1'b0;
            sdram_rd_req <= 1'b0;
        end
        //SDRAM初始化完成后才能响应读写请求
        //优先执行写操作, 防止写入SDRAM中的数据丢失
        else if(sdram_init_done)
        begin
            //若写端口FIFO中的数据量达到了写突发长度, 则发出写SDRAM请求
            if(wrf_use >= wr_len)
            begin
                sdram_wr_req <= 1'b1;
                sdram_rd_req <= 1'b0;
            end
            //若读端口FIFO中的数据量小于读突发长度, 
            //同时SDRAM读使能信号为高, 则发出读SDRAM请求
            else if((rdf_use < rd_len) && read_valid_r2)
            begin
                sdram_wr_req <= 1'b0;
                sdram_rd_req <= 1'b1;
            end
            else 
            begin
                sdram_wr_req <= 1'b0;
                sdram_rd_req <= 1'b0;
            end
        end
        else
        begin
            sdram_wr_req <= 1'b0;
            sdram_rd_req <= 1'b0;
        end
    end


// ---------------------------------------------------------------------------------
// 结构化描述 Moudle Instantiate
// ---------------------------------------------------------------------------------
    // 例化写端口FIFO
    wr_fifo     U_wr_fifo
    (
        //用户接口
        .wr_clk                 (clk_write),                //写时钟
        .wr_en                  (wrf_wrreq),                //写请求
        .din                    (wrf_din),                  //写数据
        //SDRAM接口
        .rd_clk                 (clk_ref),                  //读时钟
        .rd_en                  (sdram_wr_ack),             //读请求
        .dout                   (sdram_din),                //读数据

        .rd_data_count          (wrf_use),                  //FIFO中的可读数据量
        .rst                    (~rst_n | wr_load_flag),    //异步清零信号
        .full                   (),                         //FIFO满信号
        .empty                  (),                         //FIFO空信号
        .wr_data_count          ()                          //FIFO中的已写数据量
    );
    
    
    // 例化读端口FIFO
    rd_fifo     U_rd_fifo
    (
        //SDRAM接口
        .wr_clk                 (clk_ref),                  //写时钟
        .wr_en                  (sdram_rd_ack),             //写请求
        .din                    (sdram_dout),               //写数据
        //用户接口                                          
        .rd_clk                 (clk_read),                 //读时钟
        .rd_en                  (rdf_rdreq),                //读请求
        .dout                   (rdf_dout),                 //读数据

        .rd_data_count          (),                         //FIFO中的可读数据量
        .rst                    (~rst_n | rd_load_flag),    //异步清零信号
        .full                   (),                         //FIFO满信号
        .empty                  (),                         //FIFO空信号
        .wr_data_count          (rdf_use)                   //FIFO中的已写数据量
    );


// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------
    
	
// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------

    
endmodule 