// さのくん
module normalize(
    input [24:0] sum_rnd,
    input [7:0] e,
    output [31:0] res
);

wire [0:0] fugo;
wire [4:0] u;
wire [23:0] number;
wire [23:0] number_shiftl;
wire [31:0] temp; //出力一時保存先

// 正規化などをする
// addから渡された値は正ならば正、負ならば２の補数表示になっている

// 補数ならば２進に直す

assign number[23:0] = (sum_rnd[24] == 1'b1) ? ((~sum_rnd[23:0]) + 1'b1) : sum_rnd[23:0];// ~はビット反転（たぶん）
assign fugo[0] = sum_rnd[24];

//補数を２進に直してnumberに入れた

//pdfだと25bit目が1の時右shiftしてるんだけど、盛くんの実装だと25bit目は符号らしいので、ここは24bit目が１の時右shiftにすべきでは？と考えて変えた

assign u = 
    (number[23]==1'b1) ? 5'b11111:
	(number[22]==1'b1) ? 5'b00000:
	(number[21]==1'b1) ? 5'b00001:
	(number[20]==1'b1) ? 5'b00010:
	(number[19]==1'b1) ? 5'b00011:
	(number[18]==1'b1) ? 5'b0010:
	(number[17]==1'b1) ? 5'b00101:
	(number[16]==1'b1) ? 5'b00110:
	(number[15]==1'b1) ? 5'b00111:
	(number[14]==1'b1) ? 5'b01000:
	(number[13]==1'b1) ? 5'b01001:
	(number[12]==1'b1) ? 5'b01010:
	(number[11]==1'b1) ? 5'b01011:
	(number[10]==1'b1) ? 5'b01100:
	(number[9]==1'b1) ? 5'b01101:
	(number[8]==1'b1) ? 5'b01110:
	(number[7]==1'b1) ? 5'b01111:
	(number[6]==1'b1) ? 5'b10000:
	(number[5]==1'b1) ? 5'b10001:
	(number[4]==1'b1) ? 5'b10010:
	(number[3]==1'b1) ? 5'b10011:
	(number[2]==1'b1) ? 5'b10100:
	(number[1]==1'b1) ? 5'b10101:
	5'b10110;

// 例外処理を入れないといけないのかもしれない。資料では入れているっぽい。とりあえず後回し。
// 右シフトするのは、number[23]が１のときで、1bit右シフト
// 左シフトするのは、それ以外の時で、uの数ぶんシフト
	
assign number_shiftl = number << u;
assign temp = (u == 5'b11111) ? {fugo[0:0], (e + 1'b1), number[23:1]} : {fugo[0:0], (e - {3'b000, u} ), number_shiftl[23:1]};

// e-uが、e:8bit u:5bitなのでこのまま引き算していいのか不安

// 最終的にはこういう感じでresに代入する
assign res = temp;

endmodule


// 盛くん
//Large_n =>でかい方の数,Small_n=>小さい方の数,bit_r =>シフトで消えるビットのor
//sum_rnd => 結果
module add(
	input [25:0] Large_n,
	input [25:0] Small_n,
	input bit_r,
	input [7:0] e,
	output [31:0] res
);


wire [26:0] sum;
wire [3:0] ulps;
wire [24:0] sum_rnd;

// 普通に足し算 符号拡張法
//ulps={sumの下位2ビット,large_nの符号とsmall_nの符号のxor,bit_rとsum[0]のor}

assign sum ={Large_n[25],Large_n}+{Small_n[25],Small_n};
assign ulps ={sum[2:1],Large_n[25]^Small_n[25],sum[0]|bit_r};

// 場合分け

	//結果が正
		//0.1ulp未満=>切り捨て
assign sum_rnd=	//(ulps == 4'b0000) ? sum[26:2]:
		//(ulps == 2'b0001) ? sum[26:2]:
		//(ulps == 2'b1000) ? sum[26:2]:
		//(ulps == 2'b1001) ? sum[26:2]:
		//0.1ulp=>切り捨て ラウンドイーブン
		//(ulps == 2'b0100) ? sum[26:2]:
		//0.1ulp=>切り上げ ラウンドイーブン
		(ulps == 4'b1100) ? sum[26:2]+1:
		//0.1ulp以上=>切り上げ
		(ulps == 4'b0101) ? sum[26:2]+1:
		(ulps == 4'b1101) ? sum[26:2]+1:
		//結果が負
		//0.1ulp未満=>切り捨て
		//(ulps == 2'b0010) ? sum[26:2]:
		//(ulps == 2'b0011) ? sum[26:2]:
		//(ulps == 2'b1010) ? sum[26:2]:
		//(ulps == 2'b1011) ? sum[26:2]:
		//0.1ulp=>切り捨て ラウンドイーブン
		//(ulps == 2'b0110) ? sum[26:2]:
		//0.1ulp=>切り上げ ラウンドイーブン
		(ulps == 4'b1110) ? sum[26:2]-1:
		//0.1ulp以上=>切り上げ
		(ulps == 4'b0111) ? sum[26:2]-1:
		(ulps == 4'b1111) ? sum[26:2]-1:
		sum[26:2];

//
// outputは、足し算した結果を25bitにまるめたもの。しかし、正規化や2進に治すことはしなくていい
//正規化はまだ考えていない by 盛
normalize normalize( .sum_rnd(sum_rnd), .e(e), .res(res) );

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
	output [31:0] res
);

wire [24:0] Large2;
wire [299:0] Small2;

// 上下2bit拡張
assign Large2 = (|Large_e==1'b0) ? {1'b0,Large[22:0],1'b0} : {1'b1,Large[22:0],1'b0};
assign Small2 = (|Small_e==1'b0) ? {1'b0,Small[22:0],276'b0} : {1'b1,Small[22:0],276'b0};

wire [300:0] shiftedS;
wire oror;

// 小さい方をシフト
assign shiftedS = Small2 >> Shift_n;
assign oror = |Small2[274:0];

wire [25:0] Large3;
wire [25:0] Small3;

// 負の数ならば補数に変換
assign Large3 = (Large_sign==1'b1) ? {1'b1,~Large2} + 1'b1 : {1'b0,Large2};
assign Small3 = (Small_sign==1'b1) ? {1'b1,~shiftedS[299:275]} + 1'b1 : {1'b0,shiftedS[299:275]};


add add(.Large_n(Large3), .Small_n(Small3), .bit_r(oror), .e(Large_e), .res(res) );

endmodule


// Main
module fadd(
	input [31:0] a,
	input [31:0] b,
	output [31:0] res,
    output ovf
);

wire [30:0] Large;
wire [30:0] Small;
wire Large_sign;
wire Small_sign;
wire [31:0] Shift_n;
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

calladd calladd( .Large(Large), .Small(Small), .Large_sign(Large_sign), .Small_sign(Small_sign), .Shift_n(Shift_n), .res(res), .Large_e(Large_e), .Small_e(Small_e) );

endmodule
