// *********************************************************************************
// �ļ���: sdram_top.v   
// ������: ���Ժ�
// ��������: 2021.3.13
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: sdram_top
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)SDRAM����������ģ��
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
module sdram_top
(
    // clock & reset
    input 			    ref_clk,	            //SDRAM�������ο�ʱ��
    input               out_clk,                //�����������λƫ��ʱ��
	input 			    rst_n,  		        //ϵͳ��λ�ź�, �͵�ƽ��Ч

    // �û�д�˿�
    input               wr_clk,                 //д�˿�FIFO: дʱ��
    input               wr_en,                  //д�˿�FIFO: дʹ��
    input      [15 : 0] wr_data,                //д�˿�FIFO: д����
    input      [23 : 0] wr_min_addr,            //дSDRAM����ʼ��ַ
    input      [23 : 0] wr_max_addr,            //дSDRAM�Ľ�����ַ
    input      [ 9 : 0] wr_len,                 //дSDRAM������ͻ������
    input               wr_load,                //д�˿ڸ�λ: ��λд��ַ, ���дFIFO

    // �û����˿�                                
    input               rd_clk,                 //���˿�FIFO: ��ʱ��
    input               rd_en,                  //���˿�FIFO: ��ʹ��
    output     [15 : 0] rd_data,                //���˿�FIFO: ������
    input      [23 : 0] rd_min_addr,            //��SDRAM����ʼ��ַ
    input      [23 : 0] rd_max_addr,            //��SDRAM�Ľ�����ַ
    input      [ 9 : 0] rd_len,                 //��SDRAM�ж����ݵ�ͻ������
    input               rd_load,                //���˿ڸ�λ: ��λ����ַ, ��ն�FIFO

    // �û����ƶ˿�                              
    input               sdram_read_valid,       //SDRAM ��ʹ��
    input               sdram_pingpang_en,      //SDRAM ��дƹ�Ҳ���ʹ��
    output              sdram_init_done,        //SDRAM ��ʼ����ɱ�־

    // SDRAMоƬӲ���ӿ�                             
    output              sdram_clk,              //SDRAM оƬʱ���ź�
    output              sdram_cke,              //SDRAM ʱ����Ч�ź�
    output              sdram_cs_n,             //SDRAM Ƭѡ�ź�
    output              sdram_ras_n,            //SDRAM �е�ַѡͨ�ź�
    output              sdram_cas_n,            //SDRAM �е�ַѡͨ�ź�
    output              sdram_we_n,             //SDRAM д����
    output     [ 1 : 0] sdram_ba,               //SDRAM L-Bank��ַ��
    output     [12 : 0] sdram_addr,             //SDRAM ��ַ����
    output     [ 1 : 0] sdram_dqm,              //SDRAM ��������
    inout      [15 : 0] sdram_data              //SDRAM ��������
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------
 
 
// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    wire                sdram_wr_req;           //SDRAM д����
    wire                sdram_wr_ack;           //SDRAM д��Ӧ
    wire       [23 : 0] sdram_wr_addr;          //SDRAM д��ַ
    wire       [15 : 0] sdram_din;              //д��SDRAM������
    
    wire                sdram_rd_req;           //SDRAM ������
    wire                sdram_rd_ack;           //SDRAM ����Ӧ
    wire       [23 : 0] sdram_rd_addr;          //SDRAM ����ַ
    wire       [15 : 0] sdram_dout;             //��SDRAM�ж���������
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// --------------------------------------------------------------------------------- 
    assign sdram_clk = out_clk;                 //����λƫ��ʱ�������SDRAMоƬ
    assign sdram_dqm = 2'b00;                   //��д�����о�������������(��ʹ����������)
    
// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------
    // SDRAM��д�˿�FIFO����ģ��
    sdram_fifo_ctrl     U_sdram_fifo_ctrl
    (
        // clock & reset
        .clk_ref                    (ref_clk),
        .rst_n                      (rst_n),

        // �û�д�˿�
        .clk_write                  (wr_clk),
        .wrf_wrreq                  (wr_en),
        .wrf_din                    (wr_data),
        .wr_min_addr                (wr_min_addr),
        .wr_max_addr                (wr_max_addr),
        .wr_len                     (wr_len),
        .wr_load                    (wr_load),

        // �û����˿�
        .clk_read                   (rd_clk),
        .rdf_rdreq                  (rd_en),
        .rdf_dout                   (rd_data),
        .rd_min_addr                (rd_min_addr),
        .rd_max_addr                (rd_max_addr),
        .rd_len                     (rd_len),
        .rd_load                    (rd_load),

        // �û����ƶ˿�
        .sdram_read_valid           (sdram_read_valid),
        .sdram_init_done            (sdram_init_done),
        .sdram_pingpang_en          (sdram_pingpang_en),

        // SDRAM������д�˿�
        .sdram_wr_req               (sdram_wr_req),
        .sdram_wr_ack               (sdram_wr_ack),
        .sdram_wr_addr              (sdram_wr_addr),
        .sdram_din                  (sdram_din),
           
        // SDRAM���������˿�
        .sdram_rd_req               (sdram_rd_req),
        .sdram_rd_ack               (sdram_rd_ack),
        .sdram_rd_addr              (sdram_rd_addr),
        .sdram_dout                 (sdram_dout)
    );
    
    //SDRAM������
    sdram_controller        U_sdram_controller
    (
        // clock & reset
        .clk                        (ref_clk),
        .rst_n  		            (rst_n),

        // SDRAM������д�˿�
        .sdram_wr_req               (sdram_wr_req),
        .sdram_wr_ack               (sdram_wr_ack),
        .sdram_wr_addr              (sdram_wr_addr),
        .sdram_wr_burst_len         (wr_len),
        .sdram_din                  (sdram_din),

        // SDRAM���������˿�
        .sdram_rd_req               (sdram_rd_req),
        .sdram_rd_ack               (sdram_rd_ack),
        .sdram_rd_addr              (sdram_rd_addr),
        .sdram_rd_burst_len         (rd_len),
        .sdram_dout                 (sdram_dout),

        .sdram_init_done            (sdram_init_done),

        // FPGA��SDRAMӲ���ӿ�
        .sdram_cke                  (sdram_cke),
        .sdram_cs_n                 (sdram_cs_n),
        .sdram_ras_n                (sdram_ras_n),
        .sdram_cas_n                (sdram_cas_n),
        .sdram_we_n                 (sdram_we_n),
        .sdram_ba                   (sdram_ba),
        .sdram_addr                 (sdram_addr),
        .sdram_data	                (sdram_data)
    );


// ---------------------------------------------------------------------------------
// ������ Called Tasks
// ---------------------------------------------------------------------------------
    
	
// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------

    
endmodule