//分频电路模块——4Hz
module FDIV(CLK, PM, RST_N);
	input CLK;
	input	RST_N;
	output PM;
	reg[8:0] Q1;
	reg FULL;
	wire RST;
	
	always @(posedge CLK or posedge RST	or negedge RST_N)
	begin  
		if (!RST_N)	
		begin 
			Q1<=0; FULL<=0;
		end 
		else if (RST) 
		begin
			Q1<=0; FULL<=1;
		end
		else begin 
			Q1<=Q1+1; FULL<=0;
		end 
	end 
	assign RST=(Q1==499);
	assign PM=FULL;
	
endmodule 