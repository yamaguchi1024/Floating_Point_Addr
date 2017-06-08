
## 進捗を出したらそのままpushしてください

### やり方
* githubでこのリポジトリをcloneする。
```
git clone https://github.com/<自分のgithub>/Floating_Point_Addr
cd Floating_Point_Addr
```
* 変更を加える
```
git commit -a -m "<ここにコメントを書く>"
git push origin master
```

### テスト
```
xvlog --sv test_fadd.sv fpu.sv
xelab -debug typical test_fadd -s test_fadd.sim
xsim --runall test_fadd.sim 
```
