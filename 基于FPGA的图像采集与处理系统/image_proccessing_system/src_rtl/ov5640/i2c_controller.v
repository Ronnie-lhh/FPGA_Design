// *********************************************************************************
// �ļ���: i2c_controller.v   
// ������: ���Ժ�
// ��������: 2021.3.16
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: i2c_controller
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)IIC����ģ��
//            2)������ʹ��IICЭ���Ӧ�ó���
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
module i2c_controller
#(
    // parameter passing
    parameter   SLAVE_ADDR = 7'h3c,             //������ַ
    parameter   CLK_FREQ   = 27'd100_000_000,   //ģ�������ʱ��Ƶ��
    parameter   I2C_FREQ   = 18'd250_000        //I2C��SCLʱ��Ƶ��
)
(
    // clock & reset
    input 			    clk,		            //ģ�������ʱ��
	input 			    rst_n,  		        //��λ�ź�, �͵�ƽ��Ч

    // i2c interface
    input               i2c_exec,               //I2C����ִ���ź�
    input               bit_ctrl,               //�ֵ�ַλ����(16b/8b)
    input               i2c_rw_ctrl,            //I2C��д�����ź�, ��(1)/д(0)
    input      [15 : 0] i2c_addr,               //I2C�����ڵ�ַ
    input      [ 7 : 0] i2c_wr_data,            //I2CҪд������
    output reg [ 7 : 0] i2c_rd_data,            //I2C����������
    output reg          i2c_done,               //I2Cһ�β�����ɱ�־
    output reg          scl,                    //I2C��SCLʱ���ź�
    inout               sda,                    //I2C��SDA�ź�
    
    // user interface
    output reg          clk_dri                 //I2C����������ʱ��
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------
   //����״̬����״̬����
   localparam   S_IDLE      = 8'b00000001;      //����״̬
   localparam   S_SLADDR    = 8'b00000010;      //����������ַ
   localparam   S_ADDR16    = 8'b00000100;      //����16λ�ֵ�ַ
   localparam   S_ADDR8     = 8'b00001000;      //����8λ�ֵ�ַ
   localparam   S_WR_DATA   = 8'b00010000;      //д����(8 bit)
   localparam   S_RD_ADDR   = 8'b00100000;      //����������ַ��
   localparam   S_RD_DATA   = 8'b01000000;      //������(8 bit)
   localparam   S_STOP      = 8'b10000000;      //����I2C����

// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    reg                 sda_en;                 //SDA���ݷ�������ź�
    reg                 sda_out;                //SDA����ź�
    reg                 s_done;                 //״̬������־
    reg                 wr_flag;                //д��־
    reg        [ 6 : 0] cnt;                    //ʱ�����ڼ�����
    reg        [ 7 : 0] cur_state;              //״̬����ǰ״̬
    reg        [ 7 : 0] nxt_state;              //״̬����һ״̬
    reg        [15 : 0] addr_t;                 //��ַ
    reg        [ 7 : 0] rd_data;                //��ȡ������
    reg        [ 7 : 0] wr_data_t;              //I2C��д���ݵ���ʱ�Ĵ�
    reg        [ 9 : 0] clk_cnt;                //��Ƶʱ�Ӽ���
	
    wire                sda_in;                 //SDA�����ź�
    wire       [ 8 : 0] clk_div;                //ģ������ʱ�ӵķ�Ƶϵ��
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// --------------------------------------------------------------------------------- 
    //SDA����
    assign sda     = sda_en? sda_out : 1'bz;         //��SDAΪ����ʱ, �����������
    assign sda_in  = sda;                            //SDA��������
    assign clk_div = (CLK_FREQ / I2C_FREQ) >> 2'd2;  //ģ������ʱ�ӵķ�Ƶϵ��
    
    //I2C��д�����źŹ̶�Ϊ�ߵ�ƽ, ֻ�õ���I2C��д����
    assign  i2c_rw_ctrl = 1'b0;
    
// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    //����I2C SCL���ı�Ƶ�ʵ�����ʱ����������I2C�Ĳ���
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            clk_dri <= 1'b1;
            clk_cnt <= 10'd0;
        end
        else if(clk_cnt == clk_div[8 : 1] - 9'd1)   //��Ƶϵ��/2 - 1
        begin
            clk_cnt <= 10'd0;
            clk_dri <= ~clk_dri;
        end
        else 
        begin
            clk_cnt <= clk_cnt + 10'd1;
            clk_dri <= clk_dri;
        end
    end
    
    //(����ʽ״̬��)ͬ��ʱ������״̬ת��
    always @(posedge clk_dri or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cur_state <= S_IDLE;
        end
        else 
        begin
            cur_state <= nxt_state;
        end
    end
    
    //����߼��ж�״̬ת������
    always @(*)
    begin
        case(cur_state)
                        //����״̬
            S_IDLE:
                begin
                    if(i2c_exec)
                    begin 
                        nxt_state = S_SLADDR;
                    end
                    else
                    begin
                        nxt_state = S_IDLE;
                    end
                end
                        //����������ַ
            S_SLADDR:
                begin
                    if(s_done)            //��ǰ״ִ̬�����
                    begin
                        if(bit_ctrl)      //�ж���16λ����8λ�ֵ�ַ
                        begin
                            nxt_state = S_ADDR16;
                        end
                        else
                        begin
                            nxt_state = S_ADDR8;
                        end
                    end
                    else 
                    begin
                        nxt_state = S_SLADDR;
                    end
                end
                        //����16λ�ֵ�ַ
            S_ADDR16:
                begin
                    if(s_done)
                    begin
                        nxt_state = S_ADDR8;
                    end
                    else
                    begin
                        nxt_state = S_ADDR16;
                    end
                end
                        //����8λ�ֵ�ַ
            S_ADDR8:
                begin
                    if(s_done)
                    begin
                        if(!wr_flag)     //��д��־Ϊ��, ��д����
                        begin
                            nxt_state = S_WR_DATA;
                        end
                        else             //��д��־Ϊ��, �������
                        begin
                            nxt_state = S_RD_ADDR;
                        end
                    end
                    else
                    begin
                        nxt_state = S_ADDR8;
                    end
                end
                        //д����(8 bit)
            S_WR_DATA:
                begin
                    if(s_done)
                    begin
                        nxt_state = S_STOP;
                    end
                    else
                    begin
                        nxt_state = S_WR_DATA;
                    end
                end
                        //����������ַ��
            S_RD_ADDR:
                begin
                    if(s_done)
                    begin
                        nxt_state = S_RD_DATA;
                    end
                    else
                    begin
                        nxt_state = S_RD_ADDR;
                    end
                end
                        //������(8 bit)
            S_RD_DATA:
                begin
                    if(s_done)
                    begin
                        nxt_state = S_STOP;
                    end
                    else
                    begin
                        nxt_state = S_RD_DATA;
                    end
                end
                        //����I2C����
            S_STOP:
                begin
                    if(s_done)
                    begin
                        nxt_state = S_IDLE;
                    end
                    else
                    begin
                        nxt_state = S_STOP;
                    end
                end
                
            default:
                begin
                    nxt_state = S_IDLE;
                end
        endcase
    end
    
    //ʱ���·����״̬���
    always @(posedge clk_dri or negedge rst_n)
    begin
        if(!rst_n)
        begin
            scl         <=  1'b1; 
            sda_out     <=  1'b1;
            sda_en      <=  1'b1;
            i2c_done    <=  1'b0;
            s_done      <=  1'b0;
            wr_flag     <=  1'b0;
            cnt         <=  7'd0;
            rd_data     <=  8'd0;
            i2c_rd_data <=  8'd0;
            wr_data_t   <=  8'd0;
            addr_t      <= 16'd0;
        end
        else
        begin
            s_done <= 1'b0;
            cnt    <= cnt + 7'd1;
            case(cur_state)
                            //����״̬
                S_IDLE:
                    begin
                        scl         <= 1'b1;
                        sda_out     <= 1'b1;
                        sda_en      <= 1'b1;
                        i2c_done    <= 1'b0;
                        cnt         <= 7'd0;
                        if(i2c_exec)        //I2C����ִ��
                        begin
                            wr_flag     <= i2c_rw_ctrl;
                            addr_t      <= i2c_addr;
                            wr_data_t   <= i2c_wr_data;
                        end
                        else 
                        begin
                            wr_flag     <= wr_flag;
                            addr_t      <= addr_t;
                            wr_data_t   <= wr_data_t;
                        end
                    end
                            //����������ַ
                S_SLADDR:
                    begin
                        case(cnt)
                            7'd1 : sda_out <= 1'b0;             //��ʼI2C
                            7'd3 : scl <= 1'b0;
                            7'd4 : sda_out <= SLAVE_ADDR[6];    //����������ַ
                            7'd5 : scl <= 1'b1;
                            7'd7 : scl <= 1'b0;
                            7'd8 : sda_out <= SLAVE_ADDR[5];
                            7'd9 : scl <= 1'b1;
                            7'd11: scl <= 1'b0;
                            7'd12: sda_out <= SLAVE_ADDR[4];
                            7'd13: scl <= 1'b1;
                            7'd15: scl <= 1'b0;
                            7'd16: sda_out <= SLAVE_ADDR[3];
                            7'd17: scl <= 1'b1;
                            7'd19: scl <= 1'b0;
                            7'd20: sda_out <= SLAVE_ADDR[2];
                            7'd21: scl <= 1'b1;
                            7'd23: scl <= 1'b0;
                            7'd24: sda_out <= SLAVE_ADDR[1];
                            7'd25: scl <= 1'b1;
                            7'd27: scl <= 1'b0;
                            7'd28: sda_out <= SLAVE_ADDR[0];
                            7'd29: scl <= 1'b1;
                            7'd31: scl <= 1'b0;
                            7'd32: sda_out <= 1'b0;             //���Ͷ�д��־λ, ��(1)/д(0)
                            7'd33: scl <= 1'b1;
                            7'd35: scl <= 1'b0;
                            7'd36:                              //�ӻ�Ӧ��
                                begin
                                    sda_en  <= 1'b0;
                                    sda_out <= 1'b1;
                                end
                            7'd37: scl <= 1'b1;
                            7'd38: s_done <= 1'b1;              //��ǰ״ִ̬�����
                            7'd39: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //ʱ�����ڼ���������
                                end
                            default: ; 
                        endcase
                    end
                            //����16λ�ֵ�ַ
                S_ADDR16:
                    begin
                        case(cnt)
                            7'd0 :                              //�����ֵ�ַ
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= addr_t[15];
                                end
                            7'd1 : scl <= 1'b1;
                            7'd3 : scl <= 1'b0;
                            7'd4 : sda_out <= addr_t[14];
                            7'd5 : scl <= 1'b1;
                            7'd7 : scl <= 1'b0;
                            7'd8 : sda_out <= addr_t[13];
                            7'd9 : scl <= 1'b1;
                            7'd11: scl <= 1'b0;
                            7'd12: sda_out <= addr_t[12];
                            7'd13: scl <= 1'b1;
                            7'd15: scl <= 1'b0;
                            7'd16: sda_out <= addr_t[11];
                            7'd17: scl <= 1'b1;
                            7'd19: scl <= 1'b0;
                            7'd20: sda_out <= addr_t[10];
                            7'd21: scl <= 1'b1;
                            7'd23: scl <= 1'b0;
                            7'd24: sda_out <= addr_t[9];
                            7'd25: scl <= 1'b1;
                            7'd27: scl <= 1'b0;
                            7'd28: sda_out <= addr_t[8];
                            7'd29: scl <= 1'b1;
                            7'd31: scl <= 1'b0;
                            7'd32:                              //�ӻ�Ӧ��
                                begin
                                    sda_en  <= 1'b0;
                                    sda_out <= 1'b1;
                                end
                            7'd33: scl <= 1'b1;
                            7'd34: s_done <= 1'b1;              //��ǰ״ִ̬�����
                            7'd35: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //ʱ�����ڼ���������
                                end
                            default: ; 
                        endcase
                    end
                            //����8λ�ֵ�ַ
                S_ADDR8:
                    begin
                        case(cnt)
                            7'd0 :                              //�����ֵ�ַ
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= addr_t[7];
                                end
                            7'd1 : scl <= 1'b1;
                            7'd3 : scl <= 1'b0;
                            7'd4 : sda_out <= addr_t[6];
                            7'd5 : scl <= 1'b1;
                            7'd7 : scl <= 1'b0;
                            7'd8 : sda_out <= addr_t[5];
                            7'd9 : scl <= 1'b1;
                            7'd11: scl <= 1'b0;
                            7'd12: sda_out <= addr_t[4];
                            7'd13: scl <= 1'b1;
                            7'd15: scl <= 1'b0;
                            7'd16: sda_out <= addr_t[3];
                            7'd17: scl <= 1'b1;
                            7'd19: scl <= 1'b0;
                            7'd20: sda_out <= addr_t[2];
                            7'd21: scl <= 1'b1;
                            7'd23: scl <= 1'b0;
                            7'd24: sda_out <= addr_t[1];
                            7'd25: scl <= 1'b1;
                            7'd27: scl <= 1'b0;
                            7'd28: sda_out <= addr_t[0];
                            7'd29: scl <= 1'b1;
                            7'd31: scl <= 1'b0;
                            7'd32:                              //�ӻ�Ӧ��
                                begin
                                    sda_en  <= 1'b0;
                                    sda_out <= 1'b1;
                                end
                            7'd33: scl <= 1'b1;
                            7'd34: s_done <= 1'b1;              //��ǰ״ִ̬�����
                            7'd35: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //ʱ�����ڼ���������
                                end
                            default: ; 
                        endcase
                    end
                            //д����(8 bit)
                S_WR_DATA:
                    begin
                        case(cnt)
                            7'd0 :                              //I2Cд8λ����
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= wr_data_t[7];
                                end
                            7'd1 : scl <= 1'b1;
                            7'd3 : scl <= 1'b0;
                            7'd4 : sda_out <= wr_data_t[6];
                            7'd5 : scl <= 1'b1;
                            7'd7 : scl <= 1'b0;
                            7'd8 : sda_out <= wr_data_t[5];
                            7'd9 : scl <= 1'b1;
                            7'd11: scl <= 1'b0;
                            7'd12: sda_out <= wr_data_t[4];
                            7'd13: scl <= 1'b1;
                            7'd15: scl <= 1'b0;
                            7'd16: sda_out <= wr_data_t[3];
                            7'd17: scl <= 1'b1;
                            7'd19: scl <= 1'b0;
                            7'd20: sda_out <= wr_data_t[2];
                            7'd21: scl <= 1'b1;
                            7'd23: scl <= 1'b0;
                            7'd24: sda_out <= wr_data_t[1];
                            7'd25: scl <= 1'b1;
                            7'd27: scl <= 1'b0;
                            7'd28: sda_out <= wr_data_t[0];
                            7'd29: scl <= 1'b1;
                            7'd31: scl <= 1'b0;
                            7'd32:                              //�ӻ�Ӧ��
                                begin
                                    sda_en  <= 1'b0;
                                    sda_out <= 1'b1;
                                end
                            7'd33: scl <= 1'b1;
                            7'd34: s_done <= 1'b1;              //��ǰ״ִ̬�����
                            7'd35: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //ʱ�����ڼ���������
                                end
                            default: ; 
                        endcase
                    end
                            //����������ַ��
                S_RD_ADDR:
                    begin
                        case(cnt)
                            7'd0 :
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= 1'b1;
                                end
                            7'd1 : scl <= 1'b1;
                            7'd2 : sda_out <= 1'b0;             //���·��Ϳ�ʼ�ź�
                            7'd3 : scl <= 1'b0;
                            7'd4 : sda_out <= SLAVE_ADDR[6];    //����������ַ
                            7'd5 : scl <= 1'b1;
                            7'd7 : scl <= 1'b0;
                            7'd8 : sda_out <= SLAVE_ADDR[5];
                            7'd9 : scl <= 1'b1;
                            7'd11: scl <= 1'b0;
                            7'd12: sda_out <= SLAVE_ADDR[4];
                            7'd13: scl <= 1'b1;
                            7'd15: scl <= 1'b0;
                            7'd16: sda_out <= SLAVE_ADDR[3];
                            7'd17: scl <= 1'b1;
                            7'd19: scl <= 1'b0;
                            7'd20: sda_out <= SLAVE_ADDR[2];
                            7'd21: scl <= 1'b1;
                            7'd23: scl <= 1'b0;
                            7'd24: sda_out <= SLAVE_ADDR[1];
                            7'd25: scl <= 1'b1;
                            7'd27: scl <= 1'b0;
                            7'd28: sda_out <= SLAVE_ADDR[0];
                            7'd29: scl <= 1'b1;
                            7'd31: scl <= 1'b0;
                            7'd32: sda_out <= 1'b1;             //���Ͷ�д��־λ, ��(1)/д(0)
                            7'd33: scl <= 1'b1;
                            7'd35: scl <= 1'b0;
                            7'd36:                              //�ӻ�Ӧ��
                                begin
                                    sda_en  <= 1'b0;
                                    sda_out <= 1'b1;
                                end
                            7'd37: scl <= 1'b1;
                            7'd38: s_done <= 1'b1;              //��ǰ״ִ̬�����
                            7'd39: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //ʱ�����ڼ���������
                                end
                            default: ; 
                        endcase
                    end
                            //������(8 bit)
                S_RD_DATA:
                    begin
                        case(cnt)
                            7'd0 : sda_en <= 1'b0;              //��SDA��������Ϊ����
                            7'd1 : 
                                begin
                                    rd_data[7] <= sda_in;       //��ȡ�ӻ�����
                                    scl <= 1'b1;
                                end
                            7'd3 : scl <= 1'b0;
                            7'd5 : 
                                begin
                                    rd_data[6] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd7 : scl <= 1'b0;
                            7'd9 : 
                                begin
                                    rd_data[5] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd11: scl <= 1'b0;
                            7'd13: 
                                begin
                                    rd_data[4] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd15: scl <= 1'b0;
                            7'd17: 
                                begin
                                    rd_data[3] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd19: scl <= 1'b0;
                            7'd21: 
                                begin
                                    rd_data[2] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd23: scl <= 1'b0;
                            7'd25: 
                                begin
                                    rd_data[1] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd27: scl <= 1'b0;
                            7'd29: 
                                begin
                                    rd_data[0] <= sda_in;
                                    scl <= 1'b1;
                                end
                            7'd31: scl <= 1'b0;
                            7'd32:                              //������Ӧ��
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= 1'b1;
                                end
                            7'd33: scl <= 1'b0;
                            7'd34: s_done <= 1'b1;              //��ǰ״ִ̬�����
                            7'd35: 
                                begin
                                    scl <= 1'b0;
                                    cnt <= 7'd0;                //ʱ�����ڼ���������
                                    i2c_rd_data <= rd_data;
                                end
                            default: ;
                        endcase
                    end
                            //����I2C����
                S_STOP:
                    begin
                        case(cnt)
                            7'd0 : 
                                begin
                                    sda_en  <= 1'b1;
                                    sda_out <= 1'b0;
                                end
                            7'd1 : scl <= 1'b1;
                            7'd3 : sda_out <= 1'b1;             //���ͽ����ź�
                            7'd15: s_done <= 1'b1;              //��ǰ״ִ̬�����
                            7'd16: 
                                begin
                                    cnt <= 7'd0;                //ʱ�����ڼ���������
                                    i2c_done <= 1'b1;           //I2Cһ�β������
                                end
                            default: ;
                        endcase
                    end

                default:    ;
                    // begin
                        // ;
                    // end
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