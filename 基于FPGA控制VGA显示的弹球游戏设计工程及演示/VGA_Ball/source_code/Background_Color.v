//背景颜色选择模块--键控产生背景颜色切换信号
module Background_Color(iCLK,iRST_n,key_num,oBackground_set);
	input iCLK, iRST_n;
	input [15:0]key_num;
	output [1:0]oBackground_set;
	
	reg [1:0]oBackground_set;
	
	always@(posedge iCLK or negedge iRST_n)
		begin
			if(!iRST_n) 
				oBackground_set<=2'b11;
			else if(key_num[3:0]==4'h4)		//按下按键S5后，切换到上一个背景颜色
				oBackground_set<=oBackground_set-1;
			else if(key_num[3:0]==4'h5)		//按下按键S6后，切换到下一个背景颜色
				oBackground_set<=oBackground_set+1;
			else
				oBackground_set<=oBackground_set;
		end

endmodule
		