// *********************************************************************************
// 文件名: img_proc_median_tb.v   
// 创建人: 梁辉鸿
// 创建日期: 2021.3.30
// 联系方式: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// 模块名: img_proc_median_tb
// 发布版本号: V0.0
// --------------------------------------------------------------------------------- 
// 功能说明: 1)Testbench for 图像处理算法模块
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
`timescale  1ns/1ns

// ---------------------------------------------------------------------------------
// 常量参数 Constant Parameters
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// 模块定义 Module Define
// --------------------------------------------------------------------------------- 
module img_proc_median_tb;

// ---------------------------------------------------------------------------------
// 局部常量 Local Constant Parameters
// ---------------------------------------------------------------------------------
    ////////////////////////////////////////////产生摄像头时序 
    parameter [10:0] IMG_HDISP = 11'd720;
    parameter [10:0] IMG_VDISP = 11'd713;

    localparam H_SYNC = 11'd5;		
    localparam H_BACK = 11'd5;		
    localparam H_DISP = IMG_HDISP;	
    localparam H_FRONT = 11'd5;		
    localparam H_TOTAL = H_SYNC + H_BACK + H_DISP + H_FRONT;	

    localparam V_SYNC = 11'd1;		
    localparam V_BACK = 11'd0;		
    localparam V_DISP = IMG_VDISP;	
    localparam V_FRONT = 11'd1;		
    localparam V_TOTAL = V_SYNC + V_BACK + V_DISP + V_FRONT;
    
    

// ---------------------------------------------------------------------------------
// 模块内变量定义 Module_Variables
// --------------------------------------------------------------------------------- 
    integer iBmpFileId;                 //输入BMP图片
    integer oBmpFileId;                 //输出BMP图片
    integer oTxtFileId;                 //输入TXT文本
            
    integer iIndex = 0;                 //输出BMP数据索引
    integer pixel_index = 0;            //输出像素数据索引 
            
    integer iCode;      
            
    integer iBmpWidth;                  //输入BMP 宽度
    integer iBmpHight;                  //输入BMP 高度
    integer iBmpSize;                   //输入BMP 字节数
    integer iDataStartIndex;            //输入BMP 像素数据偏移量
        
    reg [ 7:0] rBmpData [0:2000000];    //用于寄存输入BMP图片中的字节数据（包括54字节的文件头）
    reg [ 7:0] Vip_BmpData [0:2000000]; //用于寄存视频图像处理之后 的BMP图片 数据 
    reg [31:0] rBmpWord;                //输出BMP图片时用于寄存数据（以word为单位，即4byte）
    
    reg [ 7:0] pixel_data;              //输出视频流时的像素数据
    
    reg clk;                            //50MHz
    reg rst_n;
    
    reg [ 7:0] vip_pixel_data [0:1540080];   //720x713x3
    
        
    ////////////////////////////////////////////产生摄像头时序 
    wire		cmos_vsync;
    reg			cmos_href;
    wire        cmos_clken;
    reg	[23:0]	cmos_data;			 

    reg [31:0]  cmos_index;
    
    //-------------------------------------
    //从数组中以视频格式输出像素数据
    wire [10:0] x_pos;
    wire [10:0] y_pos;
    
    //-------------------------------------
    //VIP算法——彩色转灰度
    wire 		per_frame_vsync	=	cmos_vsync ;	
    wire 		per_frame_href	=	cmos_href;	
    wire 		per_frame_clken	=	cmos_clken;	
    wire [7:0]	per_img_red		=	cmos_data[23:16];	   	
    wire [7:0]	per_img_green	=	cmos_data[15: 8];   	            
    wire [7:0]	per_img_blue	=	cmos_data[ 7: 0];   	            


    wire 		post0_frame_vsync;   
    wire 		post0_frame_href ;   
    wire 		post0_frame_clken;    
    wire [7:0]	post0_img_Y      ;   
    wire [7:0]	post0_img_Cb     ;   
    wire [7:0]	post0_img_Cr     ;   
    
    //--------------------------------------
    //VIP 算法——Sobel边缘检测
    wire			post1_frame_vsync;	 
    wire			post1_frame_href;	 
    wire			post1_frame_clken;	 
    wire			post1_img_Bit;
    
    //-------------------------------------
    //寄存图像处理之后的像素数据
    wire 		vip_out_frame_vsync;   
    wire 		vip_out_frame_href ;   
    wire 		vip_out_frame_clken;    
    wire [7:0]	vip_out_img_R     ;   
    wire [7:0]	vip_out_img_G     ;   
    wire [7:0]	vip_out_img_B     ;  
    
    reg [31:0] vip_cnt;
 
    reg         vip_vsync_r;    //寄存VIP输出的场同步 
    reg         vip_out_en;     //寄存VIP处理图像的使能信号，仅维持一帧的时间
    
    
// ---------------------------------------------------------------------------------
// 数据流描述 Continuous Assignments
// --------------------------------------------------------------------------------- 
    //---------------------------------------------
    //Image data href vaild  signal
    wire	frame_valid_ahead =  ( vcnt >= V_SYNC + V_BACK  && vcnt < V_SYNC + V_BACK + V_DISP
                                && hcnt >= H_SYNC + H_BACK  && hcnt < H_SYNC + H_BACK + H_DISP ) 
                            ? 1'b1 : 1'b0;
          
    reg			cmos_href_r;
    
    //-------------------------------------
    //从数组中以视频格式输出像素数据
    assign x_pos = frame_valid_ahead ? (hcnt - (H_SYNC + H_BACK )) : 0;
    assign y_pos = frame_valid_ahead ? (vcnt - (V_SYNC + V_BACK )) : 0;

    //-------------------------------------
    //寄存图像处理之后的像素数据
    assign vip_out_frame_vsync = post1_frame_vsync;   
    assign vip_out_frame_href  = post1_frame_href ;   
    assign vip_out_frame_clken = post1_frame_clken;    
    assign vip_out_img_R       = {8{post1_img_Bit}};   
    assign vip_out_img_G       = {8{post1_img_Bit}};   
    assign vip_out_img_B       = {8{post1_img_Bit}}; 




// ---------------------------------------------------------------------------------
// 结构化描述 Moudle Instantiate
// ---------------------------------------------------------------------------------
    //-------------------------------------
    //VIP算法——彩色转灰度
    VIP_RGB888_YCbCr444	u_VIP_RGB888_YCbCr444
    (
        //global clock
        .clk				(clk),					//cmos video pixel clock
        .rst_n				(rst_n),				//system reset

        //Image data prepred to be processd
        .per_frame_vsync	(per_frame_vsync),		//Prepared Image data vsync valid signal
        .per_frame_href		(per_frame_href),		//Prepared Image data href vaild  signal
        .per_frame_clken	(per_frame_clken),		//Prepared Image data output/capture enable clock
        .per_img_red		(per_img_red),			//Prepared Image red data input
        .per_img_green		(per_img_green),		//Prepared Image green data input
        .per_img_blue		(per_img_blue),			//Prepared Image blue data input
        
        //Image data has been processd
        .post_frame_vsync	(post0_frame_vsync),		//Processed Image frame data valid signal
        .post_frame_href	(post0_frame_href),		//Processed Image hsync data valid signal
        .post_frame_clken	(post0_frame_clken),		//Processed Image data output/capture enable clock
        .post_img_Y			(post0_img_Y),			//Processed Image brightness output
        .post_img_Cb		(post0_img_Cb),			//Processed Image blue shading output
        .post_img_Cr		(post0_img_Cr)			//Processed Image red shading output
    );
    
    //--------------------------------------
    //VIP 算法——Sobel边缘检测
    VIP_Sobel_Edge_Detector #(
        .IMG_HDISP	(320),	 
        .IMG_VDISP	(240)
    ) u_VIP_Sobel_Edge_Detector (
        .clk					(clk),  				
        .rst_n					(rst_n),				

        //Image data prepred to be processd
        .per_frame_vsync		(post0_frame_vsync),	
        .per_frame_href			(post0_frame_href),		
        .per_frame_clken		(post0_frame_clken),	
        .per_img_Y				(post0_img_Y),			

        //Image data has been processd
        .post_frame_vsync		(post1_frame_vsync),	
        .post_frame_href		(post1_frame_href),		
        .post_frame_clken		(post1_frame_clken),	
        .post_img_Bit			(post1_img_Bit),		
        
        //User interface
        .Sobel_Threshold		(128)					
    );
    
    
    
// ---------------------------------------------------------------------------------
// 行为描述 Clocked Assignments
// ---------------------------------------------------------------------------------
    initial
    begin
        //分别打开 输入/输出BMP图片，以及输出的Txt文本
        iBmpFileId = $fopen("F:\\Project\\ModelSim\\grad_proj_tb\\image_proccessing_system\\img\\lenna_salt.bmp","rb");
    //  iBmpFileId = $fopen("F:\\Project\\ModelSim\\grad_proj_tb\\image_proccessing_system\\img\\lenna_salt_2.bmp","rb");
        oBmpFileId = $fopen("F:\\Project\\ModelSim\\grad_proj_tb\\image_proccessing_system\\img\\lenna_med.bmp","wb+");
        oTxtFileId = $fopen("F:\\Project\\ModelSim\\grad_proj_tb\\image_proccessing_system\\img\\lenna_med.txt","w+");

        //将输入BMP图片加载到数组中
        iCode = $fread(rBmpData,iBmpFileId);
     
        //根据BMP图片文件头的格式，分别计算出图片的 宽度 /高度 /像素数据偏移量 /图片字节数
        iBmpWidth       = {rBmpData[21],rBmpData[20],rBmpData[19],rBmpData[18]};
        iBmpHight       = {rBmpData[25],rBmpData[24],rBmpData[23],rBmpData[22]};
        iBmpSize        = {rBmpData[ 5],rBmpData[ 4],rBmpData[ 3],rBmpData[ 2]};
        iDataStartIndex = {rBmpData[13],rBmpData[12],rBmpData[11],rBmpData[10]};
        
        //关闭输入BMP图片
        $fclose(iBmpFileId);
        
        //将数组中的数据写到输出Txt文本中
        $fwrite(oTxtFileId,"%p",rBmpData);
        //关闭Txt文本
        $fclose(oTxtFileId);
        
        //延迟2ms，等待第一帧VIP处理结束
        #2000000    
        //加载图像处理后，BMP图片的文件头和像素数据
        for (iIndex = 0; iIndex < iBmpSize; iIndex = iIndex + 1) begin
            if(iIndex < 54)
                Vip_BmpData[iIndex] = rBmpData[iIndex];
            else
                Vip_BmpData[iIndex] = vip_pixel_data[iIndex-54];
        end
        
        //将数组中的数据写到输出BMP图片中    
        for (iIndex = 0; iIndex < iBmpSize; iIndex = iIndex + 4) begin
            rBmpWord = {Vip_BmpData[iIndex+3],Vip_BmpData[iIndex+2],Vip_BmpData[iIndex+1],Vip_BmpData[iIndex]};
            $fwrite(oBmpFileId,"%u",rBmpWord);
        end
        //关闭输出BMP图片
        $fclose(oBmpFileId);
    end
    
    //初始化时钟和复位信号
    initial begin
        clk     = 1;
        rst_n   = 0;
        #110
        rst_n   = 1;
    end 
    
    //产生50MHz时钟
    always #10 clk = ~clk;
    
    //在时钟驱动下, 从数组中读出像素数据
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            pixel_data  <=  8'd0;
            pixel_index <=  0;
        end
        else begin
            pixel_data  <=  rBmpData[pixel_index];
            pixel_index <=  pixel_index+1;
        end
    end
    
    ////////////////////////////////////////////产生摄像头时序 
    //---------------------------------------------
    //水平计数器
    reg	[10:0]	hcnt;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            hcnt <= 11'd0;
        else
            hcnt <= (hcnt < H_TOTAL - 1'b1) ? hcnt + 1'b1 : 11'd0;
    end

    //---------------------------------------------
    //竖直计数器
    reg	[10:0]	vcnt;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            vcnt <= 11'd0;		
        else begin
            if(hcnt == H_TOTAL - 1'b1)
                vcnt <= (vcnt < V_TOTAL - 1'b1) ? vcnt + 1'b1 : 11'd0;
            else
                vcnt <= vcnt;
        end
    end

    //---------------------------------------------
    //场同步
    reg	cmos_vsync_r;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cmos_vsync_r <= 1'b0;			//H: Vaild, L: inVaild
        else begin
            if(vcnt <= V_SYNC - 1'b1)
                cmos_vsync_r <= 1'b0; 	//H: Vaild, L: inVaild
            else
                cmos_vsync_r <= 1'b1; 	//H: Vaild, L: inVaild
        end
    end
    assign	cmos_vsync	= cmos_vsync_r;
    
    //---------------------------------------------
    //Image data href vaild  signal
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cmos_href_r <= 0;
        else begin
            if(frame_valid_ahead)
                cmos_href_r <= 1;
            else
                cmos_href_r <= 0;
        end
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cmos_href <= 0;
        else
            cmos_href <= cmos_href_r;
    end

    assign cmos_clken = cmos_href;

    //-------------------------------------
    //从数组中以视频格式输出像素数据
    always@(posedge clk or negedge rst_n)begin
       if(!rst_n) begin
           cmos_index   <=  0;
           cmos_data    <=  24'd0;
       end
       else begin
           cmos_index   <=  y_pos * 960  + x_pos*3 + 54;        //  3*(y*320 + x) + 54
           cmos_data    <=  {rBmpData[cmos_index], rBmpData[cmos_index+1] , rBmpData[cmos_index+2]};
       end
    end
    
    //-------------------------------------
    //寄存图像处理之后的像素数据
    always@(posedge clk or negedge rst_n)begin
       if(!rst_n) 
            vip_vsync_r   <=  1'b0;
       else 
            vip_vsync_r   <=  post0_frame_vsync;
    end

    always@(posedge clk or negedge rst_n)begin
       if(!rst_n) 
            vip_out_en    <=  1'b1;
       else if(vip_vsync_r & (!post0_frame_vsync))  //第一帧结束之后，使能拉低
            vip_out_en    <=  1'b0;
    end

    always@(posedge clk or negedge rst_n)begin
       if(!rst_n) begin
            vip_cnt <=  32'd0;
       end
       else if(vip_out_en) begin
            if(vip_out_frame_href & vip_out_frame_clken) begin
                vip_cnt <=  vip_cnt + 3;
                vip_pixel_data[vip_cnt+0] <= vip_out_img_R;
                vip_pixel_data[vip_cnt+1] <= vip_out_img_G;
                vip_pixel_data[vip_cnt+2] <= vip_out_img_B;
            end
       end
    end
    
// ---------------------------------------------------------------------------------
// 任务定义 Called Tasks
// ---------------------------------------------------------------------------------
    
	
// ---------------------------------------------------------------------------------
// 函数定义 Called Functions
// ---------------------------------------------------------------------------------

    
endmodule 