+++
title = "webpacker で dart-sass を使う"
draft = false
date = "2020-04-12T01:54:22+09:00"

+++

webpacker はデフォルトの状態だと dart-sass ではなく node-sass を使う。一方で `@use` などの新しい構文は dart-sass にしか実装されておらず、node-sass (libsass) での実装予定はない様子 (?)。
sass-loader の README などを参考にしつつ、webpacker で使えるようにしてみた。

何はともあれ dart-sass をインストールする。fibers というパッケージも入れておくと[パフォーマンス上のメリットがあるらしい](https://github.com/sass/dart-sass/tree/bf35513a4cdb5b0d4e86309211735bdbddd938a0#javascript-api)のでおとなしく従っておく。

```
yarn add sass fibers
```

`assets:precompile` では dependencies だけがインストールされるので `yarn add -D` ではなく `yarn add` なのが注意点。

webpacker の設定を変える。

```js
// config/webpack/environment.js
const { environment } = require('@rails/webpacker')

const sassLoader = environment.loaders.get('sass')['use'].find(rule => rule['loader'] === 'sass-loader')
sassLoader.options = {
  ...sassLoader.options,
  implementation: require('sass'),
}

module.exports = environment
```

要は sass-loader の設定の `options` を書き換えて、`implementation` に `require('sass')` を入れるようにしている。[sass-loader の README](https://github.com/webpack-contrib/sass-loader/tree/3ad529157d1bcff1905be19dd18d0192bc89f29a#implementation) に従っている感じ。もっとうまい書き方がありそうな気もする。

fiber に関しては [sass-loader が勝手に解決する](https://github.com/webpack-contrib/sass-loader/blob/master/CHANGELOG.md#800-2019-08-29)ようになっていて、(おそらく) インストールだけしておけば設定なしにうまいこと使ってくれる。

これらを設定したあと sass ファイルで `@use` を使ってみるとうまく動いたので、ちゃんと動いてそうな雰囲気。
