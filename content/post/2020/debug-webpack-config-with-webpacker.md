+++
title = "webpacker が吐く webpack の設定を眺める"
draft = false
date = "2020-04-12T01:48:02+09:00"

+++

基本的には webpacker がデフォルトで用意する設定だけでやりくりするけど、たまに webpacker が吐く webpack 設定をいじりたくなるときがある。webpacker は webpack に薄い皮をかぶせているという特性上、webpacker の先にある webpack のことを想像しながらいじらないといけなくて、webpack を直接触る場合よりフラストレーションがたまる。webpacker が吐く webpack の設定を眺めながらいじれると、フラストレーションが少し緩和される。

node のワンライナーで、以下を叩くと webpacker が吐く webpack が出力される:

```
node -e 'console.dir((new (require("@rails/webpacker")).Environment).toWebpackConfig(), { depth: null })'
```

`console.dir` の第二引数がポイント。これがないと 2 階層目ぐらいまでしか出力されず、肝心のところが見えなかったりする。

https://nodejs.org/api/console.html#console_console_dir_obj_options
