+++
date = "2018-03-19T22:45:39+09:00"
title = "Vim の f/t を Emacs で"
draft = false

+++

小ネタ。

今は Emacs をメインで使っているんだけど、もともとは長いこと Vim を使っていた。Vim を使っていた頃に重宝していたのが [f, t キー](http://vim-jp.org/vimdoc-ja/usr_03.html#03.3)なんだけど、Emacs にはそれと同じ機能を提供するコマンドが、デフォルトにはない。C-s, C-r が近いんだけど、これらはどちらかといえば Vim の /, ? に近く、f, t とはちょっと違う。重宝していただけに、ほしいなぁと思いつつ、C-s, C-r でだましだましやっていたんだけど、先日同僚と話している際に「一文字打ったら即座に `search-forward` する関数を作りゃいいのか」という、言ってしまえば当たり前のことに気づいて、重い腰をあげたのだった。

コードは以下。f, t, ; は再現したつもり。F, T はサポートしてないけど、ゴールをずらすだけなので、やろうと思えばかんたんだと思う。

```
(defvar *vim-ft-last-char*)

(defun %vim-ft (char f-or-t)
  (let ((forward (eq f-or-t 'f)))
    (unless char
      (if (eq last-command (if forward 'vim-f 'vim-t))
          (setq char *vim-ft-last-char*)
        (setq char (read-char "Character: "))))
    (setq *vim-ft-last-char* char)

    (let* ((search-fn (if forward 'search-forward 'search-backward))
           (bound-fn (if forward 'point-at-eol 'point-at-bol))
           (off (if forward 1 0))
           (p (save-excursion
                (forward-char off)
                (let ((ep (funcall bound-fn)))
                  (funcall search-fn (char-to-string char) ep nil)))))
      (when p
        (goto-char (if forward (1- p) p))))))

(defun vim-f (&optional char)
  (interactive)
  (%vim-ft char 'f))

(defun vim-t (&optional char)
  (interactive)
  (%vim-ft char 't))

(global-set-key (kbd "M-s") 'vim-f)
(global-set-key (kbd "M-r") 'vim-t)
```

`M-s` して何か文字を入力すると、同行内の次の「入力した文字」の位置にカーソルが移る。そのまま `M-s` を続けると、文字入力なしに同行内の次の「入力した文字」の位置にカーソルが移る。`vim-f` が f, ; を再現していて、`vim-t` が t, ; を再現している。

たぶん探せば同じようなことを実現するコード片なりパッケージなりがあるんだろうけど、Emacs Lisp の練習台にちょうどいい大きさのタスクだったので自前で実装した。
