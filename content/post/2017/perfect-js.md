+++
date = "2017-04-25T20:56:07+09:00"
title = "積読消化 - パーフェクト JavaScript"
draft = false

+++

積読消化、第二弾。パーフェクト JavaScript を読んだ。雰囲気で JavaScript を書いているのを、いい加減に是正したいという願いから、この本を手にしたことを覚えている。

---

本書は JavaScript の言語仕様から、(発売当時としては新しい分野だった) HTML5 で追加された API やサーバーサイド JavaScript まで、JavaScript に関するトピックを幅広く扱った本である。幅広く扱いつつも、ちょいちょいマニアックな話題にも触れてあり、広く浅い本とはまた違う。

言語仕様とクライアントサイド環境に関する節をしっかり読んだ。その他の、ライブラリ (jQuery)、HTML5、サーバーサイドに関する話題は、パラッと目を通すだけにとどめた。ライブラリと HTML5 は知ってる内容だったり都度調べれば済む話だし、サーバーサイド JS はあまり興味がない。また、HTML5 の章は、ApplicationCache API など現在では削除された API の解説も含まれている。致し方ないが、内容が古い面もある。

JavaScript の数値型は Number だけだというのは知っていたが、これが 64bit の浮動小数点型 (だけ) であることは知らなかった。整数を捨てている。Lua なんかがそんな設計だった気がする。

文字列型と文字列オブジェクト (new String で得るオブジェクト) が異なる型を持つことも知らなかった。Java のラッパー型と同じようなものだと解説されていたが、動的型付けで Box/Unbox が暗黙のうちに切り替わるのは、なんとも辛い。自分から文字列 (や数値、論理値) オブジェクトを積極的に使うことはないと思うが、罠にはまらないよう、知っておくことは決して損ではない。

不変オブジェクトを定義できるという点も新たな発見だった。`Object` の [preventExtensions](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Object/preventExtensions), [seal](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Object/seal), [freeze](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Object/freeze) の 3 つの関数によって提供される。動的型付けの言語は Python が初めてで、Java から本格的なプログラミングに入った身としては、なんでも変更できることに驚いた。動的型付けの言語は Python のように色んなものを動的に変えられるのが当たり前だと思っていて、JavaScript も基本的にはそれに漏れないと思うのだけど、逆に不変オブジェクトを定義できる方法が提供されているということに、考えすら至っていなかったのだった。

---

冒頭で述べたとおり、半分くらいは (ほぼ) 読み飛ばした。が、発見は色々とあった。雰囲気で JavaScript を書いているサーバーサイドプログラマーは、この手の本を一読して JavaScript の基本を抑えておくのもいいかもしれない。
