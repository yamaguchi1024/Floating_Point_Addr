// さのくん
module normalize(
    input [31:0] kekka,
    output [31:0] res
);
// 正規化などをする


// 最終的にはこういう感じでresに代入する
assign res = hoge;

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

// 符号を付け加える
wire [26:0] lar;
wire [26:0] sma;

// 00を追加
assign n = {l[22:0],2'b00};
assign m = {s[22:0],2'b00};

wire [128:0] o;

// 小さい方をシフト
assign o = k >> d;

assign watasu = o[22:0];
assign orwotoru = 

// 負の数を補数に変換
//代入先の引数名を変更　by 盛
add add(.Large_n(lar), .Small_n(sma), .bit_r(oror) .sum_rnd(res) )
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
