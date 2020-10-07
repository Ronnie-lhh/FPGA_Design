//乐曲简谱码对应的分频预置数查表电路模块
module F_CODE(INX, DISPLAY_NUM, TO);
	input[3:0] INX;
	output[15:0] DISPLAY_NUM; //数码管显示数据：[15:12]数码管千位--“H”（低中高音标识符），[3:0]数码管个位--“CODE”（乐谱音符简码）
	output[10:0] TO;
	reg[10:0] TO;
	reg[11:0] CODE;
	reg[3:0] H;
	
	always @(INX)
	begin
	case (INX)
		0: begin TO<=11'H7FF; CODE<=0; H<=0; end
		1: begin TO<=11'H089; CODE<=1; H<=0; end
		2: begin TO<=11'H159; CODE<=2; H<=0; end
		3: begin TO<=11'H213; CODE<=3; H<=0; end
		4: begin TO<=11'H268; CODE<=4; H<=0; end
		5: begin TO<=11'H305; CODE<=5; H<=0; end
		6: begin TO<=11'H390; CODE<=6; H<=0; end
		7: begin TO<=11'H40C; CODE<=7; H<=0; end
		8: begin TO<=11'H444; CODE<=1; H<=1; end
		9: begin TO<=11'H4AD; CODE<=2; H<=1; end
		10: begin TO<=11'H50A; CODE<=3; H<=1; end
		11: begin TO<=11'H534; CODE<=4; H<=1; end
		12: begin TO<=11'H582; CODE<=5; H<=1; end
		13: begin TO<=11'H5C8; CODE<=6; H<=1; end
		14: begin TO<=11'H606; CODE<=7; H<=1; end
		15: begin TO<=11'H622; CODE<=1; H<=2; end
		default: begin TO<=11'H622; CODE<=1; H<=2; end
	endcase
	end 
	assign DISPLAY_NUM={H,CODE};
	
endmodule 