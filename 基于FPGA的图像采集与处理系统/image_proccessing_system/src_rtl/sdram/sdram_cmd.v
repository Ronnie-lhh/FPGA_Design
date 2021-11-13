// *********************************************************************************
// �ļ���: sdram_cmd.v   
// ������: ���Ժ�
// ��������: 2021.3.10
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: sdram_cmd
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)SDRAM�������ģ��
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
`include "sdram_para.v"                     //����SDRAM��������ģ��

// ---------------------------------------------------------------------------------
// ����ʱ�� Simulation Timescale
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// �������� Constant Parameters
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// ģ�鶨�� Module Define
// --------------------------------------------------------------------------------- 
module sdram_cmd
(
    // clock & reset
    input 			    clk,		            //SDRAM������ʱ��
	input 			    rst_n,  		        //ϵͳ��λ�ź�, �͵�ƽ��Ч

    // input signal
    input      [23 : 0] sys_wr_addr,            //дSDRAMʱ��ַ
    input      [23 : 0] sys_rd_addr,            //��SDRAMʱ��ַ
    input      [ 9 : 0] sdram_wr_burst_len,     //ͻ��дSDRAM�ֽ���
    input      [ 9 : 0] sdram_rd_burst_len,     //ͻ����SDRAM�ֽ���
       
    input      [ 4 : 0] sdram_init_state,       //SDRAM��ʼ��״̬
    input      [ 3 : 0] sdram_work_state,       //SDRAM����״̬
    input      [ 9 : 0] cnt_clk,                //ʱ�Ӽ����� 
    input               sdram_rd_wr_ctrl,       //SDRAM��/д�����ź�, д(0), ��(1)
    
    // output signal                       
    output              sdram_cke,              //SDRAMʱ����Ч�ź�
    output              sdram_cs_n,             //SDRAMƬѡ�ź�
    output              sdram_ras_n,            //SDRAM�е�ַѡͨ����
    output              sdram_cas_n,            //SDRAM�е�ַѡͨ����
    output              sdram_we_n,             //SDRAMд����λ
    output reg [ 1 : 0] sdram_ba,               //SDRAM��L-Bank��ַ��
    output reg [12 : 0] sdram_addr              //SDRAM��ַ����
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------
   
   
// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    reg        [ 4 : 0] sdram_cmd_r;            //SDRAM����ָ��
	
    wire       [23 : 0] sys_addr;               //SDRAM��д��ַ
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// --------------------------------------------------------------------------------- 
    //SDRAM�����ź��߸�ֵ
    assign {sdram_cke, sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = sdram_cmd_r;
    
    //SDRAM��/д��ַ���߿���
    assign sys_addr = sdram_rd_wr_ctrl? sys_rd_addr : sys_wr_addr;
    
// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    //SDRAM����ָ�����
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_cmd_r <= `CMD_INIT;
            sdram_ba <= 2'b11;
            sdram_addr <= 13'h1fff;
        end
        else
        begin
            case(sdram_init_state)
                            //��ʼ��������, ����״̬��ִ���κ�ָ��
                `I_NOP, `I_TRP, `I_TRF, `I_TRSC: 
                    begin
                        sdram_cmd_r <= `CMD_NOP;
                        sdram_ba    <= 2'b11;
                        sdram_addr  <= 13'h1fff;
                    end
                `I_PRE:     //Ԥ���ָ��
                    begin
                        sdram_cmd_r <= `CMD_PRGE;
                        sdram_ba    <= 2'b11;
                        sdram_addr  <= 13'h1fff;
                    end
                `I_AR:      //�Զ�ˢ��ָ��
                    begin
                        sdram_cmd_r <= `CMD_A_REF;
                        sdram_ba    <= 2'b11;
                        sdram_addr  <= 13'h1fff;
                    end
                `I_MRS:     //ģʽ�Ĵ�������ָ��
                    begin
                        sdram_cmd_r <= `CMD_LMR;
                        sdram_ba    <= 2'b00;
                        sdram_addr  <=       //���õ�ַ������ģʽ�Ĵ���, �ɸ���ʵ����Ҫ�����޸�
                        {
                            3'b000,         //Ԥ��
                            1'b0,           //��д��ʽ, A9=0, ͻ����&ͻ��д
                            2'b00,          //Ĭ��, {A8,A7}=00
                            3'b011,         //CASǱ��������, ��������Ϊ3, {A6,A5,A4}=011
                            1'b0,           //ͻ�����䷽ʽ, ��������Ϊ˳��, A3=0
                            3'b111          //ͻ������, ��������Ϊҳͻ��, {A2,A1,A0}=011
                        };
                    end
                `I_DONE:    //SDRAM��ʼ�����
                    begin
                        case(sdram_work_state)
                                            //���¹���״̬��ִ���κ�ָ��
                            `W_IDLE, `W_TRCD, `W_CL, `W_TWR, `W_TRP, `W_TRFC:
                                begin
                                    sdram_cmd_r <= `CMD_NOP;
                                    sdram_ba    <= 2'b11;
                                    sdram_addr  <= 13'h1fff;
                                end
                            `W_ACTIVE:      //����Чָ��
                                begin
                                    sdram_cmd_r <= `CMD_ACTIVE;
                                    sdram_ba    <= sys_addr[23 : 22];
                                    sdram_addr  <= sys_addr[21 : 9 ];
                                end
                            `W_READ:        //������ָ��
                                begin
                                    sdram_cmd_r <= `CMD_READ;
                                    sdram_ba    <= sys_addr[23 : 22];
                                    sdram_addr  <= {4'b0000, sys_addr[ 8 : 0 ]};
                                end
                            `W_RD:          
                                begin
                                    if(`end_rdburst)    //ͻ��������ָֹ��
                                    begin
                                        sdram_cmd_r <= `CMD_B_STOP;
                                    end
                                    else
                                    begin
                                        sdram_cmd_r <= `CMD_NOP;
                                        sdram_ba    <= 2'b11;
                                        sdram_addr  <= 13'h1fff;
                                    end
                                end
                            `W_WRITE:       //д����ָ��
                                begin
                                    sdram_cmd_r <= `CMD_WRITE;
                                    sdram_ba    <= sys_addr[23 : 22];
                                    sdram_addr  <= {4'b0000, sys_addr[ 8 : 0 ]};
                                end
                            `W_WD:
                                begin
                                    if(`end_wrburst)    //ͻ��������ָֹ��
                                    begin
                                        sdram_cmd_r <= `CMD_B_STOP;
                                    end
                                    else
                                    begin
                                        sdram_cmd_r <= `CMD_NOP;
                                        sdram_ba    <= 2'b11;
                                        sdram_addr  <= 13'h1fff;
                                    end
                                end
                            `W_PRE:         //Ԥ���ָ��
                                begin
                                    sdram_cmd_r <= `CMD_PRGE;
                                    sdram_ba    <= sys_addr[23 : 22];
                                    sdram_addr  <= 13'h0400;
                                end
                            `W_AR:          //�Զ�ˢ��ָ��
                                begin
                                    sdram_cmd_r <= `CMD_A_REF;
                                    sdram_ba    <= 2'b11;
                                    sdram_addr  <= 13'h1fff;
                                end
                            default:
                                begin
                                    sdram_cmd_r <= `CMD_NOP;
                                    sdram_ba    <= 2'b11;
                                    sdram_addr  <= 13'h1fff;
                                end
                        endcase
                    end
                default:
                    begin
                        sdram_cmd_r <= `CMD_NOP;
                        sdram_ba    <= 2'b11;
                        sdram_addr  <= 13'h1fff;
                    end
            endcase
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