---
title: "bundle open を Emacs の中でやる"
date: 2021-03-13T13:14:17+09:00
draft: false
---

最近書いた Emacs の小物の紹介です。

`bundle open` というコマンドがあります。引数に gem の名前を渡すと、環境変数 `BUNDLER_EDITOR` で gem のディレクトリを開いてくれるコマンドです。gem の中に潜っていくときに役立ちます。

はじめは `BUNDLER_EDITOR` に `emacsclient -nw` を設定して使っていたんだけど、Emacs の中で完結したいってことで、一つ関数をこさえました。

```
(defun bundle-open (gem-name)
  (interactive
   (let* ((gems (shell-command-to-string "bundle list --name-only"))
          (candidates (split-string gems "\n" t)))
     (list (ido-completing-read "Gem: " candidates))))
  (find-file (s-chomp (shell-command-to-string (concat "bundle info " gem-name " --path")))))
```

`bundle list --name-only` で現在のプロジェクトの Gemfile.lock にある gem を列挙してくれます。それをリスト化して、`ido-completing-read` で補完しつつ選択します。
gem のディレクトリパスは `bundler info GEMNAME --path` で拾ってくることができます。あとはこれを `find-file` に渡してしまえば終わり。

私は今のところ困っていませんが、Gemfile.lock にない gem も指定できるようにするオプションがあってもいいかもしれませんね。
