---
title: "添付ファイルだけ先にアップロードして、あとで関連付ける"
date: 2021-02-27T16:08:38+09:00
draft: false
---

ということをやりたくなることはありませんか？私はたまにあります。

コメントに画像を添付できるようなフォームがあったとして、画像を添付したら即サムネイルを表示したいとか。コメントを投稿する前に本文含めてプレビューを出したいとか。サーバーサイドで HTML を生成するアーキテクチャの場合、ファイルを先行してアップロードしておいて、サムネイルやプレビューをサーバーサイドで生成する形にすると、全体としてスッキリ作ることができます。

Rails の ActiveStorage はファイルの本体 (Blob) とその関連付け (Attachment) とが分かれて定義されていて、このタスクをこなすのにうってつけの構造だったりします。ActiveStorage を使わない場合は、これらに相当するモデルを自前で定義するのがいいんじゃないかな。

やり方としてはこんな感じ:

1. Blob だけ作るエンドポイントを用意
2. `<input type=file>` の変更を検知して、ファイルを単独でアップロード、Blob を生成
3. Blob の signed_id を hidden field に埋める

ActiveStorage には Direct Upload という仕組みがあって、それに近い動きではあります。一点違うのは、バックエンドのストレージに誰がアップロードするかという点。Direct Upload は js がストレージへのアップロードを担います。今回紹介するコードでは、サーバーサイドがストレージへのアップロードを担います。

こんなモデルがあったとして、

```
class Comment < ApplicationRecord
  has_one_attached :image
end
```

Blob 用のコントローラを用意して、

```
class BlobsController < ApplicationController
  def create
    file = params[:file]
    blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename)
    render json: { signed_id: blob.signed_id, url: url_for(blob) }
  end
end
```

view に `<input type=file>` を用意して、

```
<%= form_with(model: comment) do |form| %>
  <div class="field">
    <input type="file" class="js-image-upload">
  </div>
<% end %>
```

js でゴニョる:

```
const input = document.querySelector('.js-image-upload')
let img
input.addEventListener('change', () => {
  const [file] = input.files
  const csrfToken = Rails.csrfToken()

  const xhr = new XMLHttpRequest()
  xhr.open("POST", '/blobs', true)
  xhr.responseType = "json"
  xhr.setRequestHeader("X-CSRF-Token", csrfToken)

  xhr.addEventListener("load", event => requestDidLoad(event))
  xhr.addEventListener("error", event => requestDidError(event))

  const formdata = new FormData()
  formdata.append('file', file)
  xhr.send(formdata)

  function requestDidLoad(event) {
    const status = xhr.status
    if (status >= 200 && status < 300) {
      const { response } = xhr
      const { signed_id, url } = response
      setSignedId(signed_id)
      showImage(url)
    } else {
      requestDidError(event)
    }
  }

  function requestDidError(event) {
    console.error('request did error', event)
  }

  function setSignedId(signedId) {
    const hidden = document.createElement('input')
    hidden.type = 'hidden'
    hidden.name = 'comment[image]'
    hidden.value = signedId
    input.insertAdjacentElement('beforebegin', hidden)
  }

  function showImage(url) {
    if (!img) {
      img = document.createElement('img')
      img.width = '100'
      img.height = '100'
      input.insertAdjacentElement('beforebegin', img)
    }
    img.src = url
  }
})
```

js はちょっと冗長だけど、ライブラリをうまく使えばもっと短く書けると思います。エッセンスとしてはそんなに多くないはず。
`input.insertAdjacentElement('beforebegin', hidden)` してるのがミソで、これで複数回ファイルを選んでも最後に選んだファイルが有効になります。

あとオマケでアップロードしたファイルをサムネ表示しています（`showImage` のところ）。

ActiveStorage を使う場合はあらかじめ用意されているモデルを使うだけで済むので、かなり少ないコードで実現できてるんじゃないかと思います。
