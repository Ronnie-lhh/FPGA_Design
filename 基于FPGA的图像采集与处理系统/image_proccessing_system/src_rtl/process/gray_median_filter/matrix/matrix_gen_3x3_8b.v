// ********************************************************************************* 
// �ļ���: matrix_gen_3x3_8b.v
// ������: ���Ժ�
// ��������: 2021.3.25
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: matrix_gen_3x3_8b
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)3X3�ҶȾ�������ģ��
//            2)��ԻҶ�ͼ������, 8bit
//             3)ʹ��2��˫�˿�RAM(512 x 8)
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
module matrix_gen_3x3_8b
(
    // clock & reset
    input 			    clk,	                //ʱ���ź�
    input               rst_n,                  //��λ�ź�, �͵�ƽ��Ч

    // input signal
    input               ycbcr_vs,               //vsync�ź�
    input               ycbcr_hs,               //hsync�ź�
    input               ycbcr_de,               //data enable�ź�
    input      [ 7 : 0] ycbcr_y,                //�Ҷ�����
    
    // output signal
    output              matrix_vs,              //vsync�ź�
    output              matrix_hs,              //hsync�ź�
    output              matrix_de,              //data enable�ź�
    output reg [ 7 : 0] matrix_p11,             //��������(1,1)
    output reg [ 7 : 0] matrix_p12,             //��������(1,2)
    output reg [ 7 : 0] matrix_p13,             //��������(1,3)
    output reg [ 7 : 0] matrix_p21,             //��������(2,1)
    output reg [ 7 : 0] matrix_p22,             //��������(2,2)
    output reg [ 7 : 0] matrix_p23,             //��������(2,3)
    output reg [ 7 : 0] matrix_p31,             //��������(3,1)
    output reg [ 7 : 0] matrix_p32,             //��������(3,2)
    output reg [ 7 : 0] matrix_p33              //��������(3,3)
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------

   
// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    reg        [ 7 : 0] row3_data;              //3x3�����3������
    reg        [ 1 : 0] ycbcr_vs_d;             //��ͬ���źŵĶ����Ĵ�
    reg        [ 1 : 0] ycbcr_hs_d;             //��ͬ���źŵĶ����Ĵ�
    reg        [ 1 : 0] ycbcr_de_d;             //������Чʹ���źŵĶ����Ĵ�
    
    wire       [ 7 : 0] row1_data;              //3x3�����1������
    wire       [ 7 : 0] row2_data;              //3x3�����2������
    wire                ycbcr_hs_d0;            //��ͬ���źŵ�һ���Ĵ�
    wire                ycbcr_de_d0;            //������Чʹ���źŵ�һ���Ĵ�
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// ---------------------------------------------------------------------------------    
    // �����źŵ���ʱ�Ĵ�
    assign  ycbcr_hs_d0 = ycbcr_hs_d[0];
    assign  ycbcr_de_d0 = ycbcr_de_d[0];
    assign  matrix_vs   = ycbcr_vs_d[1];
    assign  matrix_hs   = ycbcr_hs_d[1];
    assign  matrix_de   = ycbcr_de_d[1];

// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    // ��ǰ���ݷ��ڵ�3��
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            row3_data <= 8'd0;
        end
        else if(ycbcr_de)
        begin
            row3_data <= ycbcr_y;
        end
        else
        begin
            row3_data <= row3_data;
        end
    end    
    
    // �������ź��ӳ�2��, ����ͬ��������
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            ycbcr_vs_d <= 2'd0;
            ycbcr_hs_d <= 2'd0;
            ycbcr_de_d <= 2'd0;
        end
        else
        begin
            ycbcr_vs_d <= {ycbcr_vs_d[0], ycbcr_vs};
            ycbcr_hs_d <= {ycbcr_hs_d[0], ycbcr_hs};
            ycbcr_de_d <= {ycbcr_de_d[0], ycbcr_de};
        end
    end    
    
    // ��ͬ���������Ŀ����ź���, ���3x3�ҶȾ���
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            {matrix_p11, matrix_p12, matrix_p13} <= 24'd0;
            {matrix_p21, matrix_p22, matrix_p23} <= 24'd0;
            {matrix_p31, matrix_p32, matrix_p33} <= 24'd0;
        end
        else if(ycbcr_hs_d0)
        begin
            if(ycbcr_de_d0)
            begin
                {matrix_p11, matrix_p12, matrix_p13} <= {matrix_p12, matrix_p13, row1_data};
                {matrix_p21, matrix_p22, matrix_p23} <= {matrix_p22, matrix_p23, row2_data};
                {matrix_p31, matrix_p32, matrix_p33} <= {matrix_p32, matrix_p33, row3_data};
            end
            else
            begin
                {matrix_p11, matrix_p12, matrix_p13} <= {matrix_p11, matrix_p12, matrix_p13};
                {matrix_p21, matrix_p22, matrix_p23} <= {matrix_p21, matrix_p22, matrix_p23};
                {matrix_p31, matrix_p32, matrix_p33} <= {matrix_p31, matrix_p32, matrix_p33};
            end
        end
        else
        begin
            {matrix_p11, matrix_p12, matrix_p13} <= 24'd0;
            {matrix_p21, matrix_p22, matrix_p23} <= 24'd0;
            {matrix_p31, matrix_p32, matrix_p33} <= 24'd0;
        end
    end

// ---------------------------------------------------------------------------------
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------
    // ʵ������λ�洢��˫�˿�RAM����ģ��
    row_shift_ram_ctrl      U_row_shift_ram_ctrl
    (
        // clock & reset
        .clk                        (clk),
        .rst_n                      (rst_n),
    
        // input signal 
        .ycbcr_hs                   (ycbcr_hs),
        .ycbcr_de                   (ycbcr_de),
        .ycbcr_y                    (ycbcr_y),
    
        // output signal    
        .pre_row0                   (row2_data),
        .pre_row1                   (row1_data)
    );

// ---------------------------------------------------------------------------------
// ������ Called Tasks
// ---------------------------------------------------------------------------------

	
// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------

    
endmodule