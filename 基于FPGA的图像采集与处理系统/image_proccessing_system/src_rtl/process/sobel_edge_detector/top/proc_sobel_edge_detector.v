// ********************************************************************************* 
// �ļ���: proc_sobel_edge_detector.v
// ������: ���Ժ�
// ��������: 2021.3.26
// ��ϵ��ʽ: 17hhliang3@stu.edu.cn
// --------------------------------------------------------------------------------- 
// ģ����: proc_sobel_edge_detector
// �����汾��: V0.0
// --------------------------------------------------------------------------------- 
// ����˵��: 1)ͼ�����㷨ģ��--����Sobel���ӵı�Ե���
//            2)Sobel��������:
//**********************************************************************************
//                   Sobel                     *         Pixel
//         Gx                     Gy        
//  [  -1  0  +1  ]        [  -1  -2  -1  ]        [  Z1   Z2   Z3  ]
//  [  -2  0  +2  ]        [   0   0   0  ]        [  Z4   Z5   Z6  ]
//  [  -1  0  +1  ]        [  +1  +2  +1  ]        [  Z7   Z8   Z9  ]
//  ��ⴹֱ����ı�Ե    ���ˮƽ����ı�Ե
//
//               Gx = (Z7 + 2Z8 + Z9) - (Z1 + 2Z2 + Z3)
//               Gy = (Z3 + 2Z6 + Z9) - (Z1 + 2Z4 + Z7)
//               G  = ��(Gx^2 + Gy^2)        //�ݶȴ�С
//               ��  = tan^(-1) (Gy / Gx)    //�ݶȷ���
//               ��G > ��ֵ, ���϶�Ϊ��Ե
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
module proc_sobel_edge_detector
#(
    // parameter passing
    parameter   SOBEL_THRESHOLD = 11'd250       //�Զ�Sobel��ֵ, ��ΧΪ[0, 255]
)
(
    // clock & reset
    input 			    clk,	                //ʱ���ź�
    input               rst_n,                  //��λ�ź�, �͵�ƽ��Ч

    // input signal
    // ͼ����ǰ�����ݽӿ�
    input               ycbcr_vs,               //vsync�ź�
    input               ycbcr_hs,               //hsync�ź�
    input               ycbcr_de,               //data enable�ź�
    input      [ 7 : 0] ycbcr_y,                //�Ҷ�����

    // output signal
    // ͼ���������ݽӿ�
    output              sobel_vs,               //vsync�ź�
    output              sobel_hs,               //hsync�ź�
    output              sobel_de,               //data enable�ź�
    output     [ 7 : 0] sobel_y                 //Sobel��Ե����ĻҶ�����
);

// ---------------------------------------------------------------------------------
// �ֲ����� Local Constant Parameters
// ---------------------------------------------------------------------------------

   
// ---------------------------------------------------------------------------------
// ģ���ڱ������� Module_Variables
// --------------------------------------------------------------------------------- 
    reg        [ 9 : 0] Gx_tmp1;                //��һ��ֵ
    reg        [ 9 : 0] Gx_tmp2;                //������ֵ
    reg        [ 9 : 0] Gx_data;                //y�����ƫ����
    reg        [ 9 : 0] Gy_tmp1;                //��һ��ֵ
    reg        [ 9 : 0] Gy_tmp2;                //������ֵ
    reg        [ 9 : 0] Gy_data;                //x�����ƫ����
    reg        [20 : 0] Gxy_square;             //Gx��Gy��ƽ����
    reg                 edge_flag;              //��Ե�����, ��Ե(1)/�Ǳ�Ե(0)
    
    reg        [ 3 : 0] matrix_vs_d;            //��ͬ���źŵ��ļ��Ĵ�
    reg        [ 3 : 0] matrix_hs_d;            //��ͬ���źŵ��ļ��Ĵ�
    reg        [ 3 : 0] matrix_de_d;            //������Чʹ���źŵ��ļ��Ĵ�
    
    wire       [10 : 0] sqrt_result;            //�������
    wire       [ 7 : 0] sobel_y_r;              //Sobel��Ե����ĻҶ�����Ԥ��
    
    wire                matrix_vs;              //vsync�ź�
    wire                matrix_hs;              //hsync�ź�
    wire                matrix_de;              //data enable�ź�
    wire       [ 7 : 0] matrix_p11;             //��������(1,1)
    wire       [ 7 : 0] matrix_p12;             //��������(1,2)
    wire       [ 7 : 0] matrix_p13;             //��������(1,3)
    wire       [ 7 : 0] matrix_p21;             //��������(2,1)
    wire       [ 7 : 0] matrix_p22;             //��������(2,2)
    wire       [ 7 : 0] matrix_p23;             //��������(2,3)
    wire       [ 7 : 0] matrix_p31;             //��������(3,1)
    wire       [ 7 : 0] matrix_p32;             //��������(3,2)
    wire       [ 7 : 0] matrix_p33;             //��������(3,3)
    
// ---------------------------------------------------------------------------------
// ���������� Continuous Assignments
// ---------------------------------------------------------------------------------    
    // �����ź��ӳ�4��ʱ������
    assign  sobel_vs = matrix_vs_d[3];
    assign  sobel_hs = matrix_hs_d[3];
    assign  sobel_de = matrix_de_d[3];
    
    // Sobel��Ե����ĻҶ�����Ԥ��, ��Ե(��ɫ)/�Ǳ�Ե(��ɫ)
    assign  sobel_y_r = edge_flag? 8'h00 : 8'hff;
    
    // Sobel��Ե����ĻҶ�����
    assign  sobel_y = sobel_hs? sobel_y_r : 8'd0;

// ---------------------------------------------------------------------------------
// ��Ϊ���� Clocked Assignments
// ---------------------------------------------------------------------------------
    // Step1 ����Gx, Gy
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            Gx_tmp1 <= 10'd0;
            Gx_tmp2 <= 10'd0;
            Gx_data <= 10'd0;
            
            Gy_tmp1 <= 10'd0;
            Gy_tmp2 <= 10'd0;
            Gy_data <= 10'd0;
        end
        else
        begin
            Gx_tmp1 <= {2'b00, matrix_p11} + {1'b0, matrix_p12, 1'b0} + {2'b00, matrix_p13};
            Gx_tmp2 <= {2'b00, matrix_p31} + {1'b0, matrix_p32, 1'b0} + {2'b00, matrix_p33};
            Gx_data <= (Gx_tmp1 >= Gx_tmp2)? (Gx_tmp1 - Gx_tmp2) : (Gx_tmp2 - Gx_tmp1);
            
            Gy_tmp1 <= {2'b00, matrix_p11} + {1'b0, matrix_p21, 1'b0} + {2'b00, matrix_p31};
            Gy_tmp2 <= {2'b00, matrix_p13} + {1'b0, matrix_p23, 1'b0} + {2'b00, matrix_p33};
            Gy_data <= (Gy_tmp1 >= Gy_tmp2)? (Gy_tmp1 - Gy_tmp2) : (Gy_tmp2 - Gy_tmp1);
        end
    end
    
    /*
    // Step1 ����Gx, Gy
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            Gx_tmp1 <= 10'd0;
            Gx_tmp2 <= 10'd0;
            Gx_data <= 10'd0;
            
            Gy_tmp1 <= 10'd0;
            Gy_tmp2 <= 10'd0;
            Gy_data <= 10'd0;
        end
        else
        begin
            Gx_tmp1 <= matrix_p11 + (matrix_p12 << 1) + matrix_p13;
            Gx_tmp2 <= matrix_p31 + (matrix_p32 << 1) + matrix_p33;
            Gx_data <= (Gx_tmp1 >= Gx_tmp2)? (Gx_tmp1 - Gx_tmp2) : (Gx_tmp2 - Gx_tmp1);
            
            Gy_tmp1 <= matrix_p11 + (matrix_p21 << 1) + matrix_p31;
            Gy_tmp2 <= matrix_p13 + (matrix_p23 << 1) + matrix_p33;
            Gy_data <= (Gy_tmp1 >= Gy_tmp2)? (Gy_tmp1 - Gy_tmp2) : (Gy_tmp2 - Gy_tmp1);
        end
    end
    */
    
    // Step2 ����Gx^2 + Gy^2
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            Gxy_square <= 21'd0;
        end
        else
        begin
            Gxy_square <= Gx_data * Gx_data + Gy_data + Gy_data;
        end
    end
    
    // Step3 ��ƽ��, ʹ��Xilinx��ƽ����IP������
    
    // Step4 �����������Ԥ����ֵ�Ƚ�
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            edge_flag <= 1'b0;
        end
        else if(sqrt_result >= SOBEL_THRESHOLD)     //���ڵ���Ԥ����ֵ, ��⵽��Ե
        begin
            edge_flag <= 1'b1;
        end
        else                                        //С��Ԥ����ֵ, �Ǳ�Ե
        begin
            edge_flag <= 1'b0;
        end
    end
    
    // �����źŴ�4��, ����ͬ��������
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            matrix_vs_d <= 4'd0;
            matrix_hs_d <= 4'd0;
            matrix_de_d <= 4'd0;
        end
        else
        begin
            matrix_vs_d <= {matrix_vs_d[2 : 0], matrix_vs};
            matrix_hs_d <= {matrix_hs_d[2 : 0], matrix_hs};
            matrix_de_d <= {matrix_de_d[2 : 0], matrix_de};
        end
    end

// ---------------------------------------------------------------------------------
// �ṹ������ Moudle Instantiate
// ---------------------------------------------------------------------------------
    // 3X3�ҶȾ�������ģ��
    matrix_gen_3x3_8b       U2_matrix_gen_3x3_8b
    (
        // clock & reset
        .clk	                        (clk),
        .rst_n                          (rst_n),
        
        // input signal
        .ycbcr_vs                       (ycbcr_vs),
        .ycbcr_hs                       (ycbcr_hs),
        .ycbcr_de                       (ycbcr_de),
        .ycbcr_y                        (ycbcr_y),

        // output signal
        .matrix_vs                      (matrix_vs),
        .matrix_hs                      (matrix_hs),
        .matrix_de                      (matrix_de),
        .matrix_p11                     (matrix_p11),
        .matrix_p12                     (matrix_p12),
        .matrix_p13                     (matrix_p13),
        .matrix_p21                     (matrix_p21),
        .matrix_p22                     (matrix_p22),
        .matrix_p23                     (matrix_p23),
        .matrix_p31                     (matrix_p31),
        .matrix_p32                     (matrix_p32),
        .matrix_p33                     (matrix_p33)
    );
    
    // ƽ����IP������
    sqrt_ip     U_sqrt_ip
    (
        // clock & reset
        .clk                            (clk),
        
        .x_in                           (Gxy_square),
        .x_out                          (sqrt_result)
    );
    
// ---------------------------------------------------------------------------------
// ������ Called Tasks
// ---------------------------------------------------------------------------------

	
// ---------------------------------------------------------------------------------
// �������� Called Functions
// ---------------------------------------------------------------------------------

    
endmodule