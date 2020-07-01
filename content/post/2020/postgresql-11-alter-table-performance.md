---
title: "PostgreSQL 11 でパフォーマンス改善された ALTER TABLE を試す"
date: 2020-07-01T22:57:27+09:00
draft: false
---

PostgreSQL 11 の改善点として、[ALTER TABLE で NOT NULL DEFAULT 'blah' な ADD COLUMN したときのパフォーマンスが改善されている](https://brandur.org/postgres-default)ということを知った。大きめのテーブルに列を追加するときは結構死活問題で、地道なワークアラウンドを強要されていた。これで解決するならとても嬉しいということで、一つ試してみることにした。

手順はこんな感じ:

1. PostgreSQL 10 と 11 の環境をローカルに用意
2. それぞれに `x integer not null` な列を持つ `table1` を定義
3. `table1` に 100 万レコード追加
4. `table1` に `ADD COLUMN y integer not null default 1` な `ALTER TABLE` を発行
   - これを計測

結果は以下:

| バージョン | 時間 (ms) |
|------------|-----------|
| 10.4 | 653.094 |
| 11.8 | 5.971 |

素晴らしい。なぜ速くなるかは[先の記事](https://brandur.org/postgres-default#under-the-hood)が詳しいのでここでは割愛。

以下、計測作業時のログ:

## Ver 10.4

```
postgres=# \d table1
               Table "public.table1"
 Column |  Type   | Collation | Nullable | Default
--------+---------+-----------+----------+---------
 x      | integer |           | not null |

postgres=# select count(*) from table1;
  count
---------
 1000000
(1 row)

postgres=# \timing
Timing is on.

postgres=# alter table table1 add column y integer not null default 1;
ALTER TABLE
Time: 653.094 ms
```

## Ver 11.8

```
postgres=# \d table1
               Table "public.table1"
 Column |  Type   | Collation | Nullable | Default 
--------+---------+-----------+----------+---------
 x      | integer |           | not null | 

postgres=# select count(*) from table1;
  count  
---------
 1000000
(1 row)

postgres=# \timing
Timing is on.

postgres=# alter table table1 add column y integer not null default 1;
ALTER TABLE
Time: 5.971 ms
```
