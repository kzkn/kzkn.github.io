---
title: "最初にぼやけた画像を表示して、あとできれいな画像を表示するやつ"
date: 2021-02-27T15:44:40+09:00
draft: false
---

画像の読み込みが遅いのをごまかすテクニックの紹介。こんな動きをするやつです:

1. 解像度の低いもやっとした軽量版の画像をあらかじめ表示
2. 解像度の高いきれいな画像をロードできたタイミングで置き換え

私の初見は [medium.com](https://medium.com/) でした。今は他のサイトでも使われてるのを見ます。

ちゃんと名前があって、["Blur Up"](https://css-tricks.com/the-blur-up-technique-for-loading-background-images/) というそうです。知りませんでした。

複数の画像を用意しなきゃいけないけれど、Rails の ActiveStorage なんかを使えば、そこはわりとかんたんにクリアできます。js 側も、作ってみると結構かんたんでした（こだわらなければ）。

こんなモデルがあったとして、

```
class Comment < ApplicationRecord
  has_one_attached :image
end
```

こんなヘルパーを用意して、

```
def blur_up_image_tag(comment, width:, height:)
  image_tag low_quality_image(comment), data: { high_src: url_for(high_quality_image(comment)) },
    class: 'js-blur-up', width: width, height: height
end

def low_quality_image(comment)
  comment.image.variant(resize_to_limit: [100, 100], saver: { quality: 10 })
end

def high_quality_image(comment)
  comment.image.variant(resize_to_limit: [800, 800], saver: { quality: 90 })
end
```

erb からヘルパーを叩いて、

```
<%= blur_up_image_tag(@comment, width: 500, height: 320) %>
```

js でゴニョります。

```
for (const img of document.querySelectorAll('.js-blur-up')) {
  img.style.filter = 'blur(20px)'

  const high = new Image()
  high.onload = () => {
    img.style.filter = 'none'
    img.style.transition = 'filter .1s ease-out'
    img.src = high.src
  }

  high.src = img.dataset.highSrc
}
```

`low_quality_image` は画像のサイズも小さければ、JPEG の品質も低めに設定しています。画像にもよるけど、試しに使ってたものだと 3kb 弱でした。これなら一瞬でロードできそうですよね。引き伸ばしてそのまま表示すると、まともに見れたものではありません。そこで CSS の `filter` でぼやかしてやります。

`high_quality_image` はサイズも品質も高めに設定しています。この画像をロードしたタイミングで、画面上の画像を置き換えつつ、ぼやかし用の `filter` を解除してやります。解除時にちょっとアニメーションを入れてやることで、かっこよくなります。このへんは好みということで。
