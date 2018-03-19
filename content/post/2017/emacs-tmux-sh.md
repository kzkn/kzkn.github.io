+++
date = "2017-12-12T00:00:00+09:00"
title = "tmux のキャプチャ機能を使った emacs とシェルの連携"
draft = false

+++

この記事は [Emacs Advent Calendar 2017](https://qiita.com/advent-calendar/2017/emacs) の 12 日目の記事です。

Emacs とシェルを連携させたいとき主に `M-x shell` を使っていたが、最近は tmux 上で起動したシェルを使うようになった。`M-x shell` を使う主な理由は、シェルの出力を Emacs でいじりたい (主にヤンクしたい) ということ。しかしそのために微妙に操作感の違う `M-x shell` をだましだまし使い続けるのも後ろめたい。普段使いで慣れているふつうのターミナルでシェルを使いつつ Emacs と連携できるならそれに越したことはない。

tmux のキャプチャ機能を使うことで容易にこれが達成できる。アイデアは [こちら](http://emacs.rubikitch.com/zsh-fish-emacs-eshell/) で紹介されていたもので、それを手元で実装した。本稿はそんな小ネタ的なお話。

---

流れはこんな感じ:

 1. Emacs から `tmux new-window` で `default-directory` をカレントディレクトリとしたウィンドウを起動する
 2. そのウィンドウで適当な操作を行う
 3. キャプチャしたい内容が出力された時点で `tmux capture-pane` でキャプチャしてファイルに書き出す
 4. 書き出したファイルを Emacs で開く

Emacs とシェルにちょろっと設定を書くだけで実現できる。

```lisp
(defun sh (&optional arg)
  (interactive "P")
  (let* ((start-directory (if arg
                              (ido-read-directory-name "Starting directory: " default-directory)
                            default-directory))
         (tmux (executable-find "tmux"))
         (command (format "%s new-window -c %s" tmux start-directory)))
    (call-process-shell-command command)))
```

[ido](https://www.emacswiki.org/emacs/InteractivelyDoThings) を使いたくなければ `ido-read-directory-name` ではなく `read-directory-name` を使うといい。

シェル (筆者は zsh を使っているが、他のシェルにも簡単に移植できるはず) には以下の設定を追加する。`alias` はお好みで。

```sh
alias e=emacsclient

function _do_tmux_capture {
  dir="$HOME/tmp/capture"
  if [ -n "$1" ]; then
    out="$dir/$1"
  else
    out=`mktemp -u --tmpdir=$dir`
  fi
  shift
  mkdir -p "$dir"
  tmux capture-pane "$@" >"$out"
  echo "$out"
}

function cap { _do_tmux_capture "$1" -p }
function caph { _do_tmux_capture "$1" -pS -32768 }
```

こんな感じで使う:

```sh
$ tmux
$ emacs -nw
# emacs 上で M-x sh
# 制御が新しいウィンドウに移る
$ ls -l
合計 92
-rw-r--r-- 1 kzkn kzkn  8728  6月 30 18:58 #%2Ascratch%2A#191002Nn#
-rw-r--r-- 1 kzkn kzkn  8728  6月 27 21:58 #%2Ascratch%2A#29651XUl#
-rw-r--r-- 1 kzkn kzkn 14232  9月 22 06:41 #%2Ascratch%2A#31070eMR#
-rw-r--r-- 1 kzkn kzkn  8728  6月 27 21:46 #%2Ascratch%2A#3308PVn#
-rw-r--r-- 1 kzkn kzkn   176  9月 22 06:42 README.md
drwxr-xr-x 2 kzkn kzkn  4096  2月 22  2017 archetypes
$ e `cap`
# tmux の <prefix> l (筆者の環境なら C-t l) で Emacs に戻るとキャプチャした内容が Emacs 上に開かれている
```

`cap` と `caph` はキャプチャ内容を出力したファイルのパスを出力するので、これを `emacsclient` に食わせれば Emacs 上でキャプチャ内容を開いていじれるという寸法。Emacs で編集なりなんなりしたあとは、バッファを殺すなり `C-x #` なりすれば `emacsclient` が死ぬ。シェルは適当なタイミングで殺すといい。

ここでは `emacs -nw` として非 GUI な Emacs を使っている。非 GUI な Emacs であれば `M-x sh` した時点で新しい tmux ウィンドウにフォーカスが移るので、今回紹介した連携方法においては都合がいい。GUI な Emacs を使う場合は Alt-Tab などでターミナルのウィンドウ (ここでいうウィンドウは GUI 環境のウィンドウ) に切り替えなければならず、ちょっと面倒くさい。筆者はこれのためだけに GUI な Emacs から非 GUI な Emacs に移行した。
