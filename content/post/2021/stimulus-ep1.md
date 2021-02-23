---
title: "Stimulus と Rails UJS を組み合わせて簡易版 Hotwire"
date: 2021-02-23T14:53:28+09:00
draft: false
---

[Hotwire](https://hotwire.dev/) の登場により下火になることが約束されていると言っても過言ではない (要出典) [Rails UJS](https://github.com/rails/rails/tree/main/actionview/app/assets/javascripts) ですが、Hotwire (の Turbo) が beta 版な現状においては、Rails UJS を使って `<%= link_to hoge, remote: true %>` なコードを書く機会は、まだまだあるんじゃないかと思います。

Rails UJS の remote 機能は画面遷移なしにリクエスト飛ばす方法として極めて気軽に使えます。個人的にとても気に入っています。その応答で画面に変化をつけるには Server Generated JavaScript Response (SJR) を使うのが、一般的な方法の一つです。しかし SJR はテンプレートエンジンを使って動的に JavaScript を生成するという仕組みから、コードが難解になりやすく、新しいコードではできるだけ避けたい手法ではないでしょうか。

かといってサーバーから JSON を返して JavaScript でハンドリングするのは面倒くさいし、remote 機能の手軽さは捨てたくない。そこで使えるのが [Stimulus](https://stimulus.hotwire.dev/) です。前置きが長くなった。

ざっくりこんな感じ:

- remote リクエストの応答に HTML を返す
- 返ってきた HTML で画面を部分更新

これだけです。発想は Hotwire のそれに近い。というかほぼ同じで、Turbo を使うか、Rails UJS と Stimulus で自前実装するかの違いってぐらいです。もちろん Turbo のほうが高機能だけど。

実装はこんな感じ:

```
# app/controllers/greetings_controller.rb
class GreetingsController < ApplicationController
  def show
    render layout: nil
  end
end
```

```
<div id="replace-here"></div>
<%= link_to 'click here', '/greeting', remote: true, data: { controller: 'remote', remote_target_value: '#replace-here', action: 'ajax:success->remote#replace' }
%>
```

```
<%# greetings/show.html.erb %>
<div>Hello!</div>
```

```
// remote_controller.js
export default class extends Controller {
  static values = { target: String }

  replace(event) {
    const { detail: [, , xhr] } = event
    this.targetElement.outerHTML = xhr.responseText
  }
  
  get targetElement() {
    return document.querySelector(this.targetValue)
  }
}
```

`data: { ... }` のところが長ったらしくてダサいのがちょっとネック。けど Rails UJS を使える点、SJR を避けられる点など、得られるメリットを考えると、まぁ目を瞑ってやれるんじゃないでしょうか。私は瞑れます。

サーバーから返ってくる HTML の処理方法としては `replace` 以外にも `append`, `prepend`, `remove` とかのバリエーションがあってもいいですね。今回は `link_to` で使ったけど Rails UJS のイベントが拾えるなら使えます。`form_with` とか。あとは `data-remote-target-value` を必須にしてるけど、これを任意にして、未設定なら `this.element` を `targetElement` の戻り値にするなんていうバリエーションがあってもよさそうです。

データを変更するエンドポイントに対する要求への応答には、「登録しました」みたいな通知メッセージを出したくなるんじゃないでしょうか。それにも使えます。応答の中に通知メッセージを含む `<template>` を埋めておいて、`<template>` 経由でメッセージを表示する感じです。

例えば [toastr](https://www.npmjs.com/package/toastr) を使う場合だとこんな感じ:

```
class GreetingsController < ApplicationController
  def create
    render layout: nil
  end
end
```

```
<div id="replace-here"></div>
<%= link_to 'click here', '/greeting', remote: true, method: :post, data: { controller: 'remote', remote_target_value: '#replace-here', action: 'ajax:success->remote#replace' } %>
```

```
<%# greetings/create.html.erb %>
<div>Created</div>
<template data-controller="notice">
  Succeeded!
</template>
```

```
// notice_controller.js
export default class extends Controller {
  connect() {
    toastr.success(this.element.textContent)
  }
}
```

`create.html.erb` の内容で `#replace-here` が置き換えられます。そのタイミングで `<template>` が DOM ツリーにアタッチされ、notice コントローラの `connect` が発火します。で、`toastr.success` が呼ばれて無事にメッセージが表示される。`<template>` 自体は画面に見えないので、こういうテクニックが使えます。

画面の複数ヶ所に変化をつけたい場合も、`<template>` と Stimulus を工夫して使えば実現することができます。Turbo だと Turbo Stream でやってるようなやつを、簡易的に自前実装する感じ。

今回紹介した Rails UJS の remote 機能と Stimulus の連携は [stimulus-remote](https://www.npmjs.com/package/stimulus-remote) としてパッケージ化されています。こちらを使うでもいいですね。

あまり脚光を浴びることのない Stimulus だけど、十分役に立つよということで、ささやかながら1つの例を紹介しました。
