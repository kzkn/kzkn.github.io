+++
title = "ThinkPad X1 Carbon 第6世代の BIOS をアップデートする"
draft = false
date = "2018-10-06T11:43:55+09:00"

+++

[X1 Carbon 6th gen about 50% slower on Linux](https://200ok.ch/posts/2018-09-26_X1_carbon_6th_gen_about_50_percent_slower_on_Linux.html) という記事を Twitter のタイムラインで流れているのを見つけた。記事によれば、「ThinkPad X1 Carbon 第6世代 (以下 X1C6) で Linux を走らせているなら、BIOS を最新化するだけで倍速くなる」ということらしい。

どういうことやねん？と思ってもう少し詳しく記事を読むと、温度の上限設定があがったことで CPU の周波数が抑制されにくくなったとのこと。CPU ヘビーな処理なら、それだけ速くなるよってことらしい。[BIOS の更新履歴](https://fwupd.org/lvfs/component/1023/all) にはそんなこと書いてないんだけどなぁ。他にも S3 Suspend がサポートされたとかいう更新もある。というわけで BIOS を更新してみたよ、という話。

更新は結構かんたんにできた。以下は Arch Linux での操作記録だけど、他のディストリでも同じような手順でできるんじゃないかと思う。

 1. [fwupd](https://wiki.archlinux.jp/index.php/Fwupd) をインストールする
 2. [ここ](https://github.com/fiji-flo/x1carbon2018s3#via-lvfs) に従って `fwupdmgr update` する
 3. マシンを再起動
 4. Boot Menu から「Linux Firmware Updater」を選択
    - BIOS 更新が適用される
 5. `fwupdmgr get-devices` で更新されたかどうか確認する

手元の環境では 0.1.12 が 0.1.30 になった。ずいぶんたまってたらしい。

さらに Linux 向けに最適化された Suspend (S3 Suspend のこと？よく分かってない) を有効するために、BIOS の設定を変える。[ここ](https://github.com/fiji-flo/x1carbon2018s3#discontinued-fixed-by-lenovo-in-new-firmware-release) の手順に従えば OK.

>  After flashing you will need to enable it under Setup → Config → Power then select Linux

正確には Power の「Sleep State」を Linux に選択する感じ。手元の環境では「Windows 10」になっていたのを「Linux」に変更した。

PC を閉じてしばらく放っておいたところ、バッテリーの持ちがかなり改善されてることを確認できた。32 時間ほどで 11% ほどの消費。もともとは数時間しか持たなかったことを考えると、すごい改善。X1C 初代では困ってなかったんだけど、X1C6 にしてからというもの、PC を閉じた状態でも結構バッテリーを食ってたのが気になっていた。改善して何より。
