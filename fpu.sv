//全体的に修正が加わっています
// さのくん
module normalize(
    input [27:0] sum,
    input [7:0] e,
    input Large_sign,
    output [31:0] res,
    output ovf
);

wire [0:0] fugo;
wire [4:0] u;

wire [27:0] number;

wire [23:0] number_rnd;
wire [25:0] number_shift; 
wire [23:0] number_shiftl; 
wire [25:0] number_shiftn2;

wire [23:0] z_m;
wire [0:0] guard;
wire [0:0] round;
wire [0:0] sticky;
wire [0:0] sticky_n;

wire [31:0] temp; //出力一時保存先
wire [0:0] ulps;
wire [2:0] ovf_c;
wire [7:0] e_fin;

wire [7:0] z_ae;
wire [7:0] z_ne;

// addから渡された値sumは符号を持たず、◯◯.・・・という形

//符号・仮数をそのまま渡す
assign number[27:0] = sum[27:0];
assign fugo[0] = Large_sign;

assign u = 
    (number[27]==1'b1) ? 5'b11111:
	(number[26]==1'b1) ? 5'b00000:
	(number[25]==1'b1) ? 5'b00001:
	(number[24]==1'b1) ? 5'b00010:
	(number[23]==1'b1) ? 5'b00011:
	(number[22]==1'b1) ? 5'b00100:
	(number[21]==1'b1) ? 5'b00101:
	(number[20]==1'b1) ? 5'b00110:
	(number[19]==1'b1) ? 5'b00111:
	(number[18]==1'b1) ? 5'b01000:
	(number[17]==1'b1) ? 5'b01001:
	(number[16]==1'b1) ? 5'b01010:
	(number[15]==1'b1) ? 5'b01011:
	(number[14]==1'b1) ? 5'b01100:
	(number[13]==1'b1) ? 5'b01101:
	(number[12]==1'b1) ? 5'b01110:
	(number[11]==1'b1) ? 5'b01111:
	(number[10]==1'b1) ? 5'b10000:
	(number[9]==1'b1) ? 5'b10001:
	(number[8]==1'b1) ? 5'b10010:
	(number[7]==1'b1) ? 5'b10011:
	(number[6]==1'b1) ? 5'b10100:
	(number[5]==1'b1) ? 5'b10101:
	(number[4]==1'b1) ? 5'b10110:
	(number[3]==1'b1) ? 5'b10111:
	(number[2]==1'b1) ? 5'b11000:
	(number[1]==1'b1) ? 5'b11001:
	5'b11010;

//normalize

//プライオリティエンコーダーの結果を整理
//1.最上位に1(u == 5'b11111):仮数を上から24ビット格納;eを+1 ◯◯.・・・=>◯.◯・・・
//2.それ以外一個飛ばしで格納 0◯.・・・ =>◯.・・・
//それぞれに合わせてgurad,round,sticky設定
assign z_m = (u == 5'b11111) ? sum[27:4] :
		sum[26:3];

assign guard =(u == 5'b11111) ? sum[3]:sum[2];

assign round =(u == 5'b11111) ? sum[2]:sum[1];

assign sticky =(u == 5'b11111) ? sum[1]|sum[0]:sum[0];

//場合分け
//1.(u == 5'b11111)
//2.シフトしきれない　sumの26bit目に1を持ってこれない=>非正規仮数 指数を0に
//それ以外　26bit目に1を持ってくる example. (case u==0) 01.・・・=>1.・・・ no shift
assign z_ae = (u == 5'b11111) ? e+1:
	      (e<=u) ? 8'b0:
	      e-u;

//実際にシフト
//1.(u == 5'b11111)or元から非正規仮数　(e==0) そのまま
//2.シフトしきれない　最上位に1を持ってこれない=>非正規仮数 e分シフト
//それ以外　最上位に1を持ってくる ex. (u==0) 01.・・・=>1.・・・ no shift　u分シフト
assign number_shift = ((u == 5'b11111)|(e==0)) ? {z_m,guard,round}:
		      (z_ae==0) ? {z_m,guard,round}<<(e-1):
		      {z_m,guard,round}<<u;

//number_shiftl:24bit ◯.・・・
//ulp=number_shift[2],guard=number_shift[1],round=number_shift[0]
assign number_shiftl =number_shift[25:2];

//e normalize2 全体の方で上がっているurl　https://github.com/dawsonjon/fpu/blob/master/adder/adder.v
//でのサンプルにあった場合分け->よくわからないので削除

assign z_ne=/*((|z_ae[7:0]==0)&&(number_shift[25]==1)) ? z_ae+1:*/z_ae;
assign sticky_n = /*((|z_ae[7:0]==0)&&(number_shift[25]==1)) ? sticky|number_shiftl[0]:*/sticky;
assign number_shiftn2 = /*((|z_ae[7:0]==0)&&(number_shift[25]==1)) ? number_shift <<1 :*/number_shift;

//ulps=g&&(r|s|u)(ulp=number_shiftl[0],guard=number_a[1],round=number_a[0],sticky=sum[0])
assign ulps = number_shiftn2[1]&&(number_shiftn2[0]|sticky_n|number_shiftn2[2]);

//round
//number_rnd:24bit ◯.・・・
assign number_rnd=(ulps == 1'b1) ? number_shiftl[23:0]+1:number_shiftl[23:0]; 

//overflow_check:ulp桁上がり前eがmax,ulpで+1,仮数がmax
assign ovf_c ={&number_rnd[23:0],&z_ne[7:0],ulps};

//最終のe
//ulpによる桁上がりをcheck
//ulpで+1,num_rndがall 0
assign e_fin =((ulps == 1'b1)&&(|number_rnd[23:0] == 0)) ? (z_ne + 1'b1) : z_ne;

//結果
//（NaNとかの場合分けはここに追加するとよい)　advice:すべてのモジュールに input statusでstatusで分岐
//非正規仮数:正規化数に昇進するかいなか (e_fin == 8'b0)
//正規仮数：非正規に落ちるかいなか(e_fin == 8'b1)&&(number_rnd[23] == 0)
//オーバーフロー
//それ以外
assign temp = 
((e_fin == 8'b0)&&(number_rnd[23] == 1)) ? {fugo[0:0], 8'b00000001, number_rnd[22:0]} : 
(e_fin==8'b0) ? {fugo[0:0], 8'b00000000, number_rnd[22:0]} :  
(ovf_c == 3'b111) ? {fugo[0:0], (8'b11111111),23'b0} :
{fugo[0:0], e_fin, number_rnd[22:0]} ;


// 最終的にはこういう感じでresに代入する
assign res = temp;

assign ovf= (ovf_c == 3'b111) ? 1'b1 : 1'b0;

endmodule


// 盛くん
//Large_n =>でかい方の数,Small_n=>小さい方の数
//sum_rnd => 結果
//2の補数表示せず
module add(
	input [26:0] Large_n,
	input [26:0] Small_n,
	input Large_sign,
	input Small_sign,
	input [7:0] e,
	output [31:0] res,
	output ovf
);


wire [27:0] sum;
//小数点位置　sum=◯◯.・・・
assign sum = (Large_sign==Small_sign) ? Large_n+Small_n : 
             (Large_n>Small_n) ? Large_n-Small_n:
             Small_n-Large_n;

wire Large_sign2;

assign Large_sign2 = (Large_sign!=Small_sign)&&(Large_n == Small_n) ? 1'b0 : Large_sign;

//add内でroundしない

normalize normalize( .sum(sum), .e(e), .Large_sign(Large_sign2), .res(res), .ovf(ovf) );
endmodule


// 阪本くん担当
module calladd(
	input [30:0] Large,
	input [30:0] Small,
	input Large_sign,
	input Small_sign,
	input [7:0] Shift_n,
	input [7:0] Large_e,
	input [7:0] Small_e,
	output [31:0] res,
	output ovf
);

wire [25:0] Large2;
wire [300:0] Small2;


// 上下2bit拡張 上：正規・非正規分岐　下:ulp,guard追加
assign Large2 = (|Large_e==1'b0) ? {1'b0,Large[22:0],2'b00} : {1'b1,Large[22:0],2'b00};
assign Small2 = (|Small_e==1'b0) ? {1'b0,Small[22:0],277'b0} : {1'b1,Small[22:0],277'b0};

wire [300:0] shiftedS;
wire oror;
wire [7:0] shift;

assign shift = (Large_e == 0)&&(Small_e == 0) ? Shift_n:
				(Small_e == 0) ? Shift_n-1:
				Shift_n;
// 小さい方をシフト
assign shiftedS = Small2 >> shift;
assign oror = |Small2[274:0];

wire [26:0] Large3;
wire [26:0] Small3;

//最下位にsticky(oror)を追加
assign Large3 = {Large2,1'b0};
assign Small3 = {shiftedS[300:275],oror};


add add(.Large_n(Large3), .Small_n(Small3), .Large_sign(Large_sign), .Small_sign(Small_sign), .e(Large_e), .res(res), .ovf(ovf) );

endmodule


// Main
module compare(
	input [31:0] a,
	input [31:0] b,
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
	input [31:0] a,
        input [31:0] b,
        output isNaN
);

assign isNaN = (a[30:23] == 8'b11111111)||(b[30:23] == 8'b11111111) ? 1'b1 : 1'b0;

endmodule

module when_NaN(
	input [31:0] a,
        input [31:0] b,
        output [31:0] res,
	output ovf
);

assign ovf = 1'b0;
assign res = (|b[22:0] != 0)&&(b[30:23] == 8'b11111111)&&(|a[22:0] != 0)&&(a[30:23] == 8'b11111111)&&(a[31]==b[31])                     ? {b[31], 9'b111111111, b[21:0]} :
		 (|b[22:0] != 0)&&(b[30:23] == 8'b11111111)&&(|a[22:0] != 0)&&(a[30:23] == 8'b11111111)                                         ? {10'b0111111111, b[21:0]} :
		 (|b[22:0] != 0)&&(b[30:23] == 8'b11111111)                                                                                     ? {b[31], 9'b111111111, b[21:0]} :
	     (|a[22:0] != 0)&&(a[30:23] == 8'b11111111)                                                                                     ? {a[31], 10'b0111111111, a[21:0]} :
	     (((a[31] == 1'b0)&&(b[31] == 1'b1))||((a[31] == 1'b1)&&(b[31] == 1'b0)))&&(b[30:23] == 8'b11111111)&&(a[30:23] == 8'b11111111) ? {32'b01111111110000000000000000000000}    :
	     (a[30:23] == 8'b11111111)                                                                                                      ? {a[31],31'b1111111100000000000000000000000}     :
		 {b[31],31'b1111111100000000000000000000000};

endmodule

module fadd(
	input [31:0] a,
        input [31:0] b,
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
