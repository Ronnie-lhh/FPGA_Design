// *********************************************************************************
// �ļ���: lcd_controller.v   
// ������: ���Ժ�
// ��������: 2021.3.19
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: lcd_controller
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)LCD��������ģ��
//            2)RGB565��ʽ���
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

// ---------------------------------------------------------------------------------
// �������� Constant Parameters
// ---------------------------------------------------------------------------------
`define LCD_480_272

`ifdef  LCD_480_272
    //4.3��  480*272  12.5MHz
    parameter   H_SYNC  = 11'd41;               //��ͬ��
    parameter   H_BACK  = 11'd2;                //����ʾ����
    parameter   H_DISP  = 11'd480;              //����Ч����
    parameter   H_FRONT = 11'd2;                //����ʾǰ��
    parameter   H_TOTAL = 11'd525;              //��ɨ������
    parameter   HS_POL  = 1'b0;                 //��ͬ���źŵļ���, 1/0

    parameter   V_SYNC  = 11'd10;               //��ͬ��
    parameter   V_BACK  = 11'd2;                //����ʾ����
    parameter   V_DISP  = 11'd272;              //����Ч����
    parameter   V_FRONT = 11'd2;                //����ʾǰ��
    parameter   V_TOTAL = 11'd286;              //��ɨ������
    parameter   VS_POL  = 1'b0;                 //��ͬ���źŵļ���, 1/0
`endif

// ---------------------------------------------------------------------------------
// ģ�鶨�� Module Define
// --------------------------------------------------------------------------------- 
module lcd_controller
(
    // clock & reset
    input 			    lcd_clk,                //ʱ���ź�
	input 			    rst_n,  		        //��λ�ź�, �͵�ƽ��Ч

    // input signal
    input      [15 : 0] pixel_data,             //��������
    
    // output signal
    output              lcd_data_req,           //���ص���ɫ������������
    output     [10 : 0] pixel_xpos,             //��ǰ���ص������
    output     [10 : 0] pixel_ypos,             //��ǰ���ص�������
    output     [15 : 0] lcd_rgb565,             //LCD RGB565��ɫ����
    output reg [10 : 0] h_disp,                 //LCD ˮƽ�ֱ���
    output reg [10 : 0] v_disp,                 //LCD ��ֱ�ֱ���
    
    // LCD �ӿ�
    output              lcd_de,                 //LCD ��������ʹ���ź�
    output              lcd_hs,                 //LCD ��ͬ���ź�
    output              lcd_vs,                 //LCD ��ͬ���ź�
    output reg          lcd_bl,                 //LCD ��������ź�
    output reg          lcd_rst,                //LCD ��λ�ź�
    output              lcd_dclk                //LCD ����ʱ��
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    reg        [10 : 0] h_sync;                 //��ͬ��
    reg        [10 : 0] h_back;                 //����ʾ����
    reg        [10 : 0] h_total;                //��ɨ������
    reg        [10 : 0] v_sync;                 //��ͬ��
    reg        [10 : 0] v_back;                 //����ʾ����
    reg        [10 : 0] v_total;                //��ɨ������
    reg        [10 : 0] h_cnt;                  //�м�����
    reg        [10 : 0] v_cnt;                  //��������
    
    wire                lcd_en;                 //RGB565�������ʹ��
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// --------------------------------------------------------------------------------- 
    //RGB LCD ����DEģʽʱ, �г�ͬ���ź���Ҫ����
    assign  lcd_hs = 1'b1;
    assign  lcd_vs = 1'b1;
    
    assign  lcd_dclk = lcd_clk;
    assign  lcd_de = lcd_en;
    
    //RGB565�������ʹ��
    assign  lcd_en       = ((h_cnt >= h_sync + h_back) && 
                            (h_cnt < h_sync + h_back + h_disp) &&
                            (v_cnt >= v_sync + v_back) &&
                            (v_cnt < v_sync + v_back + v_disp))? 1'b1 : 1'b0;
    
    //���ص���ɫ������������
    assign  lcd_data_req = ((h_cnt >= h_sync + h_back - 11'd1) && 
                            (h_cnt < h_sync + h_back + h_disp - 11'd1) &&
                            (v_cnt >= v_sync + v_back) &&
                            (v_cnt < v_sync + v_back + v_disp))? 1'b1 : 1'b0;
    
    //���ص�����
    assign  pixel_xpos = lcd_data_req? (h_cnt - (h_sync + h_back - 1'b1)) : 11'd0;
    assign  pixel_ypos = lcd_data_req? (v_cnt - (v_sync + v_back - 1'b1)) : 11'd0;
    
    //RGB565�������
    assign  lcd_rgb565 = lcd_en? pixel_data : 16'd0;
    
// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    //�г�ʱ�����
    always @(posedge lcd_clk)
    begin
        h_sync  <=  H_SYNC;
        h_back  <=  H_BACK;
        h_disp  <=  H_DISP;
        h_total <=  H_TOTAL;
        v_sync  <=  V_SYNC;
        v_back  <=  V_BACK;
        v_disp  <=  V_DISP;
        v_total <=  V_TOTAL;
    end
    
    //�м�����������ʱ�Ӽ���
    always @(posedge lcd_clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            h_cnt <= 11'd0;
        end
        else if(h_cnt == h_total - 11'd1)
        begin
            h_cnt <= 11'd0;
        end
        else
        begin
            h_cnt <= h_cnt + 11'd1;
        end
    end
    
    //�����������м���
    always @(posedge lcd_clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            v_cnt <= 11'd0;
        end
        else if(h_cnt == h_total - 11'd1)
        begin
            if(v_cnt == v_total - 11'd1)
            begin
                v_cnt <= 11'd0;
            end 
            else
            begin
                v_cnt <= v_cnt + 11'd1;
            end
        end
        else
        begin
            v_cnt <= v_cnt;
        end
    end
    
    //��ͬ���ź�
    // always @(posedge lcd_clk or negedge rst_n)
    // begin
        // if(!rst_n)
        // begin
            // lcd_hs <= 1'b0;
        // end
        // else if(h_cnt == H_FRONT - 11'd1)           //��ͬ���źſ�ʼ
        // begin
            // lcd_hs <= HS_POL;
        // end
        // else if(h_cnt == H_FRONT + H_SYNC - 11'd1)  //��ͬ���źŽ���
        // begin
            // lcd_hs <= ~lcd_hs;
        // end
        // else
        // begin
            // lcd_hs <= lcd_hs;
        // end
    // end
    
    //��ͬ���ź�
    // always @(posedge lcd_clk or negedge rst_n)
    // begin
        // if(!rst_n)
        // begin
            // lcd_vs <= 1'b0;
        // end
        // else if((v_cnt == V_FRONT - 11'd1) && (h_cnt == H_FRONT - 11'd1))               //��ͬ���źſ�ʼ
        // begin
            // lcd_vs <= VS_POL;
        // end
        // else if((v_cnt == V_FRONT + V_SYNC - 11'd1) && (h_cnt == H_FRONT - 11'd1))      //��ͬ���źŽ���
        // begin
            // lcd_vs <= ~lcd_vs;
        // end
        // else
        // begin
            // lcd_vs <= lcd_vs;
        // end
    // end
    
    //LCD��λ�źźͱ�������ź�
    always @(posedge lcd_clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            lcd_rst <= 1'b0;
            lcd_bl  <= 1'b0;
        end
        else
        begin
            lcd_rst <= 1'b1;
            lcd_bl  <= 1'b1;
        end
    end

// ---------------------------------------------------------------------------------
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// ������ Called Tasks
// ---------------------------------------------------------------------------------
    

// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------


endmodule 