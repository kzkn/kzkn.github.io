+++
draft = false
date = "2017-05-25T22:04:21+09:00"
title = "bash と ffmpeg でハマった話"

+++

とてもハマった。一応解決には至ったので、記録を残しておくことにする。

---

mp4 から png を抽出するスクリプトを bash と ffmpeg を使って書いていた。処理対象のファイルは外部のコマンドから得られるので、それを `while read` で回して ffmpeg に食わせるという、しごくかんたんなもの。

```
#!/bin/bash

print_mp4_files | while read f
do
  ffmpeg -loglevel error -i "${f}" -f image2 -vcodec png -r 1 "%03d.png"
done
```

ところがこれが動作しない。一行目しか処理されないのだ。また、処理対象のファイルが変わると、壊れたファイルとして扱われたり、`f` に不正なファイル名が入ったりすることもあり、極めて不可解な挙動になる。

結論からいうと、ffmpeg に `</dev/null` を足せば解決する。

```
#!/bin/bash

print_mp4_files | while read f
do
  ffmpeg -loglevel error -i "${f}" -f image2 -vcodec png -r 1 "%03d.png" </dev/null
done
```

---

なぜこんなことになるのか。[Stack Overflow](https://unix.stackexchange.com/questions/36310/strange-errors-when-using-ffmpeg-in-a-loop) や [BashFAQ](http://mywiki.wooledge.org/BashFAQ/089) に解説が見つかった。

ffmpeg は stdin を読むプログラムである。実際、ffmpeg の実行中に "q" と入力すると、処理が中断され、プロセスも終了する。bash では、子プロセスの stdin は親プロセスの stdin を継承するようになっており、`read` で読むはずの「次のファイル」が ffmpeg によって食われてしまい、謎の挙動を生んでいる。よって `</dev/null` を足すことで、ffmpeg プロセス (子プロセス) が bash プロセス (親プロセス) の stdin を継承しないようになり、問題を回避できる。

少し実験してみた。まず、stdin から `fgetc` して `printf` するだけのかんたんなプログラム getc.c を用意する。

```
#include <stdio.h>

int main() {
  int c = fgetc(stdin);
  printf("getc: %c\n", c);
  return 0;
}
```

コンパイルする。

```
$ gcc -o getc getc.c
```

スクリプトを書き換える。

```
#!/bin/bash

while read f
do
  echo "sh: $f"
  ./getc
done <<EOF
10
20
30
EOF
```

実行してみる:

```
$ ./stdin.sh
sh: 10
getc: 2
```

`read` が stdin から読んだ一行目 "10" が `f` に入る。その後実行した getc により、stdin から次の文字 "2" が出力される。親プロセスと子プロセスの stdin がつながっている様子が分かる。

残りの入力 "0\n30\n" がなぜ消費されないのか、謎は残る。サブプロセスが終了するタイミングで stdin を閉じてしまい、それにつられて親プロセスの stdin まで閉じてしまっているとか、そういうことだろうか。別の機会にもう少し調べてみたい。

---

残った謎について調べた。結論から言うと、↑の見解は完全に間違いで、getc.c の `fgetc` によって stdin の内容が全部読み取られることで、次の `read` で EOF を検出している。

検証用に stdin.sh を次のように改造する:

```
#!/bin/bash

prog="$1"
while read f
do
  echo "sh: $f"
  ./"${prog}"
done <<EOF
10xyz
20xyz
30xyz
EOF
```

`while` に食わせる入力値をちょっと派手にしたのと、起動するプログラムを外部から指定するようにしたのと、2 点の修正を加えている。

まずは先ほどの getc.c を使って動かす。システムコールの動きが見たいので、strace に食わせる。

```
$ strace -f -eread,lseek ./stdin.sh getc
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\320\303\0\0\0\0\0\0"..., 832) = 832
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\320\16\0\0\0\0\0\0"..., 832) = 832
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P \2\0\0\0\0\0"..., 832) = 832
read(3, "MemTotal:        7870540 kB\nMemF"..., 1024) = 1024
lseek(3, 0, SEEK_CUR)                   = 0
read(3, "#!/bin/bash\n\nprog=\"$1\"\nwhile rea"..., 80) = 80
lseek(3, 0, SEEK_SET)                   = 0
lseek(255, 0, SEEK_CUR)                 = 0
read(255, "#!/bin/bash\n\nprog=\"$1\"\nwhile rea"..., 102) = 102
lseek(4, 0, SEEK_CUR)                   = 0
lseek(0, 0, SEEK_CUR)                   = 0
read(0, "10xyz\n20xyz\n30xyz\n", 128)   = 18
lseek(0, -12, SEEK_CUR)                 = 6
sh: 10xyz
Process 4800 attached
[pid  4800] read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P \2\0\0\0\0\0"..., 832) = 832
[pid  4800] read(0, "20xyz\n30xyz\n", 4096) = 12
getc: 2
[pid  4800] +++ exited with 0 +++
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=4800, si_status=0, si_utime=0, si_stime=0} ---
lseek(0, 0, SEEK_CUR)                   = 18
read(0, "", 128)                        = 0
read(255, "", 102)                      = 0
+++ exited with 0 +++
```

stdin.sh から fork した子プロセス (pid=4800, ./getc のこと) で 4096 バイトも read(2) していることが伺える。`fgetc` の戻り値は 1 文字だけだが、libc 内部にはそれ以上の内容をバッファリングするので、このような動作になっている。当然 stdin の最後まで読み込まれるので、stdin.sh における次の read(1) では読み込む内容がなく (= EOF)、プログラムは終了する。

よく見ると親プロセス (= stdin.sh) でも

```
read(0, "10xyz\n20xyz\n30xyz\n", 128)   = 18
```

こんなことをやっている。しかしその直後に 1 行分だけ読んだことにするための `lseek` が入っているので、`fgetc` によるバッファリングのような問題は起きない。

では、`fgetc` ではなく read(2) を使ってみるとどうか。次のような read.c を用意する。

```
#include <unistd.h>
#include <stdio.h>

int main() {
  int c;
  read(0, &c, 1);
  printf("read: %c\n", c);
  return 0;
}
```

コンパイルして、まずは strace なしで動かす。

```
$ gcc -o read read.c
$ ./stdin.sh read
sh: 10xyz
read: 2
sh: 0xyz
read: 3
sh: 0xyz
read: 
```

すべての内容が出力されるようになった。これは read(2) を直接使うことで、確実に 1 バイトしか消費しないように制御を変更したため。一応 strace の内容も確認しておく。

```
$ strace -f -eread,lseek ./stdin.sh read
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\320\303\0\0\0\0\0\0"..., 832) = 832
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\320\16\0\0\0\0\0\0"..., 832) = 832
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P \2\0\0\0\0\0"..., 832) = 832
read(3, "MemTotal:        7870540 kB\nMemF"..., 1024) = 1024
lseek(3, 0, SEEK_CUR)                   = 0
read(3, "#!/bin/bash\n\nprog=\"$1\"\nwhile rea"..., 80) = 80
lseek(3, 0, SEEK_SET)                   = 0
lseek(255, 0, SEEK_CUR)                 = 0
read(255, "#!/bin/bash\n\nprog=\"$1\"\nwhile rea"..., 102) = 102
lseek(4, 0, SEEK_CUR)                   = 0
lseek(0, 0, SEEK_CUR)                   = 0
read(0, "10xyz\n20xyz\n30xyz\n", 128)   = 18
lseek(0, -12, SEEK_CUR)                 = 6
sh: 10xyz
Process 4775 attached
[pid  4775] read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P \2\0\0\0\0\0"..., 832) = 832
[pid  4775] read(0, "2", 1)             = 1
read: 2
[pid  4775] +++ exited with 0 +++
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=4775, si_status=0, si_utime=0, si_stime=0} ---
lseek(0, 0, SEEK_CUR)                   = 7
read(0, "0xyz\n30xyz\n", 128)           = 11
lseek(0, -6, SEEK_CUR)                  = 12
sh: 0xyz
Process 4776 attached
[pid  4776] read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P \2\0\0\0\0\0"..., 832) = 832
[pid  4776] read(0, "3", 1)             = 1
read: 3
[pid  4776] +++ exited with 0 +++
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=4776, si_status=0, si_utime=0, si_stime=0} ---
lseek(0, 0, SEEK_CUR)                   = 13
read(0, "0xyz\n", 128)                  = 5
sh: 0xyz
Process 4777 attached
[pid  4777] read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P \2\0\0\0\0\0"..., 832) = 832
[pid  4777] read(0, "", 1)              = 0
read: 
[pid  4777] +++ exited with 0 +++
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=4777, si_status=0, si_utime=0, si_stime=0} ---
lseek(0, 0, SEEK_CUR)                   = 18
read(0, "", 128)                        = 0
read(255, "", 102)                      = 0
+++ exited with 0 +++
```

思ったとおりに動いているっぽい。

---

`fgetc` でもバッファリングするという動作は、言われてみれば「あぁ、確かに」となるのだけど、1 文字しか返さないという関数の仕様上、考えからすっかり抜けてしまっていた。ふと strace の存在を思い出して調べてみたところ、read(2) の使われ方が思ったのと違い、バッファリングの存在を思い出したのだった。先入観はよくない。また、調査のためのツールは色々使えるようになっておくに越したことはない。strace をちゃんと使ったのは初めてだったかもしれない。
