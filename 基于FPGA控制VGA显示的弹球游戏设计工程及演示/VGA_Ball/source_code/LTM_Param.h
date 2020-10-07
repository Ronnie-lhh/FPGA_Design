//LTM_Param.h
//*************************************************************************
//parameter declarations  
//*************************************************************************
parameter H_LINE =800;							//行的总点数		
parameter V_LINE = 525;							//列的总点数		
parameter Hsync_Blank =140;					//					
parameter Hsync_Front_Porch =16;				//					
parameter Vertical_Back_Porch =33;			//				
parameter Vertical_Front_Porch =10;			//					
//*************************************************************************
// Horizontal Parameter
parameter H_TOTAL =H_LINE-1;     //total-1 行点数的最大值								799
parameter H_SYNC =96;      		//sync-1 行同步信号点数最大值						95
parameter H_START = 140;     		//sync+back-1-1-delay  行有效区域起始的点		140		
parameter H_END =780;      		//H_START+800 行有效区域结束的点					780
// Vertical Parameter
parameter V_TOTAL = V_LINE-1;    //total-1 列点数的最大值									524
parameter V_SYNC = 2;           	//sync-1 列同步信号点数最大值							2
parameter V_START =34;      	   //sync+back-1  pre 2 lines；列有效区域起始的点		34
parameter V_END=514;     		   //V_START+480  pre 2 lines；列有效区域结束的点		514

parameter X_START =Hsync_Blank;                   
parameter Y_START = Vertical_Back_Porch;

parameter Ball_X_Center =X_START-1+((H_LINE-Hsync_Blank-Hsync_Front_Porch)>>1);   				//screen center  x
parameter Ball_Y_Center=Y_START-1+((V_LINE-Vertical_Back_Porch-Vertical_Front_Porch)>>1);		//screen center  y
parameter Ball_X_Min = X_START-1;                    //screen left up x
parameter Ball_Y_Min=Y_START-1;                      //screen left up y
parameter Ball_X_Max=H_LINE-Hsync_Front_Porch-1;     //screen rigt down x
parameter Ball_Y_Max=V_LINE-Vertical_Front_Porch-1;  //screen rigt down y