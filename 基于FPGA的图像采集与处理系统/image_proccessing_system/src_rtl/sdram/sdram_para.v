// *********************************************************************************
// --------------------------------------------------------------------------------- 
// �ļ���: sdram_para.v    
// ������: ���Ժ�
// ��������: 2021.3.7
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ����: SDRAMԤ�������
// ---------------------------------------------------------------------------------
// *********************************************************************************

`ifndef SDRAM_PARA
`define SDRAM_PARA

// ---------------------------------------------------------------------------------
// �����ļ� Include File
// --------------------------------------------------------------------------------- 

// ---------------------------------------------------------------------------------
// Ԥ������� Precompiled Parameters
// ---------------------------------------------------------------------------------

//SDRAM��ʼ�����̸���״̬
`define     I_NOP           3'd0                                        //�ȴ��ϵ�200us�ȶ��ڽ���
`define     I_PRE           3'd1                                        //Ԥ���״̬
`define     I_TRP           3'd2                                        //�ȴ�Ԥ������
`define     I_AR            3'd3                                        //�Զ�ˢ��
`define     I_TRF           3'd4                                        //�ȴ��Զ�ˢ�½���
`define     I_MRS           3'd5                                        //ģʽ�Ĵ�������
`define     I_TRSC          3'd6                                        //�ȴ�ģʽ�Ĵ����������
`define     I_DONE          3'd7                                        //��ʼ�����

//SDRAM�������̸���״̬
`define     W_IDLE          4'd0                                        //����
`define     W_ACTIVE        4'd1                                        //����Ч
`define     W_TRCD          4'd2                                        //����Ч�ȴ�
`define     W_READ          4'd3                                        //������
`define     W_CL            4'd4                                        //��Ǳ����
`define     W_RD            4'd5                                        //������
`define     W_WRITE         4'd6                                        //д����
`define     W_WD            4'd7                                        //д����
`define     W_TWR           4'd8                                        //д������
`define     W_PRE           4'd9                                        //Ԥ���
`define     W_TRP           4'd10                                       //Ԥ���ȴ�
`define     W_AR            4'd11                                       //�Զ�ˢ��
`define     W_TRFC          4'd12                                       //�Զ�ˢ�µȴ�

//��ʱ����
`define     end_trp         cnt_clk == TRP_CLK                          //Ԥ�����Ч���ڽ���
`define     end_trfc        cnt_clk == TRFC_CLK                         //�Զ�ˢ�����ڽ���
`define     end_trsc        cnt_clk == TRSC_CLK                         //ģʽ�Ĵ����������ڽ���
`define     end_trcd        cnt_clk == TRCD_CLK - 1                     //��ѡͨ���ڽ���
`define     end_tcl         cnt_clk == TCL_CLK - 1                      //��Ǳ���ڽ���
`define     end_rdburst     cnt_clk == sdram_rd_burst_len - 4           //��ͻ����ֹ
`define     end_tread       cnt_clk == sdram_rd_burst_len + 2           //ͻ��������
`define     end_wrburst     cnt_clk == sdram_rd_burst_len - 1           //дͻ����ֹ
`define     end_twrite      cnt_clk == sdram_rd_burst_len - 1           //ͻ��д����
`define     end_twr         cnt_clk == TWR_CLK                          //д�����ڽ���

//SDRAM�����ź�����
`define     CMD_INIT        5'b01111                                    //INITIATE
`define     CMD_NOP         5'b10111                                    //NOP COMMAND
`define     CMD_ACTIVE      5'b10011                                    //ACTIVE COMMAND
`define     CMD_READ        5'b10101                                    //READ COMMADN
`define     CMD_WRITE       5'b10100                                    //WRITE COMMAND
`define     CMD_B_STOP      5'b10110                                    //BURST STOP
`define     CMD_PRGE        5'b10010                                    //PRECHARGE
`define     CMD_A_REF       5'b10001                                    //AOTO REFRESH
`define     CMD_LMR         5'b10000                                    //LODE MODE REGISTER

// ---------------------------------------------------------------------------------
// �������� Constant Parameters
// ---------------------------------------------------------------------------------



`endif	//SDRAM_PARA