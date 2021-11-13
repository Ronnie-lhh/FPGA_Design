// *********************************************************************************
// �ļ���: sdram_controller.v   
// ������: ���Ժ�
// ��������: 2021.3.13
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: sdram_controller
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)SDRAM������     
//            2)����ģ��
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
module sdram_controller
(
    // clock & reset
    input 			clk,		            //SDRAM������ʱ��, 100MHZ
	input 			rst_n,  		        //ϵͳ��λ�ź�, �͵�ƽ��Ч

    // SDRAM������д�˿�
	input			sdram_wr_req,           //дSDRAM�����ź�
    output			sdram_wr_ack,           //дSDRAM��Ӧ�ź�
	input  [23 : 0] sdram_wr_addr,          //дSDRAM�ĵ�ַ
	input  [ 9 : 0]	sdram_wr_burst_len,     //дSDRAM������ͻ������
	input  [15 : 0]	sdram_din,              //д��SDRAM������

    // SDRAM���������˿�	                    
	input			sdram_rd_req,           //��SDRAM�����ź�
    output 			sdram_rd_ack,           //��SDRAM��Ӧ�ź�
	input  [23 : 0]	sdram_rd_addr,          //��SDRAM�ĵ�ַ
	input  [ 9 : 0] sdram_rd_burst_len,     //��SDRAM������ͻ������
	output [15 : 0] sdram_dout,             //��SDRAM�ж���������

    output          sdram_init_done,        //SDRAM ��ʼ����ɱ�־

    // FPGA��SDRAMӲ���ӿ�                   
    output          sdram_cke,              //SDRAM ʱ����Ч�ź�
    output          sdram_cs_n,             //SDRAM Ƭѡ�ź�
    output          sdram_ras_n,            //SDRAM �е�ַѡͨ�ź�
    output          sdram_cas_n,            //SDRAM �е�ַѡͨ�ź�
    output          sdram_we_n,             //SDRAM д����
    output [ 1 : 0] sdram_ba,               //SDRAM L-Bank��ַ��
    output [12 : 0] sdram_addr,             //SDRAM ��ַ����
    inout  [15 : 0] sdram_data	            //SDRAM ��������
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------
   
   
// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    wire   [4 : 0] sdram_init_state;        //SDRAM ��ʼ��״̬
    wire   [3 : 0] sdram_work_state;        //SDRAM ����״̬
    wire   [9 : 0] cnt_clk;                 //ʱ�Ӽ�����
    wire           sdram_rd_wr_ctrl;        //SDRAM��/д�����ź�, д(0), ��(1)
	
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// --------------------------------------------------------------------------------- 
    
    
// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------
    // SDRAM ״̬����ģ��
    sdram_state_ctrl    U_sdram_state_ctrl
    (
        // clock & reset
        .clk                            (clk),
        .rst_n                          (rst_n),

        .sdram_wr_req                   (sdram_wr_req),
        .sdram_rd_req                   (sdram_rd_req),
        .sdram_wr_ack                   (sdram_wr_ack),
        .sdram_rd_ack                   (sdram_rd_ack),
        .sdram_wr_burst_len             (sdram_wr_burst_len),
        .sdram_rd_burst_len             (sdram_rd_burst_len),
        .sdram_init_done                (sdram_init_done),

        .sdram_init_state               (sdram_init_state),
        .sdram_work_state               (sdram_work_state),
        .cnt_clk                        (cnt_clk),
        .sdram_rd_wr_ctrl               (sdram_rd_wr_ctrl)
    );
    
    // SDRAM�������ģ��
    sdram_cmd       U_sdram_cmd
    (
        // clock & reset
        .clk                            (clk),
        .rst_n                          (rst_n),

        // input signal
        .sys_wr_addr                    (sdram_wr_addr),
        .sys_rd_addr                    (sdram_rd_addr),
        .sdram_wr_burst_len             (sdram_wr_burst_len),
        .sdram_rd_burst_len             (sdram_rd_burst_len),

        .sdram_init_state               (sdram_init_state),
        .sdram_work_state               (sdram_work_state),
        .cnt_clk                        (cnt_clk),
        .sdram_rd_wr_ctrl               (sdram_rd_wr_ctrl),

        // output signal
        .sdram_cke                      (sdram_cke),
        .sdram_cs_n                     (sdram_cs_n),
        .sdram_ras_n                    (sdram_ras_n),
        .sdram_cas_n                    (sdram_cas_n),
        .sdram_we_n                     (sdram_we_n),
        .sdram_ba                       (sdram_ba),
        .sdram_addr                     (sdram_addr)
    );
    
    // SDRAM���ݶ�дģ��
    sdram_data      U_sdram_data
    (
        // clock & reset
        .clk		                    (clk),
        .rst_n 		                    (rst_n),

        .sdram_data_in                  (sdram_din),
        .sdram_data_out                 (sdram_dout),
        .sdram_work_state               (sdram_work_state),
        .cnt_clk                        (cnt_clk),
        
        // SDRAMоƬӲ���ӿ�
        .sdram_data                     (sdram_data)
    );
    
// ---------------------------------------------------------------------------------
// ������ Called Tasks
// ---------------------------------------------------------------------------------
    
	
// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------

    
endmodule 