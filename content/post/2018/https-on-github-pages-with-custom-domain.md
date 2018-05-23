+++
title = "カスタムドメインな Github Pages を HTTPS 化 (正式サポート版)"
draft = false
date = "2018-05-23T23:24:14+09:00"

+++

Github Pages でカスタムドメインの HTTPS 配信が[サポートされるようになった](https://blog.github.com/2018-05-01-github-pages-custom-domains-https/)。早速このサイトでも適用した。ちょっと手こずったので、対処の手順を綴っておきたい。なお、言うまでもないけど、確実な方法を知りたければ[公式サイト](https://help.github.com/articles/using-a-custom-domain-with-github-pages/)をあたってほしい。

## 1. ALIAS レコードを設定する ##

もともと kazkn.com ドメインには A レコードと CNAME レコードを設定していた。[公式の解説](https://help.github.com/articles/setting-up-an-apex-domain/)によれば example.com のような apex domain (サブドメインのついてないドメインをそう呼ぶらしい) は ALIAS, ANAME, A レコードのいずれかを設定しなければならない、ということだったので、修正にあたった。幸い使っていた DNS サーバーでは ALIAS レコードをサポートしていたので、[ALIAS レコードを設定した](https://help.github.com/articles/setting-up-an-apex-domain/#configuring-an-alias-or-aname-record-with-your-dns-provider)。

```
ALIAS kzkn.github.io
```

A レコード、CNAME レコードの古い設定はすべて削除して、ALIAS レコードの設定だけを残した。

## 2. Custom Domain を再設定する ##

ここにちょっとハマった。ただ[公式の解説](https://help.github.com/articles/setting-up-an-apex-domain/#configuring-an-alias-or-aname-record-with-your-dns-provider)にはちゃんと記述があるので、見逃していた俺が悪い。

> If you're updating an existing custom domain, first remove and then re-add your custom domain to your GitHub account to trigger the process of enabling HTTPS.

リポジトリの Settings で Custom Domain の設定を一回空白にして Save, 改めて入力して Save, という手続きを踏んだ。

## 3. 待つ ##

ここまでやると Enforce HTTPS のチェックボックスの欄に「今 Let's Encrypt にリクエスト投げてるからちょっと待っとけ」的なメッセージが出る。24 hours とか書いてあったと思うけど、実際にはほんの数分で終わっていた。終わると勝手に Enforce HTTPS にチェックが入った状態になっている。カスタムドメインに HTTPS でアクセスできれば成功。

---

HTTPS 化自体は公式のサポートがなくとも外部サービスを使うことで実現できたのだけど、そこまでやるメリットも感じられなかったし、放っておいたのだった。しかし HTTP に対する風当たりが強くなってる現実もあって、できるならしたい、でもコストはかけたくない、とも思っていた。というところに公式のサポートが出てきたので、飛びついたのだった。かんたんだしランニングコストがかかるわけでもないので、やっておくに越したことはないと思う。
