// ********************************************************************************* 
// �ļ���: video_image_processor.v   
// ������: ���Ժ�
// ��������: 2021.3.25
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: video_image_processor
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)ͼ�����㷨�ķ�װ����ģ��  
//            2)RGBתYCbCr, ��ֵ��, ��ֵ�˲�, Sobel��Ե���
//             3)���ݰ���ָ���л���ʾ�����㷨������
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
parameter   GRAY_THRESHOLD = 8'd60;             //��ֵ��������Զ���ֵ
parameter   SOBEL_THRESHOLD = 11'd35;           //Sobel�Զ���ֵ

// ---------------------------------------------------------------------------------
// ģ�鶨�� Module Define
// --------------------------------------------------------------------------------- 
module video_image_processor
(
    // clock & reset
    input 			    clk,	                //ʱ���ź�
    input               rst_n,                  //��λ�ź�, �͵�ƽ��Ч

    // input signal
    input      [ 3 : 0] key_cmd,                //����ָ��
    
    // Ԥ����ͼ��ӿ�
    input               pre_img_vs,             //Ԥ����ͼ��ͬ���ź�
    input               pre_img_hs,             //Ԥ����ͼ����ͬ���ź�
    input               pre_img_de,             //Ԥ����ͼ��������Чʹ���ź�
    input      [15 : 0] pre_img_data,           //Ԥ����ͼ������, RGB565��ʽ
    
    // output signal
    // �����ͼ��ӿ�
    output reg          proc_img_vs,            //�����ͼ��ͬ���ź�
    output reg          proc_img_hs,            //�����ͼ����ͬ���ź�
    output reg          proc_img_de,            //�����ͼ��������Чʹ���ź�
    output reg [15 : 0] proc_img_data           //�����ͼ������, YCbCr��ʽ
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------
    // �л������㷨����İ�������
    localparam    GRAY_CMD = 4'b1110;           //�Ҷ�ͼ����ʾ
    localparam     BIN_CMD = 4'b1101;           //ͼ���ֵ��
    localparam  MEDIAN_CMD = 4'b1011;           //�Ҷ�ͼ��ֵ�˲�
    localparam   SOBEL_CMD = 4'b0111;           //����Sobel���ӵı�Ե���
   
// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    // RGBתYCbCr
    wire                ycbcr_vs;
    wire                ycbcr_hs;
    wire                ycbcr_de;
    wire       [ 7 : 0] ycbcr_y;
    wire       [ 7 : 0] ycbcr_cb;
    wire       [ 7 : 0] ycbcr_cr;
    
    // ��ֵ��
    wire                bin_vs;
    wire                bin_hs;
    wire                bin_de;
    wire       [ 7 : 0] bin_y;
    
    // ��ֵ�˲�
    wire                median_vs;
    wire                median_hs;
    wire                median_de;
    wire       [ 7 : 0] median_y;
    
    // Sobel��Ե���
    wire                sobel_vs;
    wire                sobel_hs;
    wire                sobel_de;
    wire       [ 7 : 0] sobel_y;
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// ---------------------------------------------------------------------------------    


// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    // ���ݰ���ָ���л���ʾ�����㷨������
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            proc_img_vs   <=  1'b0;
            proc_img_hs   <=  1'b0;
            proc_img_de   <=  1'b0;
            proc_img_data <= 16'd0;
        end
        else
        begin
            case(key_cmd)
                            //�Ҷ�ͼ����ʾ
                GRAY_CMD: 
                    begin
                        proc_img_vs   <= ycbcr_vs;
                        proc_img_hs   <= ycbcr_hs;
                        proc_img_de   <= ycbcr_de;
                        proc_img_data <= {ycbcr_y[7 : 3], ycbcr_y[7 : 2], ycbcr_y[7 : 3]};
                    end
                            //ͼ���ֵ��
                BIN_CMD:
                    begin
                        proc_img_vs   <= bin_vs;
                        proc_img_hs   <= bin_hs;
                        proc_img_de   <= bin_de;
                        proc_img_data <= {bin_y[7 : 3], bin_y[7 : 2], bin_y[7 : 3]};
                    end
                            //�Ҷ�ͼ��ֵ�˲�
                MEDIAN_CMD:
                    begin
                        proc_img_vs   <= median_vs;
                        proc_img_hs   <= median_hs;
                        proc_img_de   <= median_de;
                        proc_img_data <= {median_y[7 : 3], median_y[7 : 2], median_y[7 : 3]};
                    end
                            //����Sobel���ӵı�Ե���
                SOBEL_CMD:
                    begin
                        proc_img_vs   <= sobel_vs;
                        proc_img_hs   <= sobel_hs;
                        proc_img_de   <= sobel_de;
                        proc_img_data <= {sobel_y[7 : 3], sobel_y[7 : 2], sobel_y[7 : 3]};
                    end
                            //����ͼ����, ����Ϊͼ��ʵʱ�ɼ����
                default:
                    begin
                        proc_img_vs   <= pre_img_vs;
                        proc_img_hs   <= pre_img_hs;
                        proc_img_de   <= pre_img_de;
                        proc_img_data <= pre_img_data;
                    end
            endcase
        end
    end

// ---------------------------------------------------------------------------------
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------
    // RGBתYCbCr
    proc_rgb2ycbcr      U_proc_rgb2ycbcr
    (
        // clock & reset
        .clk                        (clk),
        .rst_n                      (rst_n),
    
        // input signal 
        // ͼ����ǰ�����ݽӿ�   
        .rgb565_vs                  (pre_img_vs),
        .rgb565_hs                  (pre_img_hs),
        .rgb565_de                  (pre_img_de),
        .rgb565_r                   (pre_img_data[15 : 11]),
        .rgb565_g                   (pre_img_data[10 :  5]),
        .rgb565_b                   (pre_img_data[ 4 :  0]),
    
        // output signal    
        //ͼ���������ݽӿ�    
        .ycbcr_vs                   (ycbcr_vs),
        .ycbcr_hs                   (ycbcr_hs),
        .ycbcr_de                   (ycbcr_de),
        .ycbcr_y                    (ycbcr_y),
        .ycbcr_cb                   (ycbcr_cb),
        .ycbcr_cr                   (ycbcr_cr)
    );
    
    // ��ֵ������
    proc_binarization
    #(
        // prameter passing
        .GRAY_THRESHOLD             (GRAY_THRESHOLD)
    )   
    U_proc_binarization 
    (   
        // clock & reset    
        .clk                        (clk),
        .rst_n  	                (rst_n),
    
        // input signal 
        // ͼ����ǰ�����ݽӿ�   
        .ycbcr_vs                   (ycbcr_vs),
        .ycbcr_hs                   (ycbcr_hs),
        .ycbcr_de                   (ycbcr_de),
        .ycbcr_y                    (ycbcr_y),
    
        // output signal    
        // ͼ���������ݽӿ�   
        .bin_vs                     (bin_vs),
        .bin_hs                     (bin_hs),
        .bin_de                     (bin_de),
        .bin_y                      (bin_y)
    );
    
    // �Ҷ�ͼ��ֵ�˲�
    proc_gray_median_filter      U_proc_gray_median_filter
    (
        // clock & reset
        .clk                        (clk),
        .rst_n                      (rst_n),

        // input signal
        // ͼ����ǰ�����ݽӿ�
        .ycbcr_vs                   (ycbcr_vs),
        .ycbcr_hs                   (ycbcr_hs),
        .ycbcr_de                   (ycbcr_de),
        .ycbcr_y                    (ycbcr_y),

        // output signal
        // ͼ���������ݽӿ�
        .median_vs                  (median_vs),
        .median_hs                  (median_hs),
        .median_de                  (median_de),
        .median_y                   (median_y)
    );
    
    // ����Sobel���ӵı�Ե���
    proc_sobel_edge_detector
    #(
        // parameter passing
        .SOBEL_THRESHOLD            (SOBEL_THRESHOLD)
    )
    U_proc_sobel_edge_detector
    (
        // clock & reset
        .clk                        (clk),
        .rst_n                      (rst_n),

        // input signal
        // ͼ����ǰ�����ݽӿ�
        .ycbcr_vs                   (ycbcr_vs),
        .ycbcr_hs                   (ycbcr_hs),
        .ycbcr_de                   (ycbcr_de),
        .ycbcr_y                    (ycbcr_y),

        // output signal
        // ͼ���������ݽӿ�
        .sobel_vs                   (sobel_vs),
        .sobel_hs                   (sobel_hs),
        .sobel_de                   (sobel_de),
        .sobel_y                    (sobel_y)
    );

// ---------------------------------------------------------------------------------
// ������ Called Tasks
// ---------------------------------------------------------------------------------

	
// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------

    
endmodule