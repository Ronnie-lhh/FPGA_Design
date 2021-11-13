// *********************************************************************************
// �ļ���: sdram_state_ctrl.v   
// ������: ���Ժ�
// ��������: 2021.3.4
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: sdram_state_ctrl
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)SDRAM״̬����ģ��     
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
`include "sdram_para.v"                             //SDRAM��������ģ��

// ---------------------------------------------------------------------------------
// ����ʱ�� Simulation Timescale
// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// �������� Constant Parameters
// ---------------------------------------------------------------------------------
    

// ---------------------------------------------------------------------------------
// ģ�鶨�� Module Define
// --------------------------------------------------------------------------------- 
module sdram_state_ctrl
#(
    parameter TRP_CLK  = 10'd4,                     //Ԥ�����Ч����
    parameter TRFC_CLK = 10'd6,                     //�Զ�ˢ������
    parameter TRSC_CLK = 10'd6,                     //ģʽ�Ĵ�������ʱ������
    parameter TRCD_CLK = 10'd2,                     //��ѡͨ����
    parameter TCL_CLK  = 10'd3,                     //��Ǳ������
    parameter TWR_CLK  = 10'd2                      //д��У������
)
(
    // clock & reset
    input               clk,                        //ϵͳʱ��
    input               rst_n,                      //��λ�ź�, �͵�ƽ��Ч
    
    input               sdram_wr_req,               //дSDRAM�����ź�
    input               sdram_rd_req,               //��SDRAM�����ź�
    output              sdram_wr_ack,               //дSDRAM��Ӧ�ź�
    output              sdram_rd_ack,               //��SDRAM��Ӧ�ź�
    input      [9 : 0]  sdram_wr_burst_len,         //дSDRAM������ͻ������(1~512���ֽ�)
    input      [9 : 0]  sdram_rd_burst_len,         //��SDRAM������ͻ������(1~256���ֽ�)
    output              sdram_init_done,            //SDRAM��ʼ����ɱ�־

    output reg [4 : 0]  sdram_init_state,           //SDRAM��ʼ��״̬
    output reg [3 : 0]  sdram_work_state,           //SDRAM����״̬
    output reg [9 : 0]  cnt_clk,                    //ʱ�Ӽ�����
    output reg          sdram_rd_wr_ctrl            //SDRAM��/д�����ź�, д(0), ��(1)
);



// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------
   
   
// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    reg  [14 : 0] cnt_pw_200us;                     //SDRAM�ϵ��ȶ���200us������
    reg  [10 : 0] cnt_refresh;                      //ˢ�¼����Ĵ���
    reg           sdram_ref_req;                    //SDRAM�Զ�ˢ�������ź�
    reg           cnt_rst_n;                        //��ʱ��������λ�źţ��͵�ƽ��Ч
    reg  [ 3 : 0] cnt_init_ar;                      //��ʼ�������Զ�ˢ�¼�����
   
    wire          done_pw_200us;                    //�ϵ��200us�����ȶ��ڽ�����־
    wire          sdram_ref_ack;                    //SDRAM�Զ�ˢ��Ӧ���ź�
	
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// --------------------------------------------------------------------------------- 
    //SDRAM�ϵ��200us�ȶ��ڽ�����,����־�ź�����
    assign done_pw_200us = (cnt_pw_200us == 15'd20000);
    
    //SDRAM��ʼ����ɱ�־
    assign sdram_init_done = (sdram_init_state == `I_DONE);
    
    //SDRAM�Զ�ˢ��Ӧ���ź�
    assign sdram_ref_ack = (sdram_work_state == `W_AR);
    
    //дSDRAM��Ӧ�ź�
    assign sdram_wr_ack = ((sdram_work_state == `W_TRCD) && ~sdram_rd_wr_ctrl) ||
                          ( sdram_work_state == `W_WRITE) ||
                          ((sdram_work_state == `W_WD) &&
                          ( cnt_clk < sdram_wr_burst_len - 2'd2));
   
   //��SDRAM��Ӧ�ź�
    assign sdram_rd_ack = (sdram_work_state == `W_RD) &&
                          (cnt_clk >= 10'd1) &&
                          (cnt_clk < sdram_rd_burst_len + 2'd1);
    
// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    //�ϵ���ʱ200us,�ȴ�SDRAM״̬�ȶ�
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cnt_pw_200us <= 15'd0;
        end
        else if(cnt_pw_200us < 15'd20000)
        begin
            cnt_pw_200us <= cnt_pw_200us + 15'd1;
        end
        else
        begin
            cnt_pw_200us <= cnt_pw_200us;
        end
    end

    //ˢ�¼�����ѭ������7812ns (60ms�����ȫ��8192��ˢ�²���)
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n) 
        begin
            cnt_refresh <= 11'd0;
        end
        else if(cnt_refresh < 11'd781)      //64ms/8192=7812ns
        begin
            cnt_refresh <= cnt_refresh + 15'd1;
        end
        else
        begin
            cnt_refresh <= 11'd0;
        end
    end
    
    //SDRAMˢ������
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_ref_req <= 1'b0;
        end
        else if(cnt_refresh == 11'd780)     
        begin
            sdram_ref_req <= 1'b1;          //ˢ�¼�������ʱ��7812nsʱ����ˢ������
        end
        else if(sdram_ref_ack)
        begin
            sdram_ref_req <= 1'b0;          //�յ�ˢ��������Ӧ�źź�ȡ��ˢ������ 
        end
        else
        begin
            sdram_ref_req <= sdram_ref_req;
        end
    end
    
    //ʱ�Ӽ�����
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cnt_clk <= 10'd0;
        end
        else if(!cnt_rst_n)
        begin
            cnt_clk <= 10'd0;               //��cnt_rst_n��Чʱʱ�Ӽ���������
        end
        else
        begin
            cnt_clk <= cnt_clk + 10'd1;
        end
    end

    //��ʼ�������ж��Զ�ˢ�²�������
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cnt_init_ar <= 4'd0;
        end
        else if(sdram_init_state == `I_NOP)
        begin
            cnt_init_ar <= 4'd0;
        end
        else if(sdram_init_state == `I_AR)
        begin
            cnt_init_ar <= cnt_init_ar + 4'd1;
        end
        else
        begin
            cnt_init_ar <= cnt_init_ar;
        end
    end

    //SDRAM�ĳ�ʼ��״̬��, ��ʼ��״̬����Ԥ��硢�Զ�ˢ�¡�ģʽ�Ĵ������õȲ���
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_init_state <= `I_NOP;
        end
        else
        begin
            case(sdram_init_state)
                            //�ϵ縴λ��200us�����������һ״̬
                `I_NOP:  sdram_init_state <= done_pw_200us? `I_PRE : `I_NOP;
                            //Ԥ���״̬
                `I_PRE:  sdram_init_state <= `I_TRP;
                            //Ԥ���ȴ�״̬, �ȴ�TRP_CLK��ʱ������
                `I_TRP:  sdram_init_state <= (`end_trp)? `I_AR : `I_TRP;
                            //�Զ�ˢ��״̬
                `I_AR:   sdram_init_state <= `I_TRF;
                            //�Զ�ˢ�µȴ�״̬, �ȴ�TRC_CLK��ʱ������
                `I_TRF:  sdram_init_state <= (`end_trfc)? 
                                             //����8���Զ�ˢ�²���
                                             ((cnt_init_ar == 4'd8)? `I_MRS : `I_AR) : `I_TRF;
                            //ģʽ�Ĵ�������״̬
                `I_MRS:  sdram_init_state <= `I_TRSC;
                            //ģʽ�Ĵ������õȴ�״̬, �ȴ�TRSC_CLK��ʱ������
                `I_TRSC: sdram_init_state <= (`end_trfc)? `I_DONE : `I_TRSC;
                            //SDRAM��ʼ�����״̬
                `I_DONE: sdram_init_state <= `I_DONE;
                                
                default: sdram_init_state <= `I_NOP;
            endcase
        end
    end
    
    //SDRAM�Ĺ���״̬��,����״̬��������д�Լ��Զ�ˢ�²���
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_work_state <= `W_IDLE;    //����״̬
        end
        else
        begin
            case(sdram_work_state)
                                //��ʱ�Զ�ˢ������, ��ת���Զ�ˢ��״̬
                `W_IDLE:    if(sdram_ref_req & sdram_init_done)
                             begin
                                sdram_work_state <= `W_AR;
                                sdram_rd_wr_ctrl <= 1'b1;
                             end
                                //дSDRAM����, ��ת������Ч״̬
                             else if(sdram_wr_req & sdram_init_done)
                             begin
                                sdram_work_state <= `W_ACTIVE;
                                sdram_rd_wr_ctrl <= 1'b0;
                             end
                                //��SDRAM����, ��ת������Ч״̬
                             else if(sdram_rd_req & sdram_init_done)
                             begin
                                sdram_work_state <= `W_ACTIVE;
                                sdram_rd_wr_ctrl <= 1'b1;
                             end
                                //�޲�������, ���ֿ���״̬
                             else
                             begin
                                sdram_work_state <= `W_IDLE;
                                sdram_rd_wr_ctrl <= 1'b1;
                             end
                                //����Ч״̬, ��ת������Ч�ȴ�״̬
                `W_ACTIVE:  sdram_work_state <= `W_TRCD;
                                //����Ч�ȴ�״̬����, �жϵ�ǰ�Ƕ�orд
                `W_TRCD:    if(`end_trcd)
                            begin
                                if(sdram_rd_wr_ctrl)    //��: ���������״̬
                                begin
                                    sdram_work_state <= `W_READ;
                                end
                                else                    //д: ����д����״̬
                                begin
                                    sdram_work_state <= `W_WRITE;
                                end
                            end
                            else
                            begin
                                sdram_work_state <= `W_TRCD;
                            end
                                //������״̬, ��ת����Ǳ����
                `W_READ:    sdram_work_state <= `W_CL;
                                //��Ǳ����, �ȴ�Ǳ���ڽ���, ��ת��������״̬
                `W_CL:      sdram_work_state <= (`end_tcl)? `W_RD : `W_CL; 
                                //������״̬, �ȴ������ݽ���, ��ת��Ԥ���״̬
                `W_RD:      sdram_work_state <= (`end_tread)? `W_PRE : `W_RD;
                                //д����״̬, ��ת��д����״̬
                `W_WRITE:   sdram_work_state <= `W_WD;
                                //д����״̬, �ȴ�д���ݽ���, ��ת��д������״̬
                `W_WD:      sdram_work_state <= (`end_twrite)? `W_TWR : `W_WD;
                                //д������״̬, д�����ڽ���, ��ת��Ԥ���״̬
                `W_TWR:     sdram_work_state <= (`end_twr)? `W_PRE : `W_TWR;
                                //Ԥ���״̬, ��ת��Ԥ���ȴ�״̬
                `W_PRE:     sdram_work_state <= `W_TRP;
                                //Ԥ���ȴ�״̬, Ԥ���ȴ�����, �������״̬
                `W_TRP:     sdram_work_state <= (`end_trp)? `W_IDLE : `W_TRP;
                                //�Զ�ˢ��״̬, ��ת���Զ�ˢ�µȴ�״̬
                `W_AR:      sdram_work_state <= `W_TRFC;
                                //�Զ�ˢ�µȴ�״̬, �Զ�ˢ�µȴ�����, �������״̬
                `W_TRFC:    sdram_work_state <= (`end_trfc)? `W_IDLE : `W_TRFC;

                 default:   sdram_work_state <= `W_IDLE;
            endcase
        end
    end
    
    //�����������߼�
    always @(*)
    begin
        case(sdram_init_state)
                                //��ʱ����������(cnt_rst_n�͵�ƽ��λ)
            `I_NOP:   cnt_rst_n <= 1'b0;
                                //Ԥ���״̬, ��ʱ����������(cnt_rst_n�ߵ�ƽ����)
            `I_PRE:   cnt_rst_n <= 1'b1;
                                //�ȴ�Ԥ�����ʱ����������, ���������
            `I_TRP:   cnt_rst_n <= (`end_trp)? 1'b0 : 1'b1;
                                //�Զ�ˢ��״̬, ��ʱ����������
            `I_AR:    cnt_rst_n <= 1'b1;
                                //�ȴ��Զ�ˢ����ʱ����������, ��������� 
            `I_TRF:   cnt_rst_n <= (`end_trfc)? 1'b0 : 1'b1;
                                //ģʽ�Ĵ�������״̬, ��ʱ����������
            `I_MRS:   cnt_rst_n <= 1'b1;
                                //�ȴ�ģʽ�Ĵ���������ʱ����������, ���������
            `I_TRSC:  cnt_rst_n <= (`end_trsc)? 1'b0 : 1'b1;
            
                                //��ʼ����ɺ�, �ж�SDRAM����״̬
            `I_DONE:  
                begin 
                    case(sdram_work_state)
                    
                        `W_IDLE:    cnt_rst_n <= 1'b0;
                                //����Ч״̬, ��ʱ����������
                        `W_ACTIVE:  cnt_rst_n <= 1'b1;
                                //����Ч��ʱ����������, ���������
                        `W_TRCD:    cnt_rst_n <= (`end_trcd)? 1'b0 : 1'b1;
                                //��Ǳ������ʱ����������, ���������
                        `W_CL:	    cnt_rst_n <= (`end_tcl)? 1'b0 : 1'b1;
                                //��������ʱ����������, ���������
                        `W_RD:	    cnt_rst_n <= (`end_tread)? 1'b0 : 1'b1;
                                //д������ʱ����������, ���������
                        `W_WD:	    cnt_rst_n <= (`end_twrite)? 1'b0 : 1'b1; 
                                //д��������ʱ����������, ���������
                        `W_TWR:	    cnt_rst_n <= (`end_twr)? 1'b0 : 1'b1;
                                //Ԥ���ȴ���ʱ����������, ���������
                        `W_TRP:	    cnt_rst_n <= (`end_trp)? 1'b0 : 1'b1;
                                //�Զ�ˢ�µȴ���ʱ����������, ���������
                        `W_TRFC:    cnt_rst_n <= (`end_trfc)? 1'b0 : 1'b1;
                        
                        default:    cnt_rst_n <= 1'b0;
                    endcase
                end
            
            default:  cnt_rst_n <= 1'b0;
        endcase
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


















