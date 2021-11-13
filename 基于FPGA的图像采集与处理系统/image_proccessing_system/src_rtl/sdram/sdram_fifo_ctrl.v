// *********************************************************************************
// �ļ���: sdram_fifo_ctrl.v   
// ������: ���Ժ�
// ��������: 2021.3.8
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: sdram_fifo_ctrl
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)SDRAM��д�˿�FIFO����ģ��    
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
module sdram_fifo_ctrl
(
    // clock & reset
    input 			     clk_ref,		         //SDRAM������ʱ��
	input 			     rst_n,  		         //ϵͳ��λ�ź�, �͵�ƽ��Ч

    // �û�д�˿�
    input                clk_write,              //д�˿�FIFO: дʱ�� 
    input                wrf_wrreq,              //д�˿�FIFO: д���� 
    input       [15 : 0] wrf_din,                //д�˿�FIFO: д���� 
    input       [23 : 0] wr_min_addr,            //дSDRAM����ʼ��ַ
    input       [23 : 0] wr_max_addr,            //дSDRAM�Ľ�����ַ
    input       [ 9 : 0] wr_len,                 //дSDRAM������ͻ������ 
    input                wr_load,                //д�˿ڸ�λ: ��λд��ַ, ���дFIFO 
    
    // �û����˿�
    input                clk_read,               //���˿�FIFO: ��ʱ��
    input                rdf_rdreq,              //���˿�FIFO: ������ 
    output      [15 : 0] rdf_dout,               //���˿�FIFO: ������
    input       [23 : 0] rd_min_addr,            //��SDRAM����ʼ��ַ
    input       [23 : 0] rd_max_addr,            //��SDRAM�Ľ�����ַ
    input       [ 9 : 0] rd_len,                 //��SDRAM�ж����ݵ�ͻ������ 
    input                rd_load,                //���˿ڸ�λ: ��λ����ַ, ��ն�FIFO
    
    // �û����ƶ˿�
    input                sdram_read_valid,       //SDRAM��ʹ��
    input                sdram_init_done,        //SDRAM��ʼ����ɱ�־
    input                sdram_pingpang_en,      //SDRAM��дƹ�Ҳ���ʹ��
    
    // SDRAM������д�˿�
    output reg           sdram_wr_req,           //SDRAMд����
    input                sdram_wr_ack,           //SDRAMд��Ӧ
    output reg  [23 : 0] sdram_wr_addr,          //SDRAMд��ַ
    output      [15 : 0] sdram_din,              //д��SDRAM�е����� 
                                                 
    // SDRAM���������˿�                          
    output reg           sdram_rd_req,           //SDRAM������
    input                sdram_rd_ack,           //SDRAM����Ӧ
    output reg  [23 : 0] sdram_rd_addr,          //SDRAM����ַ 
    input       [15 : 0] sdram_dout              //��SDRAM�ж��������� 
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------
   
   
// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    reg             wr_ack_r1;                   //SDRAMд��Ӧ�Ĵ���    
    reg             wr_ack_r2;                   
    reg             rd_ack_r1;                   //SDRAM����Ӧ�Ĵ���    
	reg             rd_ack_r2;                   
    reg             wr_load_r1;                  //д�˿ڸ�λ�Ĵ���     
    reg             wr_load_r2;                  
    reg             rd_load_r1;                  //���˿ڸ�λ�Ĵ���     
    reg             rd_load_r2;                  
    reg             read_valid_r1;               //SDRAM��ʹ�ܼĴ���    
    reg             read_valid_r2;               
    reg             sw_bank_en;                  //�л�BANKʹ���ź�
    reg             rw_bank_flag;                //��дBANK��־�ź�
    
    wire            wr_done_flag;                //sdram_wr_ack�½��ر�־λ 
    wire            rd_done_flag;                //sdram_rd_ack�½��ر�־λ 
    wire            wr_load_flag;                //wr_load�����ر�־λ 
    wire            rd_load_flag;                //rd_load�����ر�־λ 
    wire [9 : 0]    wrf_use;                     //д�˿�FIFO�е�������
    wire [9 : 0]    rdf_use;                     //���˿�FIFO�е�������
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// --------------------------------------------------------------------------------- 
    //����½���
    assign wr_done_flag = wr_ack_r2 & ~wr_ack_r1;
    assign rd_done_flag = rd_ack_r2 & ~rd_ack_r1;
    
    //���������
    assign wr_load_flag = ~wr_load_r2 & wr_load_r1;
    assign rd_load_flag = ~rd_load_r2 & rd_load_r1;
    
    
// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    //�Ĵ�SDRAMд��Ӧ�ź�, ���ڲ���sdram_wr_ack�½���
    always @(posedge clk_ref or negedge rst_n)
    begin
        if(!rst_n)
        begin
            wr_ack_r1 <= 1'b0;
            wr_ack_r2 <= 1'b0;
        end
        else 
        begin
            wr_ack_r1 <= sdram_wr_ack;
            wr_ack_r2 <= wr_ack_r1;
        end
    end

    //�Ĵ�SDRAM����Ӧ�ź�, ���ڲ���sdram_rd_ack�½���
    always @(posedge clk_ref or negedge rst_n) 
    begin
        if(!rst_n) 
        begin
            rd_ack_r1 <= 1'b0;
            rd_ack_r2 <= 1'b0;
        end
        else 
        begin
            rd_ack_r1 <= sdram_rd_ack;
            rd_ack_r2 <= rd_ack_r1;
        end
    end 

    //ͬ��д�˿ڸ�λ�ź�, ���ڲ���wr_load������ (��ʱ����ͬ��)
    always @(posedge clk_ref or negedge rst_n) 
    begin
        if(!rst_n) 
        begin
            wr_load_r1 <= 1'b0;
            wr_load_r2 <= 1'b0;
        end
        else 
        begin
            wr_load_r1 <= wr_load;
            wr_load_r2 <= wr_load_r1;
        end
    end

    //ͬ�����˿ڸ�λ�ź�, ���ڲ���rd_load������ (��ʱ����ͬ��)
    always @(posedge clk_ref or negedge rst_n) 
    begin
        if(!rst_n) 
        begin
            rd_load_r1 <= 1'b0;
            rd_load_r2 <= 1'b0;
        end
        else 
        begin
            rd_load_r1 <= rd_load;
            rd_load_r2 <= rd_load_r1;
        end
    end
    
    //ͬ��SDRAM��ʹ���ź� (��ʱ����ͬ��)
    always @(posedge clk_ref or negedge rst_n) 
    begin
        if(!rst_n) 
        begin
            read_valid_r1 <= 1'b0;
            read_valid_r2 <= 1'b0;
        end
        else 
        begin
            read_valid_r1 <= sdram_read_valid;
            read_valid_r2 <= read_valid_r1;
        end
    end

    //SDRAMд��ַ����ģ��
    always @(posedge clk_ref or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_wr_addr <= 24'd0;
            sw_bank_en <= 1'b0;
            rw_bank_flag <= 1'b0;
        end
        //��⵽д�˿ڸ�λ�ź�ʱ, д��ַ��λ
        else if(wr_load_flag)       
        begin
            sdram_wr_addr <= wr_min_addr;
            sw_bank_en <= 1'b0;
            rw_bank_flag <= 1'b0;
        end
        //��ͻ��дSDRAM����, ����д��ַ
        else if(wr_done_flag)
        begin
            //��SDRAM��дʹ��ƹ�Ҳ���
            if(sdram_pingpang_en)
            begin
                //��δ����дSDRAM�Ľ�����ַ, ��д��ַ�ۼ�
                if(sdram_wr_addr[22 : 0] < wr_max_addr - wr_len)
                begin
                    sdram_wr_addr <= sdram_wr_addr + wr_len;
                end
                //������дSDRAM�Ľ�����ַ, ���л�BANK
                else
                begin
                    rw_bank_flag <= ~rw_bank_flag;
                    sw_bank_en <= 1'b1;             //�����л�BANKʹ���ź�
                end
            end
            
            //����ʹ��ƹ�Ҳ���, ��δ����дSDRAM�Ľ�����ַ, ��д��ַ�ۼ�
            else if(sdram_wr_addr < wr_max_addr - wr_len)
            begin
                sdram_wr_addr <= sdram_wr_addr + wr_len;
            end
            //����ʹ��ƹ�Ҳ���, ������дSDRAM�Ľ�����ַ, ��ص�д��ʼ��ַ
            else
            begin
                sdram_wr_addr <= wr_min_addr;
            end
        end
        //���л�BANKʹ���ź�Ϊ�� (���ƹ�Ҷ�д���������)
        else if(sw_bank_en) 
        begin
            sw_bank_en <= 1'b0;         //�����л�BANKʹ���ź�
            //����дBANK��־�ź�Ϊ0, ���л�ΪBANK0
            if(rw_bank_flag == 1'b0)
            begin
                sdram_wr_addr <= {1'b0, wr_min_addr[22 : 0]};
            end
            //����дBANK��־�ź�Ϊ1, ���л�ΪBANK1
            else
            begin
                sdram_wr_addr <= {1'b1, wr_min_addr[22 : 0]};
            end
        end
        
        else
        begin
            sdram_wr_addr <= sdram_wr_addr;
            sw_bank_en <= sw_bank_en;
            rw_bank_flag <= rw_bank_flag;
        end
    end
    
    //SDRAM����ַ����ģ��
    always @(posedge clk_ref or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_rd_addr <= 24'd0;
        end
        //��⵽���˿ڸ�λ�ź�ʱ������ַ��λ
        else if(rd_load_flag)
        begin
            sdram_rd_addr <= rd_min_addr;
        end
        //ͻ����SDRAM����, ���Ķ���ַ
        else if(rd_done_flag)
        begin
            //��SDRAM��дʹ��ƹ�Ҳ���
            if(sdram_pingpang_en)
            begin
                //��δ�����SDRAM�Ľ�����ַ, �����ַ�ۼ�
                if(sdram_rd_addr[22 : 0] < rd_max_addr - rd_len)
                begin
                    sdram_rd_addr <= sdram_rd_addr + rd_len;
                end
                //�������SDRAM�Ľ�����ַ, ��ص�����ʼ��ַ
                //��ȡû������д���ݵ�BANK
                else
                begin
                    //����rw_bank_flag��ֵ�л���BANK��ַ
                    if(rw_bank_flag == 1'b0)
                    begin
                        sdram_rd_addr <= {1'b1, rd_min_addr[22 : 0]};
                    end
                    else 
                    begin
                        sdram_rd_addr <= {1'b0, rd_min_addr[22 : 0]};
                    end
                end
            end
            
            //����ʹ��ƹ�Ҳ���, ��δ�����SDRAM�Ľ�����ַ, �����ַ�ۼ�
            else if(sdram_rd_addr < rd_max_addr - rd_len)
            begin
                sdram_rd_addr <= sdram_rd_addr + rd_len;
            end
            //����ʹ��ƹ�Ҳ���, �������SDRAM�Ľ�����ַ, ��ص�����ʼ��ַ
            else
            begin
                sdram_rd_addr <= rd_min_addr;
            end
        end
        
        else
        begin
            sdram_rd_addr <= sdram_rd_addr;
        end
    end

    //SDRAM��д�����źŲ���ģ��
    always @(posedge clk_ref or negedge rst_n)
    begin
        if(!rst_n)
        begin
            sdram_wr_req <= 1'b0;
            sdram_rd_req <= 1'b0;
        end
        //SDRAM��ʼ����ɺ������Ӧ��д����
        //����ִ��д����, ��ֹд��SDRAM�е����ݶ�ʧ
        else if(sdram_init_done)
        begin
            //��д�˿�FIFO�е��������ﵽ��дͻ������, �򷢳�дSDRAM����
            if(wrf_use >= wr_len)
            begin
                sdram_wr_req <= 1'b1;
                sdram_rd_req <= 1'b0;
            end
            //�����˿�FIFO�е�������С�ڶ�ͻ������, 
            //ͬʱSDRAM��ʹ���ź�Ϊ��, �򷢳���SDRAM����
            else if((rdf_use < rd_len) && read_valid_r2)
            begin
                sdram_wr_req <= 1'b0;
                sdram_rd_req <= 1'b1;
            end
            else 
            begin
                sdram_wr_req <= 1'b0;
                sdram_rd_req <= 1'b0;
            end
        end
        else
        begin
            sdram_wr_req <= 1'b0;
            sdram_rd_req <= 1'b0;
        end
    end


// ---------------------------------------------------------------------------------
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------
    // ����д�˿�FIFO
    wr_fifo     U_wr_fifo
    (
        //�û��ӿ�
        .wr_clk                 (clk_write),                //дʱ��
        .wr_en                  (wrf_wrreq),                //д����
        .din                    (wrf_din),                  //д����
        //SDRAM�ӿ�
        .rd_clk                 (clk_ref),                  //��ʱ��
        .rd_en                  (sdram_wr_ack),             //������
        .dout                   (sdram_din),                //������

        .rd_data_count          (wrf_use),                  //FIFO�еĿɶ�������
        .rst                    (~rst_n | wr_load_flag),    //�첽�����ź�
        .full                   (),                         //FIFO���ź�
        .empty                  (),                         //FIFO���ź�
        .wr_data_count          ()                          //FIFO�е���д������
    );
    
    
    // �������˿�FIFO
    rd_fifo     U_rd_fifo
    (
        //SDRAM�ӿ�
        .wr_clk                 (clk_ref),                  //дʱ��
        .wr_en                  (sdram_rd_ack),             //д����
        .din                    (sdram_dout),               //д����
        //�û��ӿ�                                          
        .rd_clk                 (clk_read),                 //��ʱ��
        .rd_en                  (rdf_rdreq),                //������
        .dout                   (rdf_dout),                 //������

        .rd_data_count          (),                         //FIFO�еĿɶ�������
        .rst                    (~rst_n | rd_load_flag),    //�첽�����ź�
        .full                   (),                         //FIFO���ź�
        .empty                  (),                         //FIFO���ź�
        .wr_data_count          (rdf_use)                   //FIFO�е���д������
    );


// ---------------------------------------------------------------------------------
// ������ Called Tasks
// ---------------------------------------------------------------------------------
    
	
// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------

    
endmodule 