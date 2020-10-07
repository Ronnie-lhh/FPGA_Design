//VGA时序控制模块--完成时序扫描，输出LCD显示的RGB数值及水平方向和垂直方向的同步信号
module vga_controller(
			input iCLK,					//PLL输出25MHz时钟
			input iRST_n,				//复位信号，低电平有效
			input iR,
			input iG,
			input iB,
			output oVGA_R,
			output oVGA_G,
			output oVGA_B,
			output reg oVGA_HS,  	//行同步
			output reg oVGA_VS, 		//场同步
			output reg [10:0]oH_cnt,//行计数器
			output reg [9:0]oV_cnt 	//列计数器
			);

	//-----------------------------------------------------------
	`define VGA_640_480

	//-----------------------------------------------------------
	`ifdef VGA_640_480
		//VGA Timing 640*480 & 25MHz & 60Hz
		parameter VGA_HTT = 12'd800-12'd1;		//Hor Total Time
		parameter VGA_HST = 12'd96;				//Hor Sync  Time
		parameter VGA_HBP = 12'd48;//+12'd16;	//Hor Back Porch
		parameter VGA_HVT = 12'd640;				//Hor Valid Time
		parameter VGA_HFP = 12'd16;				//Hor Front Porch

		parameter VGA_VTT = 12'd525-12'd1;		//Ver Total Time
		parameter VGA_VST = 12'd2;					//Ver Sync Time
		parameter VGA_VBP = 12'd33;//-12'd4;	//Ver Back Porch
		parameter VGA_VVT = 12'd480;				//Ver Valid Time
		parameter VGA_VFP = 12'd10;				//Ver Front Porch
	`endif
		
	always @(posedge iCLK or negedge iRST_n)
		if(!iRST_n) 
			oH_cnt <= 12'd0;
		else if(oH_cnt >= VGA_HTT) 
			oH_cnt <= 12'd0;
		else 
			oH_cnt <= oH_cnt+1'b1;

	always @(posedge iCLK or negedge iRST_n)
		if(!iRST_n) 
			oV_cnt <= 12'd0;
		else if(oH_cnt == VGA_HTT) 
			begin
				if(oV_cnt >= VGA_VTT) oV_cnt <= 12'd0;
				else oV_cnt <= oV_cnt+1'b1;
			end
		else ;
			
	//-----------------------------------------------------------
	//行、场同步信号生成
	always @(posedge iCLK or negedge iRST_n)
		if(!iRST_n) 
			oVGA_HS <= 1'b0;
		else if(oH_cnt < VGA_HST) 
			oVGA_HS <= 1'b1;
		else 
			oVGA_HS <= 1'b0;
		
	always @(posedge iCLK or negedge iRST_n)
		if(!iRST_n) 
			oVGA_VS <= 1'b0;
		else if(oV_cnt < VGA_VST) 
			oVGA_VS <= 1'b1;
		else 
			oVGA_VS <= 1'b0;	
		
	//-----------------------------------------------------------	
	//显示有效区域标志信号生成
	reg vga_valid;	//显示区域内，该信号高电平

	always @(posedge iCLK or negedge iRST_n)
		if(!iRST_n) 
			vga_valid <= 1'b0;
		else if((oH_cnt >= (VGA_HST+VGA_HBP)) && (oH_cnt < (VGA_HST+VGA_HBP+VGA_HVT))
					&& (oV_cnt >= (VGA_VST+VGA_VBP)) && (oV_cnt < (VGA_VST+VGA_VBP+VGA_VVT)))
			vga_valid <= 1'b1;
		else 
			vga_valid <= 1'b0;
		
	assign oVGA_R = vga_valid ? iR:1'b0;
	assign oVGA_G = vga_valid ? iG:1'b0;	
	assign oVGA_B = vga_valid ? iB:1'b0;	
	
endmodule

		 
	   
	  