
## 進捗を出したら、プルリクエストを出してください

### やり方
* githubでこのリポジトリをforkする。
* forkした自分のリポジトリをcloneする
```
git clone https://github.com/<自分のgithub>/Floating_Point_Addr
cd Floating_Point_Addr
```
* 変更を加える
```
git commit -a -m "<ここにコメントを書く>"
git push origin master
```
* プルリクエストを作る
* 自分のリポジトリからPull Requestsボタンを押し、create new pull requestを押す

### テスト
```
xvlog --sv test_fadd.sv fpu.sv
xelab -debug typical test_fadd -s test_fadd.sim
xsim --runall test_fadd.sim 
```
