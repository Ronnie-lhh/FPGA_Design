// *********************************************************************************
// �ļ���: img_proc_median_tb.v   
// ������: ���Ժ�
// ��������: 2021.3.30
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: img_proc_median_tb
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)Testbench for ͼ�����㷨ģ��
//
// --------------------------------------------------------------------------------- 
// �������:
//    
// ---------------------------------------------------------------------------------
// ������¼:
//
// ---------------------------------------------------------------------------------
// *********************************************************************************


// ---------------------------------------------------------------------------------
// �����ļ� Include File
// --------------------------------------------------------------------------------- 

// ---------------------------------------------------------------------------------
// ����ʱ�� Simulation Timescale
// ---------------------------------------------------------------------------------
`timescale  1ns/1ns

// ---------------------------------------------------------------------------------
// �������� Constant Parameters
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// ģ�鶨�� Module Define
// --------------------------------------------------------------------------------- 
module img_proc_median_tb;

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------
    ////////////////////////////////////////////��������ͷʱ�� 
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
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    integer iBmpFileId;                 //����BMPͼƬ
    integer oBmpFileId;                 //���BMPͼƬ
    integer oTxtFileId;                 //����TXT�ı�
            
    integer iIndex = 0;                 //���BMP��������
    integer pixel_index = 0;            //��������������� 
            
    integer iCode;      
            
    integer iBmpWidth;                  //����BMP ���
    integer iBmpHight;                  //����BMP �߶�
    integer iBmpSize;                   //����BMP �ֽ���
    integer iDataStartIndex;            //����BMP ��������ƫ����
        
    reg [ 7:0] rBmpData [0:2000000];    //���ڼĴ�����BMPͼƬ�е��ֽ����ݣ�����54�ֽڵ��ļ�ͷ��
    reg [ 7:0] Vip_BmpData [0:2000000]; //���ڼĴ���Ƶͼ����֮�� ��BMPͼƬ ���� 
    reg [31:0] rBmpWord;                //���BMPͼƬʱ���ڼĴ����ݣ���wordΪ��λ����4byte��
    
    reg [ 7:0] pixel_data;              //�����Ƶ��ʱ����������
    
    reg clk;                            //50MHz
    reg rst_n;
    
    reg [ 7:0] vip_pixel_data [0:1540080];   //720x713x3
    
        
    ////////////////////////////////////////////��������ͷʱ�� 
    wire		cmos_vsync;
    reg			cmos_href;
    wire        cmos_clken;
    reg	[23:0]	cmos_data;			 

    reg [31:0]  cmos_index;
    
    //-------------------------------------
    //������������Ƶ��ʽ�����������
    wire [10:0] x_pos;
    wire [10:0] y_pos;
    
    //-------------------------------------
    //VIP�㷨������ɫת�Ҷ�
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
    //VIP �㷨����Sobel��Ե���
    wire			post1_frame_vsync;	 
    wire			post1_frame_href;	 
    wire			post1_frame_clken;	 
    wire			post1_img_Bit;
    
    //-------------------------------------
    //�Ĵ�ͼ����֮�����������
    wire 		vip_out_frame_vsync;   
    wire 		vip_out_frame_href ;   
    wire 		vip_out_frame_clken;    
    wire [7:0]	vip_out_img_R     ;   
    wire [7:0]	vip_out_img_G     ;   
    wire [7:0]	vip_out_img_B     ;  
    
    reg [31:0] vip_cnt;
 
    reg         vip_vsync_r;    //�Ĵ�VIP����ĳ�ͬ�� 
    reg         vip_out_en;     //�Ĵ�VIP����ͼ���ʹ���źţ���ά��һ֡��ʱ��
    
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// --------------------------------------------------------------------------------- 
    //---------------------------------------------
    //Image data href vaild  signal
    wire	frame_valid_ahead =  ( vcnt >= V_SYNC + V_BACK  && vcnt < V_SYNC + V_BACK + V_DISP
                                && hcnt >= H_SYNC + H_BACK  && hcnt < H_SYNC + H_BACK + H_DISP ) 
                            ? 1'b1 : 1'b0;
          
    reg			cmos_href_r;
    
    //-------------------------------------
    //������������Ƶ��ʽ�����������
    assign x_pos = frame_valid_ahead ? (hcnt - (H_SYNC + H_BACK )) : 0;
    assign y_pos = frame_valid_ahead ? (vcnt - (V_SYNC + V_BACK )) : 0;

    //-------------------------------------
    //�Ĵ�ͼ����֮�����������
    assign vip_out_frame_vsync = post1_frame_vsync;   
    assign vip_out_frame_href  = post1_frame_href ;   
    assign vip_out_frame_clken = post1_frame_clken;    
    assign vip_out_img_R       = {8{post1_img_Bit}};   
    assign vip_out_img_G       = {8{post1_img_Bit}};   
    assign vip_out_img_B       = {8{post1_img_Bit}}; 




// ---------------------------------------------------------------------------------
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------
    //-------------------------------------
    //VIP�㷨������ɫת�Ҷ�
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
    //VIP �㷨����Sobel��Ե���
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
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    initial
    begin
        //�ֱ�� ����/���BMPͼƬ���Լ������Txt�ı�
        iBmpFileId = $fopen("F:\\Project\\ModelSim\\grad_proj_tb\\image_proccessing_system\\img\\lenna_salt.bmp","rb");
    //  iBmpFileId = $fopen("F:\\Project\\ModelSim\\grad_proj_tb\\image_proccessing_system\\img\\lenna_salt_2.bmp","rb");
        oBmpFileId = $fopen("F:\\Project\\ModelSim\\grad_proj_tb\\image_proccessing_system\\img\\lenna_med.bmp","wb+");
        oTxtFileId = $fopen("F:\\Project\\ModelSim\\grad_proj_tb\\image_proccessing_system\\img\\lenna_med.txt","w+");

        //������BMPͼƬ���ص�������
        iCode = $fread(rBmpData,iBmpFileId);
     
        //����BMPͼƬ�ļ�ͷ�ĸ�ʽ���ֱ�����ͼƬ�� ��� /�߶� /��������ƫ���� /ͼƬ�ֽ���
        iBmpWidth       = {rBmpData[21],rBmpData[20],rBmpData[19],rBmpData[18]};
        iBmpHight       = {rBmpData[25],rBmpData[24],rBmpData[23],rBmpData[22]};
        iBmpSize        = {rBmpData[ 5],rBmpData[ 4],rBmpData[ 3],rBmpData[ 2]};
        iDataStartIndex = {rBmpData[13],rBmpData[12],rBmpData[11],rBmpData[10]};
        
        //�ر�����BMPͼƬ
        $fclose(iBmpFileId);
        
        //�������е�����д�����Txt�ı���
        $fwrite(oTxtFileId,"%p",rBmpData);
        //�ر�Txt�ı�
        $fclose(oTxtFileId);
        
        //�ӳ�2ms���ȴ���һ֡VIP�������
        #2000000    
        //����ͼ�����BMPͼƬ���ļ�ͷ����������
        for (iIndex = 0; iIndex < iBmpSize; iIndex = iIndex + 1) begin
            if(iIndex < 54)
                Vip_BmpData[iIndex] = rBmpData[iIndex];
            else
                Vip_BmpData[iIndex] = vip_pixel_data[iIndex-54];
        end
        
        //�������е�����д�����BMPͼƬ��    
        for (iIndex = 0; iIndex < iBmpSize; iIndex = iIndex + 4) begin
            rBmpWord = {Vip_BmpData[iIndex+3],Vip_BmpData[iIndex+2],Vip_BmpData[iIndex+1],Vip_BmpData[iIndex]};
            $fwrite(oBmpFileId,"%u",rBmpWord);
        end
        //�ر����BMPͼƬ
        $fclose(oBmpFileId);
    end
    
    //��ʼ��ʱ�Ӻ͸�λ�ź�
    initial begin
        clk     = 1;
        rst_n   = 0;
        #110
        rst_n   = 1;
    end 
    
    //����50MHzʱ��
    always #10 clk = ~clk;
    
    //��ʱ��������, �������ж�����������
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
    
    ////////////////////////////////////////////��������ͷʱ�� 
    //---------------------------------------------
    //ˮƽ������
    reg	[10:0]	hcnt;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            hcnt <= 11'd0;
        else
            hcnt <= (hcnt < H_TOTAL - 1'b1) ? hcnt + 1'b1 : 11'd0;
    end

    //---------------------------------------------
    //��ֱ������
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
    //��ͬ��
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
    //������������Ƶ��ʽ�����������
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
    //�Ĵ�ͼ����֮�����������
    always@(posedge clk or negedge rst_n)begin
       if(!rst_n) 
            vip_vsync_r   <=  1'b0;
       else 
            vip_vsync_r   <=  post0_frame_vsync;
    end

    always@(posedge clk or negedge rst_n)begin
       if(!rst_n) 
            vip_out_en    <=  1'b1;
       else if(vip_vsync_r & (!post0_frame_vsync))  //��һ֡����֮��ʹ������
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
// ������ Called Tasks
// ---------------------------------------------------------------------------------
    
	
// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------

    
endmodule 