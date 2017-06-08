// さのくん
module normalize(
    input [24:0] kekka,
    input [7:0] e,
    output [31:0] res
);

	wire [0:0] fugo;
	wire [4:0] u;
	wire [23:0] number;
	wire [31:0] temp; //出力一時保存先

// 正規化などをする
// addから渡された値は正ならば正、負ならば２の補数表示になっている

// 補数ならば２進に直す

always_comb @(kekka, e) begin

	if (kekka[24] == 1'b1) begin
		number[23:0] =  ((~kekka[23:0]) + 1'b1);// ~はビット反転（たぶん）
		fugo[0] = kekka[24];
		//補数を２進に直してnumberに入れた
	end else begin
		number = kekka[23:0];
		fugo[0] = kekka[24];
	end
end

function [4:0] discover_first_1; //pdfだと25bit目が1の時右shiftしてるんだけど、盛くんの実装だと25bit目は符号らしいので、ここは24bit目が１の時右shiftにすべきでは？と考えて変えた
	input [23:0] t;
	if(t[23]==1'b1) discover_first_1 = 5'b11111;
	else if(t[22]==1'b1) discover_first_1 = 5'b00000;
	else if(t[21]==1'b1) discover_first_1 = 5'b00001;
	else if(t[20]==1'b1) discover_first_1 = 5'b00010;
	else if(t[19]==1'b1) discover_first_1 = 5'b00011;
	else if(t[18]==1'b1) discover_first_1 = 5'b00100;
	else if(t[17]==1'b1) discover_first_1 = 5'b00101;
	else if(t[16]==1'b1) discover_first_1 = 5'b00110;
	else if(t[15]==1'b1) discover_first_1 = 5'b00111;
	else if(t[14]==1'b1) discover_first_1 = 5'b01000;
	else if(t[13]==1'b1) discover_first_1 = 5'b01001;
	else if(t[12]==1'b1) discover_first_1 = 5'b01010;
	else if(t[11]==1'b1) discover_first_1 = 5'b01011;
	else if(t[10]==1'b1) discover_first_1 = 5'b01100;
	else if(t[9]==1'b1) discover_first_1 = 5'b01101;
	else if(t[8]==1'b1) discover_first_1 = 5'b01110;
	else if(t[7]==1'b1) discover_first_1 = 5'b01111;
	else if(t[6]==1'b1) discover_first_1 = 5'b10000;
	else if(t[5]==1'b1) discover_first_1 = 5'b10001;
	else if(t[4]==1'b1) discover_first_1 = 5'b10010;
	else if(t[3]==1'b1) discover_first_1 = 5'b10011;
	else if(t[2]==1'b1) discover_first_1 = 5'b10100;
	else if(t[1]==1'b1) discover_first_1 = 5'b10101;
	else if(t[0]==1'b1) discover_first_1 = 5'b10110;
endfunction

assign u = discover_first_1(number[23:0]);

always_comb @(number, u) begin
	// 例外処理を入れないといけないのかもしれない。資料では入れているっぽい。とりあえず後回し。
	// 右シフトするのは、number[23]が１のときで、1bit右シフト
	// 左シフトするのは、それ以外の時で、uの数ぶんシフト

	if (u == 5'b1111) begin
		temp[22:0] = number[23:1]; // ずらした仮数を格納
		temp[30:23] = e + 1'b1; // 指数に１プラス
		temp[31] = fugo[0];
	end else begin
		temp[22:0] = number << u; //uだけ左shiftしたいんだけどこの書き方でいいのか不安
		temp[30;23] = e - u; // ここeが8bitでuが5bitなんだけどそのまま足し算していいのか不安
		temp[31] = fugo[0];

	end




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
	output [24:0] sum_rnd
);


wire [26:0] sum;
wire [3:0] ulps;

// 普通に足し算 符号拡張法
//ulps={sumの下位2ビット,large_nの符号,bit_r}

assign sum ={Large_n[25],Large_n}+{Small_n[25],Small_n};
assign ulps ={sum[1:0],Large_n[25],bit_r}

// 場合分け
always_comb begin
	case(ulps)
		//結果が正
		//0.1ulp未満=>切り捨て
		2'b0000:sum_rnd=sum[25:1];
		2'b0001:sum_rnd=sum[25:1];
		2'b1000:sum_rnd=sum[25:1];
		2'b1001:sum_rnd=sum[25:1];
		//0.1ulp=>切り捨て ラウンドイーブン
		2'b0100:sum_rnd=sum[25:1];
		//0.1ulp=>切り上げ ラウンドイーブン
		2'b1100:sum_rnd=sum[25:1]+1;
		//0.1ulp以上=>切り上げ
		2'b0101:sum_rnd=sum[25:1]+1;
		2'b1101:sum_rnd=sum[25:1]+1;
		//結果が負
		//0.1ulp未満=>切り捨て
		2'b0010:sum_rnd=sum[25:1];
		2'b0011:sum_rnd=sum[25:1];
		2'b1010:sum_rnd=sum[25:1];
		2'b1011:sum_rnd=sum[25:1];
		//0.1ulp=>切り捨て ラウンドイーブン
		2'b0110:sum_rnd=sum[25:1];
		//0.1ulp=>切り上げ ラウンドイーブン
		2'b1110:sum_rnd=sum[25:1]-1;
		//0.1ulp以上=>切り上げ
		2'b0111:sum_rnd=sum[25:1]-1;
		2'b1111:sum_rnd=sum[25:1]-1;
	endcase
end



// outputは、足し算した結果を25bitにまるめたもの。しかし、正規化や2進に治すことはしなくていい
//正規化はまだ考えていない by 盛
naosu();


endmodule

// 阪本くん担当
module calladd(
	input [30:0] l,
	input [30:0] s,
	input L,
	input S,
	input [7:0] d,
	input oror,
	output [31:0] res
);

wire [26:0] la;
wire [300:0] sm;

// 上下2bit拡張
assign la = (|l==1'b0) ? {2'b00,l[22:0],2'b00} : {2'b01,l[22:0],2'b00};
assign sm = (|s==1'b0) ? {2'b00,s[22:0],276'b0} : {2'b01,s[22:0],276'b0};

wire [300:0] shiftsm;
wire orwotoru;

// 小さい方をシフト
assign shiftsm = sm >> d;
assign orwotoru = |sm[273:0];

wire [26:0] lar;
wire [26:0] sma;

// 負の数ならば補数に変換
always @(L or S or la or shiftsm) begin
	if(L==1'b1) begin
		lar <= ~l + 1'b1;
	end else begin
		lar <= l;
	end
	if(S==1'b1) begin
		sma <=(~sm[300:274]) + 1'b1;
	end else begin
		sma <= sm[300:274];
	end
end

add add(.lar(lar), .sma(sma), .oror(oror) .res(res) )

endmodule

module compare(
	input [31:0] a,
	input [31:0] b,
	output [31:0] res
);

wire [30:0] l,
	wire [30:0] s,
	wire L,
	wire S,
	wire [31:0] d;
wire oror;
if (a[30:23] > b[30:23]) begin
	assign l = a[30:0];
	assign s = b[30:0];
	assign L = a[31];
	assign S = b[31];
	assign d = a[30:23] - b[30:23]
end
else if (a[30:23] < b[30:23]) begin
	assign l = b[30:0];
	assign s = a[30:0];
	assign L = b[31];
	assign S = a[31];
	assign d = b[30:23] - a[30:23]
end
else if(a[22:0] > b[22:0]) begin
	assign l = a[30:0];
	assign s = b[30:0];
	assign L = a[31];
	assign S = b[31];
	assign d = a[30:23] - b[30:23]
end
else if (a[22:0] < b[22:0]) begin
	assign l = b[30:0];
	assign s = a[30:0];
	assign L = b[31];
	assign S = a[31];
	assign d = b[30:23] - a[30:23]
end
// ここは適当
else if (a[22:0] == b[22:0]) begin
	assign l = b[30:0];
	assign s = a[30:0];
	assign L = b[31];
	assign S = a[31];
	assign d = a[30:23] - b[30:23]
end 

calladd calladd(.oror(oror), .l(l), .s(s), .L(L), .S(S), .d(d), .res(res))
endmodule
