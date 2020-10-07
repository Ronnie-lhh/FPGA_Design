module sigkeyscan(
			input clk,	//外部输入25MHz时钟信号
			input rst_n,	//外部输入复位信号，低电平有效
			input [3:0]key_v,	//4个列按键输入，未按下为高电平，按下后为低电平
			output [3:0]keyv_value		//列按键按下键值，高电平有效
    		);

//-------------------------------------
//按键抖动判断逻辑
wire key;	//所有按键值相与的结果，用于按键触发判断
reg[3:0] keyr;  //按键值key的缓存寄存器

assign key = key_v[0] & key_v[1] & key_v[2] & key_v[3];

always @(posedge clk or negedge rst_n)
    if (!rst_n) keyr <= 4'b1111;
    else keyr <= {keyr[2:0],key};

wire key_neg = ~keyr[2] & keyr[3];	//有按键被按下	
wire key_pos = keyr[2] & ~keyr[3];	//有按键被释放

//-------------------------------------
//定时计数逻辑，用于对按键的消抖判断
reg[19:0]  cnt;	

	//按键消抖定时计数器
always @ (posedge clk or negedge rst_n)
   if (!rst_n) cnt <= 20'd0;	
	else if(key_pos || key_neg) cnt <= 20'd0;
	else if(cnt < 20'd999_999) cnt <= cnt + 1'b1;
	else cnt <= 20'd0;
  
reg[3:0] key_value[1:0];

	//定时采集按键值
always @(posedge clk or negedge rst_n)
    if (!rst_n) begin
		key_value[0] <= 4'b1111;
		key_value[1] <= 4'b1111;
	end
	else begin 
		key_value[1] <= key_value[0];		
		if(cnt == 20'd999_999) key_value[0] <= key_v;	//定时键值采集
		else ;	
	end

assign keyv_value = key_value[1] & ~key_value[0];		//消抖后按键值变化标志位

  
endmodule

