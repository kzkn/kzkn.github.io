---
title: "gretel の開発の話"
date: 2021-12-11T16:21:15+09:00
draft: false
---

2020年8月ごろに [gretel](https://github.com/kzkn/gretel) という gem のメンテナーを引き継ぎました。お気に入りの gem だったんだけど、開発が[終わろうとしていた](https://github.com/kzkn/gretel/commit/0fc531bc30ecb3e23f273be36fae8c4d8393f2b1#diff-b335630551682c19a781afebcf4d07bf978fb1f8ac04c6bf87428ed5106870f5)のを見てメンテの引き継ぎを名乗り出てみたのでした。

今のところ活発に機能追加をしていくつもりはなく、Ruby や Rails のバージョン追従をしていくのを主軸にしています。安定的に使い続けられることを目的としています。CI を Travis CI から [GitHub Actions](https://github.com/kzkn/gretel/blob/9b7de7b7f7f5dd82c3975984d7fbee6d7102b5c2/.github/workflows/ci.yml) に[移行したり](https://github.com/kzkn/gretel/commit/cb6a0240732d453f26aa1e3bbb3870f9f274352f)とかもやりました。

とはいえちょっとずつ機能追加もしてます。[Bootstrap 4](https://github.com/kzkn/gretel/blob/master/CHANGELOG.md#version-400)の対応、[schema.org のマークアップへの対応](https://github.com/kzkn/gretel/blob/master/CHANGELOG.md#version-401)、[JSON-LD出力へのの対応](https://github.com/kzkn/gretel/blob/master/CHANGELOG.md#version-420)とかとか。

で、今日もちょっと開発したので、そのメモ書き。

`link_class` オプションを[追加した](https://github.com/kzkn/gretel/pull/32)。これは[オリジナルリポジトリ](https://github.com/lassebunk/gretel)時代から issue としてあがっていた [#10](https://github.com/kzkn/gretel/issues/10) への対応です。`pretext_class`, `posttext_class` とかはあるので、まぁリンクへのオプションがあってもよいなと判断して実装しました。

renderer.rb の実装を[リファクタした](https://github.com/kzkn/gretel/pull/33)。オプションが増えたり schema.org マークアップへの対応が入ったりでなかなかのカオスっぷりだったのが前から気になっていたので、気合を入れて作りを整理しました。

セマンティックなマークアップを生成する実装と、そうでないマークアップを生成する実装のクラスを分割。共通するマークアップは親クラスでレンダリングするように、という感じ。前よりは多少見通しがよくなった、と思う。

gretel のコードカバレッジは 100% をキープしてます。メンテを引き継いだあとで [100% にしました](https://github.com/kzkn/gretel/blob/9b7de7b7f7f5dd82c3975984d7fbee6d7102b5c2/coverage/coverage.txt)。メンテを引き継いだ当時からカバレッジはかなり高くて、最後の数%を俺が詰めたという感じ。その後はカバレッジが100%でないとテストが[コケるように設定](https://github.com/kzkn/gretel/blob/9b7de7b7f7f5dd82c3975984d7fbee6d7102b5c2/spec/rails_helper.rb#L12)しています。これがあるおかげで、リファクタはかなりやりやすいし、安心感があります。月並みですが、テストコードは大事だなと思う次第です。

特にオチとか結論はない、近況報告でした。
