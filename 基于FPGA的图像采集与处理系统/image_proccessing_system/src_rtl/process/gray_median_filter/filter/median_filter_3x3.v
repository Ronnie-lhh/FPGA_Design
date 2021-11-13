// ********************************************************************************* 
// �ļ���: median_filter_3x3.v   
// ������: ���Ժ�
// ��������: 2021.3.25
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: median_filter_3x3
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)3x3�������ֵ�˲���
//            2)��ֵ�˲��㷨����:
//**********************************************************************************
//              FPGA Median Fliter Sort Order
//      Pixel  --  Sort1 -- Sort2  --  Sort3
//  [ P1 P2 P3 ]  [ Max1     Mid1      Min1 ]
//  [ P4 P5 P6 ]  [ Max2     Mid2      Min2 ]  [ Max_min Mid_mid Min_max ]  Mid_result
//  [ P7 P8 P9 ]  [ Max3     Mid3      Min3 ]
//**********************************************************************************
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
module median_filter_3x3
(
    // clock & reset
    input 			    clk,	                //ʱ���ź�
    input               rst_n,                  //��λ�ź�, �͵�ƽ��Ч

    // input signal
    input               matrix_vs,              //vsync�ź�
    input               matrix_hs,              //hsync�ź�
    input               matrix_de,              //data enable�ź�
    input      [ 7 : 0] matrix_p11,             //�˲�ǰ�ľ�������(1,1)
    input      [ 7 : 0] matrix_p12,             //�˲�ǰ�ľ�������(1,2)
    input      [ 7 : 0] matrix_p13,             //�˲�ǰ�ľ�������(1,3)
    input      [ 7 : 0] matrix_p21,             //�˲�ǰ�ľ�������(2,1)
    input      [ 7 : 0] matrix_p22,             //�˲�ǰ�ľ�������(2,2)
    input      [ 7 : 0] matrix_p23,             //�˲�ǰ�ľ�������(2,3)
    input      [ 7 : 0] matrix_p31,             //�˲�ǰ�ľ�������(3,1)
    input      [ 7 : 0] matrix_p32,             //�˲�ǰ�ľ�������(3,2)
    input      [ 7 : 0] matrix_p33,             //�˲�ǰ�ľ�������(3,3)
    
    // output signal
    output              median_vs,              //vsync�ź�
    output              median_hs,              //hsync�ź�
    output              median_de,              //data enable�ź�
    output     [ 7 : 0] median_y                //�˲������ֵ��������
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------

   
// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    // �����źŵ������Ĵ�
    reg        [ 2 : 0] matrix_vs_d;
    reg        [ 2 : 0] matrix_hs_d;
    reg        [ 2 : 0] matrix_de_d;
    
    // ��һ������
    wire       [ 7 : 0] max_data1;              //�����һ�����������ֵ
    wire       [ 7 : 0] mid_data1;              //�����һ���������м�ֵ
    wire       [ 7 : 0] min_data1;              //�����һ����������Сֵ
    wire       [ 7 : 0] max_data2;              //����ڶ������������ֵ
    wire       [ 7 : 0] mid_data2;              //����ڶ����������м�ֵ
    wire       [ 7 : 0] min_data2;              //����ڶ�����������Сֵ
    wire       [ 7 : 0] max_data3;              //������������������ֵ
    wire       [ 7 : 0] mid_data3;              //����������������м�ֵ
    wire       [ 7 : 0] min_data3;              //�����������������Сֵ
    // �ڶ�������
    wire       [ 7 : 0] max_min_data;           //�����������ֵ�е���Сֵ
    wire       [ 7 : 0] mid_mid_data;           //���������м�ֵ�е��м�ֵ
    wire       [ 7 : 0] min_max_data;           //����������Сֵ�е����ֵ
    // ����������
    wire       [ 7 : 0] mid_result;             //�Եڶ�������Ľ����ȡ�м�ֵ
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// ---------------------------------------------------------------------------------    
    // �����ź��ӳ�3��
    assign  median_vs = matrix_vs_d[2];
    assign  median_hs = matrix_hs_d[2];
    assign  median_de = matrix_de_d[2];
    
    // �˲������ֵ���ػҶ�����
    assign  median_y = mid_result;

// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    // �������ź��ӳ�3��, ����ͬ�������� (����������Ҫ3��ʱ������)
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            matrix_vs_d <= 3'd0;
            matrix_hs_d <= 3'd0;
            matrix_de_d <= 3'd0;
        end
        else
        begin
            matrix_vs_d <= {matrix_vs_d[1 : 0], matrix_vs};
            matrix_hs_d <= {matrix_hs_d[1 : 0], matrix_hs};
            matrix_de_d <= {matrix_de_d[1 : 0], matrix_de};
        end
    end

// ---------------------------------------------------------------------------------
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------
    // ��һ������--ȡ�����һ�е����ֵ���м�ֵ����Сֵ
    // [ Max1     Mid1      Min1 ]
    sort3       U1_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (matrix_p11),
        .data2                      (matrix_p12),
        .data3                      (matrix_p13),

        // output signal
        .max_data                   (max_data1),
        .mid_data                   (mid_data1),
        .min_data                   (min_data1)
    );
    
    // ��һ������--ȡ����ڶ��е����ֵ���м�ֵ����Сֵ
    // [ Max2     Mid2      Min2 ]
    sort3       U2_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (matrix_p21),
        .data2                      (matrix_p22),
        .data3                      (matrix_p23),

        // output signal
        .max_data                   (max_data2),
        .mid_data                   (mid_data2),
        .min_data                   (min_data2)
    );
    
    // ��һ������--ȡ��������е����ֵ���м�ֵ����Сֵ
    // [ Max3     Mid3      Min3 ]
    sort3       U3_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (matrix_p31),
        .data2                      (matrix_p32),
        .data3                      (matrix_p33),

        // output signal
        .max_data                   (max_data3),
        .mid_data                   (mid_data3),
        .min_data                   (min_data3)
    );
    
    // �ڶ�������--ȡ�����������ֵ�е���Сֵ
    // [ Max_min
    sort3       U4_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (max_data1),
        .data2                      (max_data2),
        .data3                      (max_data3),

        // output signal
        .max_data                   (),
        .mid_data                   (),
        .min_data                   (max_min_data)
    );
    
    // �ڶ�������--ȡ���������м�ֵ�е��м�ֵ
    // Mid_mid
    sort3       U5_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (mid_data1),
        .data2                      (mid_data2),
        .data3                      (mid_data3),

        // output signal
        .max_data                   (),
        .mid_data                   (mid_mid_data),
        .min_data                   ()
    );
    
    // �ڶ�������--ȡ����������Сֵ�е����ֵ
    // Min_max ]
    sort3       U6_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (min_data1),
        .data2                      (min_data2),
        .data3                      (min_data3),

        // output signal
        .max_data                   (min_max_data),
        .mid_data                   (),
        .min_data                   ()
    );

    // ����������--�Եڶ�������Ľ����ȡ�м�ֵ
    sort3       U7_sort3
    (
        // clock & reset
        .clk	                    (clk),
        .rst_n                      (rst_n),

        // input signal
        .data1                      (max_min_data),
        .data2                      (mid_mid_data),
        .data3                      (min_max_data),

        // output signal
        .max_data                   (),
        .mid_data                   (mid_result),
        .min_data                   ()
    );
    
// ---------------------------------------------------------------------------------
// ������ Called Tasks
// ---------------------------------------------------------------------------------

	
// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------

    
endmodule