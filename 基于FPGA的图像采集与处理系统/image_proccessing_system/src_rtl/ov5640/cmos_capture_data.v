// *********************************************************************************
// �ļ���: cmos_capture_data.v   
// ������: ���Ժ�
// ��������: 2021.3.18
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: cmos_capture_data
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)CMOS���ݲɼ�ģ��
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

// ---------------------------------------------------------------------------------
// �������� Constant Parameters
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// ģ�鶨�� Module Define
// --------------------------------------------------------------------------------- 
module cmos_capture_data
(
    // clock & reset
	input 			    rst_n,  		        //��λ�ź�, �͵�ƽ��Ч

    // ����ͷ�ӿ�
    input               cam_pclk,               //CMOS��������ʱ��
    input               cam_vsync,              //CMOS��ͬ���ź�
    input               cam_href,               //CMOS��ͬ���ź�
    input      [ 7 : 0] cam_data,               //CMOS����
    
    // �û��ӿ�
    output              cmos_frame_vsync,       //CMOS֡��Ч�ź�
    output              cmos_frame_href,        //CMOS����Ч�ź�
    output              cmos_frame_valid,       //CMOS������Чʹ���ź�
    output     [15 : 0] cmos_frame_data         //CMOS��Ч����
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------
    //�Ĵ���ȫ��������ɺ�, �ȵȴ�10֡ͼ��
    //���Ĵ���������Ч���ٿ�ʼ�ɼ�ͼ��
    localparam WAIT_FRAME = 4'd10;              //�Ĵ��������ȶ��ȴ���֡����

// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    reg                 cam_vsync_d0;           //CMOS��ͬ���źżĴ�
    reg                 cam_vsync_d1;           //CMOS��ͬ���źżĴ�
    reg                 cam_href_d0;            //CMOS��ͬ���źżĴ�
    reg                 cam_href_d1;            //CMOS��ͬ���źżĴ�
    reg                 frame_val_flag;         //֡��Ч��־
    reg        [ 3 : 0] cmos_ps_cnt;            //�ȴ�֡���ȶ�������

    reg                 byte_flag;              //8λת16λ�����ź�
    reg                 byte_flag_d0;           //8λת16λ�����źżĴ�
    reg        [ 7 : 0] cam_data_d0;            //CMOS���ݼĴ�
    reg        [15 : 0] cmos_data_8_16_t;       //����8λת16λ����ʱ�Ĵ���
    
    wire                pos_vsync;              //��ͬ���ź������ر�־
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// --------------------------------------------------------------------------------- 
    //�����볡ͬ���źŵ�������
    assign pos_vsync = (~cam_vsync_d1) & (cam_vsync_d0);
    
    //���֡��Ч�ź�
    assign cmos_frame_vsync = frame_val_flag? cam_vsync_d1 : 1'b0;
    //�������Ч�ź�
    assign cmos_frame_href  = frame_val_flag? cam_href_d1  : 1'b0;
    //���������Чʹ���ź�
    assign cmos_frame_valid = frame_val_flag? byte_flag_d0 : 1'b0;
    //�������
    assign cmos_frame_data  = frame_val_flag? cmos_data_8_16_t : 16'd0; 
    
// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    //�����볡ͬ���źŵ�������
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
    
    //��֡�����м���
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
    
    //֡��Ч��־
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
    
    //8λ����ת16λRGB565����
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
    
    //�������������Ч�ź�(cmos_frame_valid)
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
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// ������ Called Tasks
// ---------------------------------------------------------------------------------
    
	
// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------

    
endmodule 