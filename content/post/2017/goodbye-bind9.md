+++
date = "2017-02-22T22:26:27+09:00"
title = "Goodbye BIND9"
draft = false

+++

[BIND9 の脆弱性報告](https://www.cvedetails.com/product/144/ISC-Bind.html?vendor_id=64) にもいい加減うんざりしてきた。今年 (2017 年) に入ってからも、2 月 21 日現在ですでに [3 件](https://www.cvedetails.com/cve/CVE-2016-9131/) の[脆弱性が](https://www.cvedetails.com/cve/CVE-2016-9147/) [報告されている](https://www.cvedetails.com/cve/CVE-2016-9444/)。

そこで BIND9 からの卒業を考える。新たな仲間は [NSD](https://www.nlnetlabs.nl/projects/nsd/) と [Unbound](https://www.nlnetlabs.nl/projects/unbound/) だ。NSD も Unbound も、BIND9 に比べて脆弱性の報告が[ずっと](https://www.cvedetails.com/product/17420/Nlnetlabs-NSD.html?vendor_id=9613) [少ない](https://www.cvedetails.com/product/20882/Nlnetlabs-Unbound.html?vendor_id=9613)。BIND9 の設定にもうんざりしている。NSD, Unbound は設定も簡潔に見える。とにかく BIND9 には数多のフラストレーションを抱えており、隣の芝は青く見えるというもので、NSD, Unbound に逃げようという趣旨だ。

BIND9 は広く普及していて、その意味では偉大なソフトウェアのひとつであることは間違いない。古くからインターネットを支えてきた、重要なソフトウェアのひとつだろう。その一方で BIND9 は複雑化する DNS の仕様を古くから実装してきたからか、その実装もまた複雑怪奇になっていると聞く。脆弱性が報告されるのも仕方がない。そろそろ BIND9 を楽にしてやってもいいのではないだろうか。

余談だが、最近は [BIND9 をリファクタリングしよう](https://www.isc.org/blogs/bind-9-refactoring/) という向きもあるらしい。


# BIND9 vs NSD, Unbound #

詳しい説明は他に譲るとして、DNS サーバーの役割と BIND9, NSD, Unbound の関係について、かんたんに触れておく。

DNS サーバーには **権威サーバー** という役割と **キャッシュサーバー** という大きく 2 つの役割がある。NSD は権威サーバーの実装、Unbound はキャッシュサーバーの実装である。BIND9 は両方の実装である。

BIND9 の使い方にもよるが、基本的には BIND9 でやっていたことを役割ごとに NSD と Unbound に分割してやる必要がある。

# BIND9 から NSD へ #

一言で言えば、zone ファイルを NSD へ移行する。zone ファイル自体は RFC 1305 で標準化されており、可搬性があるので、BIND9 で使っていたものをそのまま使いまわすことができる。

以下は BIND9 の設定を NSD の設定に書きなおしたものだ:

```
// BIND9 named.conf

options {
  listen-on port 53 { 127.0.0.1; };
  listen-on-v6 port 53 { ::1; };
  version     "unknown";
  // snip
};

view "internal" {
  match-clients { localhost; foobar-network; };
  match-destinations { localhost; foobar-network; };

  zone "." IN {
    type hint;
    file "named.ca";
  };

  /* 正引き foobar.local */
  zone "foobar.local" IN {
    type master;
    file "foobar.local.zone";
  };

  /* 正引き foobar.org */
  zone "foobar.org" IN {
    type master;
    file "foobar.local.zone";
  };

  /* 逆引き */
  zone "10.in-addr.arpa" {
    type master;
    file "foobar.local.rev.zone";
  };

  include "/etc/named.rfc1912.zones";
  include "/etc/named.root.key";
};
```

```
# NSD nsd.conf

server:
	port: 10053
	logfile: "/var/log/nsd.log"

zone:
	name: "foobar.local"
	zonefile: "foobar.local.zone"

zone:
	name: "foobar.org"
	zonefile: "foobar.local.zone"

zone:
	name: "10.in-addr.arpa"
	zonefile: "foobar.local.rev.zone"
```

# BIND9 から Unbound へ #

DNS サーバーへの要求のほとんどは **名前解決** であり、それはキャッシュサーバーの役割となる。キャッシュサーバーは自身が管理する名前と IP アドレスのマッピングから、クライアントに要求される名前の解決結果を返す。自身で解決できない場合には上位のサーバーに問い合わせし、その結果を返す。この時、上位のサーバーへの問い合わせ結果を自身に保存 (= キャッシュ) するので、キャッシュサーバーと呼ばれる。以後は上位サーバーに問い合わせすることなく、自身で名前解決できるようになり、高速に応答を返すことができるようになる。

Unbound はキャッシュサーバーでありながらも、単純なレコードの定義 (A レコード, MX レコードなど) は自身にその定義を持つことができる。`local-data` という設定を使う。ワイルドカードや CNAME などの複雑な定義を要する場合には、権威サーバーに処理を移譲するよう設定する。BIND9 は自身が権威サーバー **でも** あるので、この点についてはあまり小難しいことを考える必要がなかった。

以下は BIND9 の設定を Unbound の設定に書きなおしたものだ:

```
// BIND9 named.conf
acl "foobar-network" {
  10.0.0.0/8;
};

options {
  listen-on port 53 { 127.0.0.1; };
  listen-on-v6 port 53 { ::1; };  // ipv6 は使わない
  version     "unknown";
  directory   "/var/named";
  dump-file   "/var/named/data/cache_dump.db";
  statistics-file "/var/named/data/named_stats.txt";
  memstatistics-file "/var/named/data/named_mem_stats.txt";
  allow-query { localhost; foobar-network; };
  recursion yes;

  /* dnssec は無効 */
  dnssec-enable no;
  dnssec-validation no;

  /* Path to ISC DLV key */
  bindkeys-file "/etc/named.iscdlv.key";

  managed-keys-directory "/var/named/dynamic";

  /* 自分で名前解決できない場合は上位へ転送 */
  forwarders {
    8.8.8.8;
  };
  forward only;
};

logging {
  channel default {
    file "/var/log/named/default.log" versions 5 size 10M;
    severity info;
    print-time yes;
    print-severity yes;
    print-category yes;
  };

  channel debug {
    file "data/named.run";
    severity dynamic;
    print-time yes;
    print-severity yes;
    print-category yes;
  };

  category default { "debug"; "default"; };
  category queries { "debug"; };
  category resolver { "debug"; };
  category lame-servers { null; };  // error (connection refused) resolving というエラーログを抑止する
};

view "internal" {
  match-clients { localhost; foobar-network; };
  match-destinations { localhost; foobar-network; };

  zone "." IN {
    type hint;
    file "named.ca";
  };

  /* 正引き foobar.local */
  zone "foobar.local" IN {
    type master;
    file "foobar.local.zone";
  };

  /* 正引き foobar.org */
  zone "foobar.org" IN {
    type master;
    file "foobar.local.zone";
  };

  /* 逆引き */
  zone "10.in-addr.arpa" {
    type master;
    file "foobar.local.rev.zone";
  };

  include "/etc/named.rfc1912.zones";
  include "/etc/named.root.key";
};
```

```
# Unbound unbound.conf

server:
	interface: 0.0.0.0
	access-control: 127.0.0.1/32 allow
	access-control: 10.0.0.0/8 allow
	access-control: 0.0.0.0/0 deny
	do-not-query-localhost: no
	local-zone: "10.in-addr.arpa" nodefault

stub-zone:
	name: "foobar.org"
	stub-addr: 127.0.0.1@10053

stub-zone:
	name: "foobar.local"
	stub-addr: 127.0.0.1@10053

stub-zone:
	name: "10.in-addr.arpa"
	stub-addr: 127.0.0.1@10053

forward-zone:
	name: "."
	forward-addr: 8.8.8.8
```
