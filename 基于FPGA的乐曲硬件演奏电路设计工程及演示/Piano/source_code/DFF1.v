module DFF1(CLK,Q);
  output Q;
  input CLK;
  reg Q;
  always@(posedge CLK)
  Q <=~Q;
endmodule  