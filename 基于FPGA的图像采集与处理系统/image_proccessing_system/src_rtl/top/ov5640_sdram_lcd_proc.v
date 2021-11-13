// ********************************************************************************* 
// �ļ���: ov5640_sdram_lcd_proc.v   
// ������: ���Ժ�
// ��������: 2021.3.27
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: ov5640_sdram_lcd_proc
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)ͼ��ʵʱ�ɼ�����ϵͳ�Ķ���ģ��   
//            2)OV5640����ͷ�ɼ�, IIC����, SDRAM�洢, ���RGB888��LCD��ʾ
//             3)�Ҷ�ͼ��ʾ, ͼ���ֵ��, �Ҷ�ͼ��ֵ�˲�, Sobel��Ե���
//              4)���ݰ��������л���ʾ�����㷨������
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
parameter   SLAVE_ADDR    = 7'h3c;              //OV5640��������ַΪ7'h3c
parameter   BIT_CTRL      = 1'b1;               //OV5640���ֽڵ�ַΪ16λ, 8λ(0)/16λ(1)
parameter   CLK_FREQ      = 27'd100_000_000;    //i2c_controllerģ�������ʱ��Ƶ��
parameter   I2C_FREQ      = 18'd250_000;        //I2C��SCLʱ��Ƶ��, ������400KHz

parameter   CMOS_H_PIXEL  = 13'd480;            //CMOSˮƽ�������ظ���
parameter   CMOS_V_PIXEL  = 13'd272;            //CMOS��ֱ�������ظ���
parameter   TOTAL_H_PIXEL = 13'd1800;           //ˮƽ�����ش�С
parameter   TOTAL_V_PIXEL = 13'd1000;           //��ֱ�����ش�С
parameter   CMOS_HV_SIZE  = 24'd130560;         //CMOS���ͼ��Ĵ�С, CMOS_H_PIXEL * CMOS_V_PIXEL
                                                //��������дSDRAM������ַ

// ---------------------------------------------------------------------------------
// ģ�鶨�� Module Define
// --------------------------------------------------------------------------------- 
module ov5640_sdram_lcd_proc
(
    // clock & reset
    input 			    sys_clk,	            //ϵͳʱ���ź�, 50MHz
    input               key_rst_n,              //������λ�ź�, �͵�ƽ��Ч
    
    // �����ӿ�
    input      [ 3 : 0] key,                    //��������, �����л���ʾ����ͼ������

    // ����ͷ�ӿ�
    input               cam_pclk,               //CMOS ��������ʱ��
    input               cam_vsync,              //CMOS ��ͬ���ź�
    input               cam_href,               //CMOS ��ͬ���ź�
    input      [ 7 : 0] cam_data,               //CMOS ����
    output              cam_xclk,               //CMOS �ⲿʱ��
    output              cam_rst_n,              //CMOS Ӳ����λ�ź�, �͵�ƽ��Ч
    output              cam_pwdn,               //CMOS ��Դ����ģʽѡ���ź�
    output              cam_scl,                //CMOS SCCB_SCL��
    inout               cam_sda,                //CMOS SCCB_SDA��
    
    // SDRAM�ӿ�
    output              sdram_clk,              //SDRAM оƬʱ���ź�
    output              sdram_cke,              //SDRAM ʱ����Ч�ź�
    output              sdram_cs_n,             //SDRAM Ƭѡ�ź�
    output              sdram_ras_n,            //SDRAM �е�ַѡͨ�ź�
    output              sdram_cas_n,            //SDRAM �е�ַѡͨ�ź�
    output              sdram_we_n,             //SDRAM д����
    output     [ 1 : 0] sdram_ba,               //SDRAM L-Bank��ַ��
    output     [12 : 0] sdram_addr,             //SDRAM ��ַ����
    output     [ 1 : 0] sdram_dqm,              //SDRAM ��������
    inout      [15 : 0] sdram_data,             //SDRAM ��������
    
    // LCD�ӿ�
    output              lcd_de,                 //LCD ��������ʹ���ź�
    output              lcd_hs,                 //LCD ��ͬ���ź�
    output              lcd_vs,                 //LCD ��ͬ���ź�
    output              lcd_bl,                 //LCD ��������ź�
    output              lcd_rst,                //LCD ��λ�ź�
    output              lcd_dclk,               //LCD ����ʱ��
    output     [ 7 : 0] lcd_r,                  //LCD RGB888��ɫ����
    output     [ 7 : 0] lcd_g,                  //LCD RGB888��ɫ����
    output     [ 7 : 0] lcd_b                   //LCD RGB888��ɫ����
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------

   
// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    wire                sys_clk_bufg;           //��IBUFG�������ϵͳʱ��, 50MHz
    wire                clk_100m_sdram;         //SDRAM����ʱ��, 100MHz
    wire                clk_100m_sdram_shift;   //SDRAM��λƫ��ʱ��, 100MHz, ƫ��-75��
    wire                clk_100m_lcd;           //LCD����ģ��ʱ��, 100MHz
    wire                clk_10m_lcd;            //LCD����ʱ��, 10MHz
    wire                clk_24m_cmos;           //CMOS�ⲿʱ��, 24MHz
    wire                locked;                 //PLL�ȶ������־
    wire                sys_rst_n;              //ϵͳ��λ�ź�
    wire                sys_init_done;          //ϵͳ��ʼ�����(SDRAM��ʼ��+����ͷ��ʼ��)
    
    wire                i2c_dri_clk;            //I2C����ʱ��
    wire                i2c_exec;               //I2C����ִ���ź�
    wire                i2c_rw_ctrl;            //I2C��д�����ź�, ��(1)/д(0)
    wire                i2c_done;               //I2Cһ���Ĵ�����������ź�
    wire       [ 7 : 0] i2c_rd_data;            //I2C����������
    wire       [23 : 0] i2c_data;               //I2CҪ���õĵ�ַ������, ��ַ(��16λ)/����(��8λ)
    wire                cam_init_done;          //����ͷ��ʼ������ź�
    
    wire                lcd_data_req;           //LCD�������ص���ɫ��������
    wire       [15 : 0] pixel_data;             //����LCD��ʾ��RGB565��ʽ�����ص�����
    wire                sdram_init_done;        //SDRAM��ʼ�����
    
    wire                cmos_frame_vsync;       //CMOS֡��Ч�ź�
    wire                cmos_frame_href;        //CMOS����Ч�ź�
    wire                cmos_frame_valid;       //CMOS������Чʹ���ź�
    wire       [15 : 0] cmos_frame_data;        //CMOS��Ч����, RGB565��ʽ
    
    wire                proc_cmos_frame_vsync;  //��ͼ������CMOS֡��Ч�ź�
    wire                proc_cmos_frame_href;   //��ͼ������CMOS����Ч�ź�
    wire                proc_cmos_frame_valid;  //��ͼ������CMOS������Чʹ���ź�
    wire       [15 : 0] proc_cmos_frame_data;   //��ͼ������CMOSͼ������
    
    wire       [ 3 : 0] key_cmd;                //���ݰ������������ָ��
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// ---------------------------------------------------------------------------------    
    //��PLL����ȶ�֮��, ֹͣϵͳ��λ
    assign  sys_rst_n = key_rst_n & locked;
    
    //ϵͳ��ʼ����ɣ�SDRAM������ͷ����ʼ�����
    //������SDRAM��ʼ��������������д������
    assign  sys_init_done = sdram_init_done & cam_init_done;
    
    //��Դ����ģʽѡ��, ����ģʽ(0)/��Դ����ģʽ(1)
    assign  cam_pwdn = 1'b0;
    
    //��������ͷӲ����λ, �̶��ߵ�ƽ
    assign  cam_rst_n = 1'b1;
    
    //CMOS�ⲿʱ��, 24MHz
    assign  cam_xclk = clk_24m_cmos;
    
// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------
    // ����ȫ�ֻ���
    IBUFG       U_IBUFG
    (
        .O                      (sys_clk_bufg),
        .I                      (sys_clk)
    );
    
    // PLL ����
    sys_pll     U_sys_pll
    (
        // clock & reset
        .clk_in                 (sys_clk_bufg),
        .areset                 (~key_rst_n),

        .clk_out1               (clk_100m_sdram),
        .clk_out2               (clk_100m_sdram_shift),
        .clk_out3               (clk_100m_lcd),
        .clk_out4               (clk_10m_lcd),
        .clk_out5               (clk_24m_cmos),
        .locked                 (locked)
    );
    
    // LCD ����ģ������
    lcd_top     U_lcd_top
    (
        // clock & reset
        .clk	                (clk_100m_lcd),
        .lcd_clk                (clk_10m_lcd),
        .rst_n                  (sys_rst_n),

        // input signal
        .pixel_data             (pixel_data),

        // output signal
        .lcd_data_req           (lcd_data_req),

        // LCD �ӿ�
        .lcd_de                 (lcd_de),
        .lcd_hs                 (lcd_hs),
        .lcd_vs                 (lcd_vs),
        .lcd_bl                 (lcd_bl),
        .lcd_rst                (lcd_rst),
        .lcd_dclk               (lcd_dclk),
        .lcd_r                  (lcd_r),
        .lcd_g                  (lcd_g),
        .lcd_b                  (lcd_b)
    );
    
    // IIC ����ģ��
    i2c_ov5640_rgb565_cfg
    #(
        // parameter passing
        .CMOS_H_PIXEL           (CMOS_H_PIXEL),
        .CMOS_V_PIXEL           (CMOS_V_PIXEL),
        .TOTAL_H_PIXEL          (TOTAL_H_PIXEL),
        .TOTAL_V_PIXEL          (TOTAL_V_PIXEL),
        .CMOS_HV_SIZE           (CMOS_HV_SIZE)
    )
    U_i2c_ov5640_rgb565_cfg
    (
        // clock & reset
        .clk	                (i2c_dri_clk),
        .rst_n  		        (sys_rst_n),

        // input signal
        .i2c_done               (i2c_done),
        .i2c_rd_data            (i2c_rd_data),

        // output signal
        .i2c_exec               (i2c_exec),
        .i2c_init_done          (cam_init_done),
        .i2c_rw_ctrl            (i2c_rw_ctrl),
        .i2c_data               (i2c_data)
    );
    
    // IIC ����ģ��
    i2c_controller
    #(
        // parameter passing
        .SLAVE_ADDR             (SLAVE_ADDR),
        .CLK_FREQ               (CLK_FREQ),
        .I2C_FREQ               (I2C_FREQ)
    )
    U_i2c_controller
    (
        // clock & reset
        .clk                    (clk_100m_lcd),
        .rst_n	                (sys_rst_n),

        // i2c interface
        .i2c_exec               (i2c_exec),
        .bit_ctrl               (BIT_CTRL),
        .i2c_rw_ctrl            (i2c_rw_ctrl),
        .i2c_addr               (i2c_data[23 : 8]),
        .i2c_wr_data            (i2c_data[ 7 : 0]),
        .i2c_rd_data            (i2c_rd_data),
        .i2c_done               (i2c_done),
        .scl                    (cam_scl),
        .sda                    (cam_sda),

        // user interface
        .clk_dri                (i2c_dri_clk)
    );
    
    // CMOSͼ�����ݲɼ�ģ��
    cmos_capture_data       U_cmos_capture_data
    (
        // clock & reset
        .rst_n  		        (sys_rst_n & sys_init_done),    //ϵͳ��ʼ����ɺ��ٿ�ʼ�ɼ�����

        // ����ͷ�ӿ�
        .cam_pclk               (cam_pclk),
        .cam_vsync              (cam_vsync),
        .cam_href               (cam_href),
        .cam_data               (cam_data),

        // �û��ӿ�
        .cmos_frame_vsync       (cmos_frame_vsync),
        .cmos_frame_href        (cmos_frame_href),
        .cmos_frame_valid       (cmos_frame_valid),
        .cmos_frame_data        (cmos_frame_data)
    );
    
    // ����ָ�����ģ��
    key_ctrl        U_key_ctrl
    (
        // clock & reset
        .clk                    (cam_pclk),
        .rst_n                  (sys_rst_n),

        // input signal
        .key                    (key),

        // output signal
        .key_cmd                (key_cmd)
    );
    
    // ͼ�����㷨ģ��
    video_image_processor       U_video_image_processor
    (
        // clock & reset
        .clk	                (cam_pclk),
        .rst_n                  (sys_rst_n),

        // input signal
        .key_cmd                (key_cmd),
        
        // Ԥ����ͼ��ӿ�
        .pre_img_vs             (cmos_frame_vsync),
        .pre_img_hs             (cmos_frame_href),
        .pre_img_de             (cmos_frame_valid),
        .pre_img_data           (cmos_frame_data),

        // output signal
        // �����ͼ��ӿ�
        .proc_img_vs            (proc_cmos_frame_vsync),
        .proc_img_hs            (proc_cmos_frame_href),
        .proc_img_de            (proc_cmos_frame_valid),
        .proc_img_data          (proc_cmos_frame_data)
    );
    
    // SDRAM ����������ģ��, ��װ��FIFO�ӿ�
    // SDRAM ��������ַ���, {bank_addr[1:0], row_addr[12:0], col_addr[8:0]}
    sdram_top       U_sdram_top
    (
        // clock & reset
        .ref_clk	            (clk_100m_sdram),
        .out_clk                (clk_100m_sdram_shift),
        .rst_n 		            (sys_rst_n),

        // �û�д�˿�
        .wr_clk                 (cam_pclk),
        .wr_en                  (proc_cmos_frame_valid),
        .wr_data                (proc_cmos_frame_data),
        .wr_min_addr            (24'd0),
        .wr_max_addr            (CMOS_HV_SIZE),
        .wr_len                 (10'd512),
        .wr_load                (~sys_rst_n),

        // �û����˿�
        .rd_clk                 (clk_10m_lcd),
        .rd_en                  (lcd_data_req),
        .rd_data                (pixel_data),
        .rd_min_addr            (24'd0),
        .rd_max_addr            (CMOS_HV_SIZE),
        .rd_len                 (10'd512),
        .rd_load                (~sys_rst_n),

        // �û����ƶ˿�
        .sdram_read_valid       (1'b1),
        .sdram_pingpang_en      (1'b1),
        .sdram_init_done        (sdram_init_done),

        // SDRAMоƬӲ���ӿ�
        .sdram_clk              (sdram_clk),
        .sdram_cke              (sdram_cke),
        .sdram_cs_n             (sdram_cs_n),
        .sdram_ras_n            (sdram_ras_n),
        .sdram_cas_n            (sdram_cas_n),
        .sdram_we_n             (sdram_we_n),
        .sdram_ba               (sdram_ba),
        .sdram_addr             (sdram_addr),
        .sdram_dqm              (sdram_dqm),
        .sdram_data             (sdram_data)
    );    

// ---------------------------------------------------------------------------------
// ������ Called Tasks
// ---------------------------------------------------------------------------------

	
// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------

    
endmodule