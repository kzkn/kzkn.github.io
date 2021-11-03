---
title: "Re: JavaScript Test Code Coverage in Rails"
date: 2021-11-03T15:26:46+09:00
draft: false
---

[JavaScript Test Code Coverage in Rails](https://www.fastruby.io/blog/rails/javascript/code-coverage/js-code-coverage-in-rails.html) への一方的な返信記事です。

[jscov](https://github.com/kzkn/jscov) を使うといいよ。

---

だけじゃアレなのでもう少し詳しく。

くだんの記事は、タイトルの通り Rails のテストで JavaScript コードのカバレッジもとろうぜという内容です。JavaScript のカバレッジ計測には [istanbul](https://github.com/istanbuljs/nyc) を使っていて、それと rspec, capybara, selenium などと組み合わせることによるカバレッジの収集方法を紹介しています。無事にカバレッジの収集に至り、サンプルプロジェクトも[公開](https://github.com/fastruby/js-coverage-sample-app)されています。素晴らしい。

無事にできたね、チャンチャン、といきたいところなんだけど、ひとつ大きな落とし穴があります。一つのテストの中で複数回の `visit` や `click_link` などによるページ遷移を行うと、カバレッジデータが消えてしまうのです。istanbul は `window.__coverage__` にカバレッジデータを収集する仕組みなので、ページロードが挟まると当然ながらデータはクリアされてしまいます。

この問題に対する包括的な解決策は、記事内では触れられていません。曰く、エッジケースが多すぎるとのこと。まぁそうかもね。

---

で、冒頭で触れた [jscov](https://github.com/kzkn/jscov) という gem です。この gem を使うとページ遷移にまつわる問題を解決できます。

jscov は [Rack Middleware](https://github.com/kzkn/jscov/blob/babf18e900d06cb832e5b778464d010af196f8c2/lib/jscov/rack_middleware.rb) を内包しています。jscov の Rack Middleware を使うと、unload 時に `window.__coverage__` を `console.log` に出力するという [JavaScript コード](https://github.com/kzkn/jscov/blob/babf18e900d06cb832e5b778464d010af196f8c2/lib/jscov/bless.rb#L56)をレスポンスの HTML に[ねじ込みます](https://github.com/kzkn/jscov/blob/babf18e900d06cb832e5b778464d010af196f8c2/lib/jscov/bless.rb#L43)。
selenium では `console.log` の取得を明示的に行わない限りログをためていってくれます。なので、rspec の after などでページ遷移ごとに出力された `console.log` の内容を[収集して保存](https://github.com/kzkn/jscov/blob/master/lib/jscov.rb#L24)します。保存したカバレッジデータからのレポート出力には [nyc]((https://github.com/istanbuljs/nyc)) を使います。

セットアップは[面倒くさい](https://github.com/kzkn/jscov/blob/master/README.md)ですが、JavaScript コードのカバレッジも集めたいんだって向きには役立つツールになってるんじゃないかと思います。
