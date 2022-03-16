//============================================================================//
// AIC2021 Project1 - TPU Design                                              //
// file: top.v                                                                //
// description: Top module complete your TPU design here                      //
// authors: kaikai (deekai9139@gmail.com)                                     //
//          suhan  (jjs93126@gmail.com)                                       //
//============================================================================//

`include "src/define.v"
`include "src/global_buffer.v"

module top(clk, rst, start, m, n,  k, done);

  input clk;
  input rst;
  input start;
  input [3:0] m, k, n;
  output reg done;

  reg                   wr_en_a,	//1 -> WR 0 -> RD
                        wr_en_b,
                        wr_en_out;
  reg  [`DATA_SIZE-1:0] index_a,	//index is use to control input row
                        index_b,
                        index_out;
  reg  [`WORD_SIZE-1:0] data_in_a,	//dont touch
                        data_in_b, 	//dont touch
                        data_in_o;	//output ans 
  wire [`WORD_SIZE-1:0] data_out_a,	//value from global buffer will read to here
                        data_out_b,
                        data_out_o;

//----------------------------------------------------------------------------//
// TPU module declaration                                                     //
//----------------------------------------------------------------------------//
  //****TPU tpu1(); add your design here*****//

reg [4:0]counter; //current buffer counter
reg [4:0]counter2; // round counter
reg [3:0]counter3; //block counter
reg [3:0]state_cs,state_ns;



parameter IDLE 	= 4'd0;
parameter WAIT 	= 4'd5;
parameter RD  	= 4'd1;
parameter IDLE2 = 4'd2;
parameter OP 	= 4'd3;
parameter WR 	= 4'd4;
parameter SHIFT = 4'd7;
parameter DONE 	= 4'd6;
parameter WAIT2 = 4'd8;

wire [7:0]tmp1,tmp2;
assign tmp1=((m-1)>>2)+1;
assign tmp2 = ((n-1)>>2)+1;

wire [7:0]big = (m>n)?m:n;
wire [7:0]BL_sum=big+k;
wire check = (counter2>BL_sum)?1:0;
wire check2 = (counter3==(tmp1*tmp2))?1:0;
wire check3 = (counter2==BL_sum+4)?1:0;



always@(posedge clk or posedge rst)begin
	if(rst)
		state_cs<=IDLE;
	else
		state_cs<=state_ns;
end

always@(*)begin
	case(state_cs)
		IDLE 	: state_ns = WAIT;
		WAIT 	: state_ns = check?OP:RD;
		RD 		: state_ns = (counter==k-1)?IDLE2:RD;
		IDLE2 	: state_ns = OP;
		OP 		: state_ns = check3?WAIT2:WAIT;
		WAIT2 	: state_ns = WR;
		WR 		: state_ns = (counter==4)?SHIFT:WR;
		SHIFT	: state_ns = check2?DONE:WAIT;
		DONE 	: state_ns = DONE;
	endcase
end

always@(posedge clk or posedge rst)begin
	if(rst)
		counter2<=0;
	else if(state_cs==OP)
		counter2<=counter2+1;
	else if (state_cs==SHIFT)
		counter2<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		counter<=0;
	else if(state_cs==RD || state_ns==WR)
		counter<=counter+1;
	else 
		counter<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		counter3<=0;
	else if(state_ns==SHIFT)
		counter3<=counter3+1;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		done<=0;
	else if(state_cs==DONE)
		done<=1;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		wr_en_a<=0;
	else
		wr_en_a<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		wr_en_b<=0;
	else
		wr_en_b<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		wr_en_out<=0;
	else if(state_ns==WR)
		wr_en_out<=1;
	else 
		wr_en_out<=0;
end
//////
reg [7:0]counter3_mux_a,counter3_mux_b,counter3_mux_o;
wire [1:0]m_remainder=m[1:0];
always@(*)begin
	case(counter3)
		0:counter3_mux_a=0;
		1:counter3_mux_a=(m>4)?k:0;
		2:counter3_mux_a=(m>8)?2*k:0;
		3:counter3_mux_a=(m>8)?0:k;
		4:counter3_mux_a=(m>8)?k:0;
		5:counter3_mux_a=(m>8)?2*k:k;
		6:counter3_mux_a=0;
		7:counter3_mux_a=k;
		8:counter3_mux_a=2*k;
	endcase
end
/*
always@(*)begin
	case(counter3)
		0:counter3_mux_b=0;
		1:counter3_mux_b=(m>4)?0:k;
		2:counter3_mux_b=(m>8)?0:(m>4)?k:2*k;
		3:counter3_mux_b=k;
		4:counter3_mux_b=(m>8)?k:2*k;
		5:counter3_mux_b=(m>8)?k:2*k;
		6:counter3_mux_b=2*k;
		7:counter3_mux_b=2*k;
		8:counter3_mux_b=2*k;
	endcase
end
*/

always@(*)begin
	if(m<4)begin
		case(counter3)
		0:counter3_mux_b=0;
		1:counter3_mux_b=k;
		2:counter3_mux_b=2*k;
		endcase
	end
	else if(m>8)begin
		case(counter3)
		0:counter3_mux_b=0;
		1:counter3_mux_b=0;
		2:counter3_mux_b=0;
		3:counter3_mux_b=k;
		4:counter3_mux_b=k;
		5:counter3_mux_b=k;
		6:counter3_mux_b=2*k;
		7:counter3_mux_b=2*k;
		8:counter3_mux_b=2*k;
		endcase
	end
		
	else begin
		case(counter3)
		0:counter3_mux_b=0;
		1:counter3_mux_b=0;
		2:counter3_mux_b=k;
		3:counter3_mux_b=k;
		4:counter3_mux_b=2*k;
		5:counter3_mux_b=2*k;
		endcase
	end
end


always@(*)begin
	if(m<4)begin
		case(counter3)
		0:counter3_mux_o=0;
		1:counter3_mux_o=m_remainder;
		2:counter3_mux_o=2*m_remainder;
		endcase
	end
	else if(m>8)begin
		case(counter3)
		0:counter3_mux_o=0;
		1:counter3_mux_o=4;
		2:counter3_mux_o=8;
		3:counter3_mux_o=9;
		4:counter3_mux_o=13;
		5:counter3_mux_o=17;
		6:counter3_mux_o=18;
		7:counter3_mux_o=22;
		8:counter3_mux_o=26;
		endcase
	end
		
	else begin
		case(counter3)
		0:counter3_mux_o=0;
		1:counter3_mux_o=4;
		2:counter3_mux_o=counter3_mux_o+m_remainder;
		3:counter3_mux_o=counter3_mux_o+4;
		4:counter3_mux_o=counter3_mux_o+m_remainder;
		5:counter3_mux_o=counter3_mux_o+4;
		endcase
	end
end

/*
always@(*)begin
	case(counter3)
		0:counter3_mux_o=0;
		1:counter3_mux_o=4;
		2:counter3_mux_o=8;
		3:counter3_mux_o=(m>8)?counter3_mux_o+1:counter3_mux_o+4;
		4:counter3_mux_o=counter3_mux_o+4;
		5:counter3_mux_o=counter3_mux_o+4;
		6:counter3_mux_o=(m>8)?counter3_mux_o+1:counter3_mux_o+4;
		7:counter3_mux_o=counter3_mux_o+4;
		8:counter3_mux_o=counter3_mux_o+4;
	endcase
end
*/
//////
always@(posedge clk or posedge rst)begin
	if(rst)
		index_a<=0;
	else if(state_ns==RD)
		index_a<=index_a+1;
	else 
		index_a<=counter3_mux_a;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		index_b<=0;

	else if(state_ns==RD)
		index_b<=index_b+1;
	else 
		index_b<=counter3_mux_b;
end
always@(posedge clk or posedge rst)begin
	if(rst)
		index_out<=0;
	else if(state_cs==WR && state_ns==WR)
		index_out<=index_out+1;
	else 
		index_out<=counter3_mux_o;
end




reg [7:0]a11,a12,a13,a14,
		 a21,a22,a23,a24,
		 a31,a32,a33,a34,
		 a41,a42,a43,a44;

reg [7:0]b11,b12,b13,b14,
		 b21,b22,b23,b24,
		 b31,b32,b33,b34,
		 b41,b42,b43,b44;
//////////////////////////////////////////////////////////	 
always@(posedge clk or posedge rst)begin
	if(rst)
		b11<=0;
	else if(state_cs==RD && counter2==k)
		b11<=0;
	else if(state_cs==RD && counter==0 && counter2==0)
		b11<=data_out_b[31:24];
	else if(state_cs==RD && counter==1 && counter2==1)
		b11<=data_out_b[31:24];
	else if(state_cs==RD && counter==2 && counter2==2)
		b11<=data_out_b[31:24];
	else if(state_cs==RD && counter==3 && counter2==3)
		b11<=data_out_b[31:24];
	else if(state_cs==RD && counter==4 && counter2==4)
		b11<=data_out_b[31:24];
	else if(state_cs==RD && counter==5 && counter2==5)
		b11<=data_out_b[31:24];
	else if(state_cs==RD && counter==6 && counter2==6)
		b11<=data_out_b[31:24];
	else if(state_cs==RD && counter==7 && counter2==7)
		b11<=data_out_b[31:24];
	else if(state_cs==RD && counter==8 && counter2==8)
		b11<=data_out_b[31:24];

end

always@(posedge clk or posedge rst)begin
	if(rst)
		b21<=0;
	else if(state_cs==WAIT || state_cs==WAIT2)
		b21<=b11;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b31<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b31<=b21;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b41<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b41<=b31;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b12<=0;
	else if(state_cs==RD && counter2==k+1)
		b12<=0;
	else if(state_cs==RD && counter==0 && counter2==1)
		b12<=data_out_b[23:16];
	else if(state_cs==RD && counter==1 && counter2==2)
		b12<=data_out_b[23:16];
	else if(state_cs==RD && counter==2 && counter2==3)
		b12<=data_out_b[23:16];
	else if(state_cs==RD && counter==3 && counter2==4)
		b12<=data_out_b[23:16];
	else if(state_cs==RD && counter==4 && counter2==5)
		b12<=data_out_b[23:16];
	else if(state_cs==RD && counter==5 && counter2==6)
		b12<=data_out_b[23:16];
	else if(state_cs==RD && counter==6 && counter2==7)
		b12<=data_out_b[23:16];
	else if(state_cs==RD && counter==7 && counter2==8)
		b12<=data_out_b[23:16];
	else if(state_cs==RD && counter==8 && counter2==9)
		b12<=data_out_b[23:16];

end

always@(posedge clk or posedge rst)begin
	if(rst)
		b22<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b22<=b12;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b32<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b32<=b22;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b42<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b42<=b32;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b13<=0;
	else if(state_cs==RD && counter2==k+2)
		b13<=0;
	else if(state_cs==RD && counter==0 && counter2==2)
		b13<=data_out_b[15:8];
	else if(state_cs==RD && counter==1 && counter2==3)
		b13<=data_out_b[15:8];
	else if(state_cs==RD && counter==2 && counter2==4)
		b13<=data_out_b[15:8];
	else if(state_cs==RD && counter==3 && counter2==5)
		b13<=data_out_b[15:8];
	else if(state_cs==RD && counter==4 && counter2==6)
		b13<=data_out_b[15:8];
	else if(state_cs==RD && counter==5 && counter2==7)
		b13<=data_out_b[15:8];
	else if(state_cs==RD && counter==6 && counter2==8)
		b13<=data_out_b[15:8];
	else if(state_cs==RD && counter==7 && counter2==9)
		b13<=data_out_b[15:8];
	else if(state_cs==RD && counter==8 && counter2==10)
		b13<=data_out_b[15:8];

end

always@(posedge clk or posedge rst)begin
	if(rst)
		b23<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b23<=b13;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b33<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b33<=b23;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b43<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b43<=b33;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b14<=0;
	else if(state_cs==RD && counter2==k+3)
		b14<=0;
	else if(state_cs==RD && counter==0 && counter2==3)
		b14<=data_out_b[7:0];
	else if(state_cs==RD && counter==1 && counter2==4)
		b14<=data_out_b[7:0];
	else if(state_cs==RD && counter==2 && counter2==5)
		b14<=data_out_b[7:0];
	else if(state_cs==RD && counter==3 && counter2==6)
		b14<=data_out_b[7:0];
	else if(state_cs==RD && counter==4 && counter2==7)
		b14<=data_out_b[7:0];
	else if(state_cs==RD && counter==5 && counter2==8)
		b14<=data_out_b[7:0];
	else if(state_cs==RD && counter==6 && counter2==9)
		b14<=data_out_b[7:0];
	else if(state_cs==RD && counter==7 && counter2==10)
		b14<=data_out_b[7:0];
	else if(state_cs==RD && counter==8 && counter2==11)
		b14<=data_out_b[7:0];

end

always@(posedge clk or posedge rst)begin
	if(rst)
		b24<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b24<=b14;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b34<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b34<=b24;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		b44<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		b44<=b34;
end

////////////////////////////////////////////////////////////////////////////////
always@(posedge clk or posedge rst)begin
	if(rst)
		a11<=0;
	else if(check)
		a11<=0;
	else if(state_cs==RD  && counter2==k)
		a11<=0;
	else if(state_cs==RD && counter==0 && counter2==0)
		a11<=data_out_a[31:24];
	else if(state_cs==RD && counter==1 && counter2==1)
		a11<=data_out_a[31:24];
	else if(state_cs==RD && counter==2 && counter2==2)
		a11<=data_out_a[31:24];
	else if(state_cs==RD && counter==3 && counter2==3)
		a11<=data_out_a[31:24];
	else if(state_cs==RD && counter==4 && counter2==4)
		a11<=data_out_a[31:24];
	else if(state_cs==RD && counter==5 && counter2==5)
		a11<=data_out_a[31:24];
	else if(state_cs==RD && counter==6 && counter2==6)
		a11<=data_out_a[31:24];
	else if(state_cs==RD && counter==7 && counter2==7)
		a11<=data_out_a[31:24];
	else if(state_cs==RD && counter==8 && counter2==8)
		a11<=data_out_a[31:24];

end

always@(posedge clk or posedge rst)begin
	if(rst)
		a12<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a12<=a11;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a13<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a13<=a12;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a14<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a14<=a13;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a21<=0;
	else if(check)
		a21<=0;
	else if(state_cs==RD && counter2==k+1)
		a21<=0;
	else if(state_cs==RD && counter==0 && counter2==1)
		a21<=data_out_a[23:16];
	else if(state_cs==RD && counter==1 && counter2==2)
		a21<=data_out_a[23:16];
	else if(state_cs==RD && counter==2 && counter2==3)
		a21<=data_out_a[23:16];
	else if(state_cs==RD && counter==3 && counter2==4)
		a21<=data_out_a[23:16];
	else if(state_cs==RD && counter==4 && counter2==5)
		a21<=data_out_a[23:16];
	else if(state_cs==RD && counter==5 && counter2==6)
		a21<=data_out_a[23:16];
	else if(state_cs==RD && counter==6 && counter2==7)
		a21<=data_out_a[23:16];
	else if(state_cs==RD && counter==7 && counter2==8)
		a21<=data_out_a[23:16];
	else if(state_cs==RD && counter==8 && counter2==9)
		a21<=data_out_a[23:16];

end

always@(posedge clk or posedge rst)begin
	if(rst)
		a22<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a22<=a21;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a23<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a23<=a22;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a24<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a24<=a23;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a31<=0;
	else if(check)
		a31<=0;
	else if(state_cs==RD && counter2==k+2)
		a31<=0;
	else if(state_cs==RD && counter==0 && counter2==2)
		a31<=data_out_a[15:8];
	else if(state_cs==RD && counter==1 && counter2==3)
		a31<=data_out_a[15:8];
	else if(state_cs==RD && counter==2 && counter2==4)
		a31<=data_out_a[15:8];
	else if(state_cs==RD && counter==3 && counter2==5)
		a31<=data_out_a[15:8];
	else if(state_cs==RD && counter==4 && counter2==6)
		a31<=data_out_a[15:8];
	else if(state_cs==RD && counter==5 && counter2==7)
		a31<=data_out_a[15:8];
	else if(state_cs==RD && counter==6 && counter2==8)
		a31<=data_out_a[15:8];
	else if(state_cs==RD && counter==7 && counter2==9)
		a31<=data_out_a[15:8];
	else if(state_cs==RD && counter==8 && counter2==10)
		a31<=data_out_a[15:8];

end

always@(posedge clk or posedge rst)begin
	if(rst)
		a32<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a32<=a31;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a33<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a33<=a32;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a34<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a34<=a33;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a41<=0;
	else if(check)
		a41<=0;
	else if(state_cs==RD && counter2==k+3)
		a41<=0;
	else if(state_cs==RD && counter==0 && counter2==3)
		a41<=data_out_a[7:0];
	else if(state_cs==RD && counter==1 && counter2==4)
		a41<=data_out_a[7:0];
	else if(state_cs==RD && counter==2 && counter2==5)
		a41<=data_out_a[7:0];
	else if(state_cs==RD && counter==3 && counter2==6)
		a41<=data_out_a[7:0];
	else if(state_cs==RD && counter==4 && counter2==7)
		a41<=data_out_a[7:0];
	else if(state_cs==RD && counter==5 && counter2==8)
		a41<=data_out_a[7:0];
	else if(state_cs==RD && counter==6 && counter2==9)
		a41<=data_out_a[7:0];
	else if(state_cs==RD && counter==7 && counter2==10)
		a41<=data_out_a[7:0];
	else if(state_cs==RD && counter==8 && counter2==11)
		a41<=data_out_a[7:0];

end

always@(posedge clk or posedge rst)begin
	if(rst)
		a42<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a42<=a41;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a43<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a43<=a42;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		a44<=0;
	else if(state_cs==WAIT|| state_cs==WAIT2)
		a44<=a43;
end

reg [7:0]pe0,pe1,pe2,pe3,
		  pe4,pe5,pe6,pe7,
		  pe8,pe9,pe10,pe11,
		  pe12,pe13,pe14,pe15;

always@(posedge clk or posedge rst)begin
	if(rst)
		pe0<=0;
	else if(state_cs==OP)
		pe0<=pe0+a11*b11;
	else if(state_cs==SHIFT)
		pe0<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe1<=0;
	else if(state_cs==OP)
		pe1<=pe1+a12*b12;
	else if(state_cs==SHIFT)
		pe1<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe2<=0;
	else if(state_cs==OP)
		pe2<=pe2+a13*b13;
	else if(state_cs==SHIFT)
		pe2<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe3<=0;
	else if(state_cs==OP)
		pe3<=pe3+a14*b14;
	else if(state_cs==SHIFT)
		pe3<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe4<=0;
	else if(state_cs==OP)
		pe4<=pe4+a21*b21;
	else if(state_cs==SHIFT)
		pe4<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe5<=0;
	else if(state_cs==OP)
		pe5<=pe5+a22*b22;
	else if(state_cs==SHIFT)
		pe5<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe6<=0;
	else if(state_cs==OP)
		pe6<=pe6+a23*b23;
	else if(state_cs==SHIFT)
		pe6<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe7<=0;
	else if(state_cs==OP)
		pe7<=pe7+a24*b24;
	else if(state_cs==SHIFT)
		pe7<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe8<=0;
	else if(state_cs==OP)
		pe8<=pe8+a31*b31;
	else if(state_cs==SHIFT)
		pe8<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe9<=0;
	else if(state_cs==OP)
		pe9<=pe9+a32*b32;
	else if(state_cs==SHIFT)
		pe9<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe10<=0;
	else if(state_cs==OP)
		pe10<=pe10+a33*b33;
	else if(state_cs==SHIFT)
		pe10<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe11<=0;
	else if(state_cs==OP)
		pe11<=pe11+a34*b34;
	else if(state_cs==SHIFT)
		pe11<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe12<=0;
	else if(state_cs==OP)
		pe12<=pe12+a41*b41;
	else if(state_cs==SHIFT)
		pe12<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe13<=0;
	else if(state_cs==OP)
		pe13<=pe13+a42*b42;
	else if(state_cs==SHIFT)
		pe13<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe14<=0;
	else if(state_cs==OP)
		pe14<=pe14+a43*b43;
	else if(state_cs==SHIFT)
		pe14<=0;
end

always@(posedge clk or posedge rst)begin
	if(rst)
		pe15<=0;
	else if(state_cs==OP)
		pe15<=pe15+a44*b44;
	else if(state_cs==SHIFT)
		pe15<=0;
end
////////////////////////////////////////////////////////////////////////////////

wire [31:0] ans0,ans1,ans2,ans3;

assign ans0={pe3[7:0],pe2[7:0],pe1[7:0],pe0[7:0]};
assign ans1={pe7[7:0],pe6[7:0],pe5[7:0],pe4[7:0]};
assign ans2={pe11[7:0],pe10[7:0],pe9[7:0],pe8[7:0]};
assign ans3={pe15[7:0],pe14[7:0],pe13[7:0],pe12[7:0]};
always@(posedge clk or posedge rst)begin
	if(rst)
		data_in_o<=0;
	else if(state_ns==WR)begin
		case(counter)
		0:data_in_o<=ans0;
		1:data_in_o<=ans1;
		2:data_in_o<=ans2;
		3:data_in_o<=ans3;
		endcase
	end
end

//----------------------------------------------------------------------------//
// Global buffers declaration                                                 //
//----------------------------------------------------------------------------//
  global_buffer GBUFF_A(.clk     (clk       ),
                        .rst     (rst       ),
                        .wr_en   (wr_en_a   ),
                        .index   (index_a   ),
                        .data_in (data_in_a ),
                        .data_out(data_out_a));

  global_buffer GBUFF_B(.clk     (clk       ),
                        .rst     (rst       ),
                        .wr_en   (wr_en_b   ),
                        .index   (index_b   ),
                        .data_in (data_in_b ),
                        .data_out(data_out_b));

  global_buffer GBUFF_OUT(.clk     (clk      ),
                          .rst     (rst      ),
                          .wr_en   (wr_en_out),
                          .index   (index_out),
                          .data_in (data_in_o),
                          .data_out(data_out_o));

endmodule
