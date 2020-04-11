+++
title = "xmonad --recompile でエラーが出るようになったら"
draft = false
date = "2020-04-06T00:04:38+09:00"

+++

毎週末恒例の `yay` を実施したところ、これまた恒例の `yay` 直後に実施する `xmonad --recompile` でエラーを吐くようになってしまった。ghc が更新されていたのでそれ関係だとは思うが、結局根本原因は分からず、ひとまずは（これまた恒例の）`yay` 後のマシン再起動はやめておいた。xmonad が起動しないので。

困ったなと思いつつ、ふと Twitter を xmonad で検索してみたら、以下のような投稿が。

https://twitter.com/wat_aro/status/1248888372635922438

手元の環境では `sudo` が必要で、`sudo ghc-pkg recache` したところ `xmonad --recompile` も通るようになった。ちゃんちゃん。
