//数控分频模块——按预置数发声演奏
module SPKER(CLK, RST, TN, SPKS);
	input CLK;
	input RST;
	input[10:0] TN;
	output SPKS;
	reg SPKS;
	reg[10:0] CNT11;

	always @(posedge CLK or negedge RST)
	begin
	// CNT11B_LOAD：11位可预置计数器
		if (!RST) CNT11<=0;
		else if (CNT11==11'h7FF)
		begin
			CNT11=TN;
			SPKS<=1'b1;
		end
		else
		begin
			CNT11=CNT11+1;
			SPKS<=1'b0;
		end
	end

endmodule 
	