//normalize
module normalize(
    input  [50:0] sum,
    input  [7:0] e,
    input  Large_sign,
    output [31:0] res,
    output ovf
);

wire fugo;
wire [4:0] u;

wire [27:0] number;

wire [23:0] number_rnd;
wire [60:0] number_shift; 
wire [23:0] number_shiftl; 

wire ulps;
wire [2:0] ovf_c;
wire [7:0] e_fin;

wire [7:0] z_ae;

// addから渡された値sumは符号を持たず、◯◯.・・・という形

//符号・仮数をそのまま渡す
assign number[27:0] = sum[50:23];
assign fugo = Large_sign;

assign u = 
    (number[27]==1'b1) ? 5'b11111 :
	(number[26]==1'b1) ? 5'b00000 :
	(number[25]==1'b1) ? 5'b00001 :
	(number[24]==1'b1) ? 5'b00010 :
	(number[23]==1'b1) ? 5'b00011 :
	(number[22]==1'b1) ? 5'b00100 :
	(number[21]==1'b1) ? 5'b00101 :
	(number[20]==1'b1) ? 5'b00110 :
	(number[19]==1'b1) ? 5'b00111 :
	(number[18]==1'b1) ? 5'b01000 :
	(number[17]==1'b1) ? 5'b01001 :
	(number[16]==1'b1) ? 5'b01010 :
	(number[15]==1'b1) ? 5'b01011 :
	(number[14]==1'b1) ? 5'b01100 :
	(number[13]==1'b1) ? 5'b01101 :
	(number[12]==1'b1) ? 5'b01110 :
	(number[11]==1'b1) ? 5'b01111 :
	(number[10]==1'b1) ? 5'b10000 :
	(number[9]==1'b1)  ? 5'b10001 :
	(number[8]==1'b1)  ? 5'b10010 :
	(number[7]==1'b1)  ? 5'b10011 :
	(number[6]==1'b1)  ? 5'b10100 :
	(number[5]==1'b1)  ? 5'b10101 :
	(number[4]==1'b1)  ? 5'b10110 :
	(number[3]==1'b1)  ? 5'b10111 :
	(number[2]==1'b1)  ? 5'b11000 :
	(number[1]==1'b1)  ? 5'b11001 :
	(number[0]==1'b1)  ? 5'b11010 :
	5'b11011;

//場合分け
//1.(u == 5'b11111)
//2.シフトしきれない　sumの26bit目に1を持ってこれない=>非正規仮数 指数を0に
//それ以外　26bit目に1を持ってくる example. (case u==0) 01.・・・=>1.・・・ no shift
assign z_ae = (u == 5'b11111) ? e+1 :
	          (e<=u+1)        ? 8'b0 :
	          e-u;

//実際にシフト
//1.(u == 5'b11111) そのまま
//2.元から非正規仮数(e==0) sumの追加ビット分1だけシフト
//3.シフトしきれない　最上位に1を持ってこれない=>非正規仮数 e分シフト
//それ以外　最上位に1を持ってくる ex. (u==0) 01.・・・=>1.・・・ no shift　u分シフト
assign number_shift = (u == 5'b11111) ? sum :
					  (e==0)          ? sum<<1 :
					  (z_ae==0)       ? sum<<e :
		              sum << (u+1);

//number_shiftl:24bit
assign number_shiftl = number_shift[50:27];

//ulps=g&&(r|s|u)
//ulp=number_shift[27],guard=number_shift[26],round=number_shift[16]
assign ulps = number_shift[26]&&(number_shift[25]|(|number_shift[24:0])|number_shift[27]);

//round
//number_rnd:24bit
assign number_rnd = (ulps == 1'b1) ? number_shiftl[23:0]+1:number_shiftl[23:0]; 

//最終のe
//ulpによる桁上がりをcheck
//ulpで+1,num_rndがall 0
assign e_fin = ((ulps == 1'b1)&&(|number_rnd[23:0] == 0)) ? (z_ae + 1) : z_ae;

//overflow_check:e_finがmax,ulpで+1,仮数がmax
assign ovf_c = {&number_rnd[23:0],&e_fin,ulps};

assign ovf = (ovf_c == 3'b111) ? 1'b1 : 1'b0;

//結果
//オーバーフロー
//非正規仮数:正規化数に昇進するかいなか (e_fin == 8'b0)
//正規仮数：非正規に落ちるかいなか(e_fin == 8'b1)&&(number_rnd[23] == 0)
//それ以外
assign res = 
	(&e_fin == 1'b1)                         ? {fugo, (8'b11111111),23'b00000000000000000000000} :
	((e_fin == 8'b0)&&(number_rnd[23] == 1)) ? {fugo, 8'b00000001, number_rnd[22:0]} : 
	(e_fin==8'b0)                            ? {fugo, 8'b00000000, number_rnd[22:0]} :  
	{fugo, e_fin, number_rnd[22:0]} ;

endmodule


//Large_n =>でかい方の数,Small_n=>小さい方の数
//sum => 結果
//2の補数表示せず
module add(
	input  [49:0] Large_n,
	input  [49:0] Small_n,
	input  Large_sign,
	input  Small_sign,
	input  [7:0] e,
	output [31:0] res,
	output ovf
);

wire [50:0] sum;
//小数点位置　sum=◯◯.・・・
assign sum = (Large_sign==Small_sign) ? Large_n+Small_n : 
             (Large_n>Small_n)        ? Large_n-Small_n :
             Small_n-Large_n;

wire Large_sign2;
wire [7:0] e2;

assign Large_sign2 = (Large_sign!=Small_sign)&&(Large_n == Small_n) ? 1'b0 : Large_sign;
assign e2 = (Large_sign!=Small_sign)&&(Large_n == Small_n)          ? 8'b00000000 : e;

//add内でroundしない

normalize normalize( .sum(sum), .e(e2), .Large_sign(Large_sign2), .res(res), .ovf(ovf) );
endmodule


module calladd(
	input  [30:0] Large,
	input  [30:0] Small,
	input  Large_sign,
	input  Small_sign,
	input  [7:0] Shift_n,
	input  [7:0] Large_e,
	input  [7:0] Small_e,
	output [31:0] res,
	output ovf
);

wire [49:0] Large2;
wire [49:0] Small2;

// 上下2bit拡張 上：正規・非正規分岐　下:ulp,guard追加
assign Large2 = (|Large_e==1'b0) ? {1'b0,Large[22:0],26'b0} : {1'b1,Large[22:0],26'b0};
assign Small2 = (|Small_e==1'b0) ? {1'b0,Small[22:0],26'b0} : {1'b1,Small[22:0],26'b0};

wire [49:0] shiftedS;
wire [7:0] shift;

assign shift =  (Shift_n >= 35)&&(Small_e != 0) ? {8'b00100011} :
                (Large_e == 0)&&(Small_e == 0) ? Shift_n :
				(Small_e == 0)   ? Shift_n-1 :
				Shift_n;

// 小さい方をシフト
assign shiftedS = Small2 >> shift;

add add(.Large_n(Large2), .Small_n(shiftedS), .Large_sign(Large_sign), .Small_sign(Small_sign), .e(Large_e), .res(res), .ovf(ovf) );

endmodule


module compare(
	input  [31:0] a,
	input  [31:0] b,
	output [31:0] res,
    output ovf
);

wire [30:0] Large;
wire [30:0] Small;
wire Large_sign;
wire Small_sign;
wire [7:0] Shift_n;
wire [7:0] Large_e;
wire [7:0] Small_e;

assign Large = 
    (a[30:23] > b[30:23]) ? a[30:0] :
    (b[30:23] > a[30:23]) ? b[30:0] :
    (a[22:0] > b[22:0])   ? a[30:0] : 
    (b[22:0] > a[22:0])   ? b[30:0] : 
    a[30:0];

assign Small = 
    (a[30:23] > b[30:23]) ? b[30:0] :
    (b[30:23] > a[30:23]) ? a[30:0] :
    (a[22:0] > b[22:0])   ? b[30:0] : 
    (b[22:0] > a[22:0])   ? a[30:0] : 
    b[30:0];

assign Large_sign = 
    (a[30:23] > b[30:23]) ? a[31] :
    (b[30:23] > a[30:23]) ? b[31] :
    (a[22:0] > b[22:0])   ? a[31] : 
    (b[22:0] > a[22:0])   ? b[31] : 
    a[31];

assign Small_sign = 
    (a[30:23] > b[30:23]) ? b[31] :
    (b[30:23] > a[30:23]) ? a[31] :
    (a[22:0] > b[22:0])   ? b[31] : 
    (b[22:0] > a[22:0])   ? a[31] : 
    b[31];

assign Shift_n = 
    (a[30:23] > b[30:23]) ? a[30:23] - b[30:23] :
    (b[30:23] > a[30:23]) ? b[30:23] - a[30:23] :
    (a[22:0] > b[22:0])   ? a[30:23] - b[30:23] : 
    (b[22:0] > a[22:0])   ? b[30:23] - a[30:23] : 
    a[30:23] - b[30:23];

assign Large_e = 
    (a[30:23] > b[30:23]) ? a[30:23] :
    (b[30:23] > a[30:23]) ? b[30:23] :
    (a[22:0] > b[22:0])   ? a[30:23] : 
    (b[22:0] > a[22:0])   ? b[30:23] : 
    a[30:23];

assign Small_e = 
    (a[30:23] > b[30:23]) ? b[30:23] :
    (b[30:23] > a[30:23]) ? a[30:23] :
    (a[22:0] > b[22:0])   ? b[30:23] : 
    (b[22:0] > a[22:0])   ? a[30:23] : 
    b[30:23];

calladd calladd( .Large(Large), .Small(Small), .Large_sign(Large_sign), .Small_sign(Small_sign), .Shift_n(Shift_n), .res(res), .ovf(ovf), .Large_e(Large_e), .Small_e(Small_e) );

endmodule


module is_NaN(
	input  [31:0] a,
    input  [31:0] b,
    output isNaN
);

assign isNaN = (a[30:23] == 8'b11111111)||(b[30:23] == 8'b11111111) ? 1'b1 : 1'b0;

endmodule


module when_NaN(
	input  [31:0] a,
    input  [31:0] b,
    output [31:0] res,
	output ovf
);

assign ovf = 1'b0;
assign res = (|b[22:0] != 0)&&(b[30:23] == 8'b11111111)                             ? {b[31], 9'b111111111, b[21:0]} :
	         (|a[22:0] != 0)&&(a[30:23] == 8'b11111111)                             ? {a[31], 9'b111111111, a[21:0]} :
	         (a[31] != b[31])&&(b[30:23] == 8'b11111111)&&(a[30:23] == 8'b11111111) ? 32'b11111111110000000000000000000000 :
		     (a[30:23] == 8'b11111111)                                              ? {a[31],31'b1111111100000000000000000000000} :
		     {b[31],31'b1111111100000000000000000000000};

endmodule


//Main
module fadd(
	input  [31:0] a,
    input  [31:0] b,
    output [31:0] res,
    output ovf
);

wire isNaN;
wire [31:0] res_N;
wire [31:0] res_NaN;
wire ovf_N;
wire ovf_NaN;

is_NaN is_NaN( .a(a), .b(b), .isNaN(isNaN));
compare compare( .a(a), .b(b), .res(res_N), .ovf(ovf_N));
when_NaN when_NaN( .a(a), .b(b), .res(res_NaN), .ovf(ovf_NaN));

assign res = isNaN ? res_NaN : res_N;
assign ovf = isNaN ? ovf_NaN : ovf_N;

endmodule
