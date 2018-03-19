+++
date = "2017-06-16T00:56:29+09:00"
title = "時系列データのための SQL クエリ"
draft = false

+++

物事を Event (E) と Resource \(R) に分けてモデリングする手法を実践していると、おのずとイベントという時系列データを検索するためのクエリをたくさん書くことになる。時系列データに対するクエリは少し特徴があり、ここでひとつまとめておこうと思う。ここではいくつかの例、方法を紹介するが、よりよい解、または別の解もあると思う。このページで取り上げる SQL はすべて PostgreSQL 9.3 で動作確認している。

次のようなテーブル構成を例にとる。

```
CREATE TABLE person (
  id SERIAL PRIMARY KEY
);

CREATE TABLE person_attr_changes (
  id SERIAL PRIMARY KEY,
  person_id INTEGER NOT NULL,
  name VARCHAR NOT NULL,
  birthday DATE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (person_id) REFERENCES person(id)
);
```

人物 (pesron) と、その人物の属性の変更履歴 (person\_attr\_changes) を持つテーブルを定義している。人物の属性は人物に対して 1 対多の関係となっている。人物の属性を変更すると、person\_attr\_changes テーブルに `UPDATE` をかけるのではなく、変更を含む新たなレコードを `INSERT` することを想定している。birthday が変わることは基本的にはないと思うが、name は苗字の変更などで現実的にありえる。

例えば 2017/6/15 時点での ID=1 (person.id=1) の人物の属性を取得することを考える。person\_attr_changes には変更した時点のタイムスタンプとともに属性値が格納されているので、2017/6/15 以前の person\_id=1 のレコードのうち、最後のレコードを選択すればよい。もしこの条件に引っかかるレコードがなければ、その時点では ID=1 の人物は存在しなかったことを意味する。

このような「ある条件を満たす集合の中で、最新のレコードを選択する」というのが、イベントデータを扱っていてもっとも頻出するパターンのクエリだった。

2 通りのクエリを考える。

## NOT EXISTS + 相関サブクエリ ##

```
SELECT a.*
  FROM person_attr_changes a
 WHERE a.person_id = 1
   AND a.created_at <= '2017-6-15'::date
   AND NOT EXISTS (SELECT *
                     FROM person_attr_changes a2
                    WHERE a2.person_id = 1
                      AND a2.created_at <= '2017-6-15'::date
                      AND a2.created_at > a.created_at)
```

こんな感じになる。この相関サブクエリと `NOT EXISTS` を使ったクエリは頻出する。というか愛用している。解説は後にするとして、まずはうまく動作していることを確認したい。

```
select * from person_attr_changes order by id;
 id | person_id |      name      |  birthday  |     created_at      
----+-----------+----------------+------------+---------------------
  1 |         1 | satou tanaka   | 1980-01-01 | 2017-06-13 00:00:00
  2 |         1 | suzuki tanaka  | 1980-01-01 | 2017-06-14 00:00:00
  3 |         1 | satou tanaka   | 1980-01-01 | 2017-06-16 00:00:00
  4 |         2 | yamamoto inoue | 1988-02-03 | 2017-06-15 00:00:00
(4 rows)
```

person_id=1 の人物は、2017/6/13 に "satou tanaka" という名前で登録し、2017/6/14 に "suzuki tanaka" という名前に変更している。さらにその後の 2017/6/16 にはまたもとの "satou tanaka" という名前に戻している。このようなデータに対し、先ほどのクエリを投げる。言うまでもなく、ここで狙うのは "suzuki tanaka" のレコード。

```
SELECT a.*
  FROM person_attr_changes a
 WHERE a.person_id = 1
   AND a.created_at <= '2017-6-15'::date
   AND NOT EXISTS (SELECT *
                     FROM person_attr_changes a2
                    WHERE a2.person_id = 1
                      AND a2.created_at <= '2017-6-15'::date
                      AND a2.created_at > a.created_at);
 id | person_id |     name      |  birthday  |     created_at      
----+-----------+---------------+------------+---------------------
  2 |         1 | suzuki tanaka | 1980-01-01 | 2017-06-14 00:00:00
(1 row)
```

うまくいった。

このクエリでは person\_attr\_changes に対して 2 つの `SELECT` を発行している。いずれにおいても、person\_id と created\_at に対して同じ条件 (ID=1, 2017/6/15 以前) を与えている。サブクエリのほうではさらに `AND a2.created_at > a.created_at` を付け加えている。これがキモとなる。これはつまり、`person_id = 1 AND created_at <= '2017-6-15'::date` を満たす集合から、a.created\_at より大きな created\_at を持つレコードが存在しないレコード、すなわち最後のレコードを探し出している。

created_at が同一になりうる場合には、厳密にはこれだけではうまくいかない。複数のレコードがとれてくる可能性がある。先ほどのサンプルデータにそのようなデータを追加して試してみる。

```
select * from person_attr_changes order by id;
 id | person_id |      name       |  birthday  |     created_at      
----+-----------+-----------------+------------+---------------------
  1 |         1 | satou tanaka    | 1980-01-01 | 2017-06-13 00:00:00
  2 |         1 | suzuki tanaka   | 1980-01-01 | 2017-06-14 00:00:00
  3 |         1 | satou tanaka    | 1980-01-01 | 2017-06-16 00:00:00
  4 |         2 | yamamoto inoue  | 1988-02-03 | 2017-06-15 00:00:00
  5 |         2 | takahashi inoue | 1988-02-03 | 2017-06-15 00:00:00
(5 rows)
```

person\_id=2 に created\_at が同じレコードがふたつ存在している。

```
SELECT a.*
  FROM person_attr_changes a
 WHERE a.person_id = 2
   AND a.created_at <= '2017-6-15'::date
   AND NOT EXISTS (SELECT *
                     FROM person_attr_changes a2
                    WHERE a2.person_id = 2
                      AND a2.created_at <= '2017-6-15'::date
                      AND a2.created_at > a.created_at);
 id | person_id |      name       |  birthday  |     created_at      
----+-----------+-----------------+------------+---------------------
  4 |         2 | yamamoto inoue  | 1988-02-03 | 2017-06-15 00:00:00
  5 |         2 | takahashi inoue | 1988-02-03 | 2017-06-15 00:00:00
(2 rows)
```

両方のレコードがとれてくる。このようなことを防ぎたければ、絶対に重複せず、かつ前後関係を表すことのできる列 (連番が発行される ID など) を条件に加えればよい。PostgreSQL の場合は `ORDER BY` と `LIMIT 1` を組み合わせるのがもっともかんたんかもしれない。

```
SELECT a.*
  FROM person_attr_changes a
 WHERE a.person_id = 2
   AND a.created_at <= '2017-6-15'::date
   AND NOT EXISTS (SELECT *
                     FROM person_attr_changes a2
                    WHERE a2.person_id = 2
                      AND a2.created_at <= '2017-6-15'::date
                      AND a2.created_at > a.created_at)
 ORDER BY a.id DESC
 LIMIT 1;
 id | person_id |      name       |  birthday  |     created_at      
----+-----------+-----------------+------------+---------------------
  5 |         2 | takahashi inoue | 1988-02-03 | 2017-06-15 00:00:00
(1 row)
```

すでに十分な数 (要件にもよるところがあるが、現実的にはせいぜい 2 レコード程度ではないだろうか) まで絞り込んだあとの集合に対するソートなので、さほどコストはかからない。

## ORDER BY + LIMIT 1 ##

もうひとつの方法として、`ORDER BY` と `LIMIT 1` を使った方法を取り上げる。リレーショナルモデルを重んじる身としてはあまり使いたくない方法ではあるのだが、現実的に使わなければならない状況があったりするので、取り上げる。

上であげたクエリを、`ORDER BY` と `LIMIT 1` を使うクエリに書き換える。

```
SELECT a.*
  FROM person_attr_changes a
 WHERE a.person_id = 1
   AND a.created_at <= '2017-6-15'::date
   AND a.id = (SELECT a2.id
                 FROM person_attr_changes a2
                WHERE a2.person_id = 1
                  AND a2.created_at <= '2017-6-15'::date
                ORDER BY a2.created_at
                LIMIT 1)
```

`NOT EXISTS` と相関サブクエリを使ったクエリと異なるのは、`a.id = (SELECT a2.id` 以下の部分となる。サブクエリの中で `ORDER BY` と `LIMIT 1` を使っている。サブクエリでは、person\_id と created\_at の条件を満たす集合を created\_at の降順で並べ、その最初のレコードの id をスカラー値として選択している。メインクエリ (という呼び名が正しいかどうかは微妙だが) では、このスカラー値を id に持つ person\_attr\_changes のレコードを選択するような条件となっている。メインクエリでは a.id 以外の条件は必要なさそうに思えるし、実際なくても正しく動作するのだが、手元で試す限り、サブクエリと同じ条件を含んでいるほうが、PostgreSQL はよい実行計画を出力するようだ。

## 実行計画を見る ##

`NOT EXISTS` + 相関サブクエリの弱点のひとつが、集合を十分に絞り込めない条件の場合にコストがかかってしまうということ。先の例では person\_id と created\_at で絞り込んだ集合の中から、created\_at が最大のレコードを探しだした。これは person\_id と created\_at の条件によって、最大のレコードを探し出す集合を十分に絞り込んでいるため、高速に動作する。集合を絞り込む条件がゆるい、つまり集合を十分に絞り込めない場合、おのずと最大レコードを探し出す範囲も広がり、遅くなる。

このような状況でも `ORDER BY` と `LIMIT 1` を使ったクエリは高速に動作する。もちろん適切にインデックスをはっておく必要はあるが。ここではその違いを実行計画を見ながら比較していく。

もう少し量の多いデータを例を考える。さすがに 1 人の人物の属性を 100 万回変えるようなことはないと思うので、モデルを変える。センサーによる計測データを蓄積していくようなシナリオを考える。センサーは 1 秒に 1 回程度、計測データを出力する。データベースにはそのすべてをタイムスタンプ付きで記録していく。センサーは複数個存在する。

```
CREATE TABLE sensor (
  id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL
);

CREATE TABLE measure (
  id BIGSERIAL PRIMARY KEY,
  sensor_id INTEGER NOT NULL,
  value VARCHAR NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sensor_id) REFERENCES sensor(id)
);

```

センサーを 100 個、センサーごとに 100 万件ずつの計測データをテストデータとして挿入する。

```
INSERT INTO sensor (name) SELECT 'sensor-' || i.v FROM generate_series(1, 100) AS i(v);
INSERT INTO measure (sensor_id, value, created_at)
  SELECT i.v, 'data-' || i.v || '-' || j.v, '2010-1-1'::timestamp + (j.v || ' second')::interval
    FROM generate_series(1, 100) AS i(v)
       , generate_series(1, 1000000) AS j(v);

CREATE INDEX idx_measure_sensor_id ON measure(sensor_id);
CREATE INDEX idx_measure_created_at ON measure(created_at);
```

今回はインデックスをはった。インデックスを使われ方が `NOT EXISTS` と相関サブクエリを使ったクエリと `ORDER BY` と `LIMIT 1` を使ったクエリとで異なるので、その様子を実行計画で見てみたい。

軽くデータを俯瞰する。

```
SELECT MIN(created_at), MAX(created_at), COUNT(*) FROM measure;
         min         |         max         |   count   
---------------------+---------------------+-----------
 2010-01-01 00:00:01 | 2010-01-12 13:46:40 | 100000000
(1 row)
```

センサー 15 (sensor.id=15) における 2010/1/10 22:00:00 時点の最新の計測データを取得することを考える。

まずは `NOT EXISTS` と相関サブクエリを使ったクエリ。

```
EXPLAIN ANALYZE
SELECT s.id, s.name, m.value, m.created_at as measured_at
  FROM sensor s
       INNER JOIN measure m ON m.sensor_id = s.id
 WHERE m.sensor_id = 15
   AND m.created_at <= '2010-1-10 22:00:00'
   AND NOT EXISTS (SELECT *
                     FROM measure m2
                    WHERE m2.sensor_id = 15
                      AND m2.created_at <= '2010-1-10 22:00:00'
                      AND m2.created_at > m.created_at);

                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=1.14..306403237.25 rows=550689 width=35) (actual time=11830.748..11858.808 rows=1 loops=1)
   ->  Seq Scan on sensor s  (cost=0.00..2.25 rows=1 width=13) (actual time=0.039..0.046 rows=1 loops=1)
         Filter: (id = 15)
         Rows Removed by Filter: 99
   ->  Nested Loop Anti Join  (cost=1.14..306397728.11 rows=550689 width=26) (actual time=11830.701..11858.752 rows=1 loops=1)
         ->  Index Scan using idx_measure_sensor_id on measure m  (cost=0.57..37734.59 rows=826034 width=26) (actual time=1.074..261.470 rows=856800 loops=1)
               Index Cond: (sensor_id = 15)
               Filter: (created_at <= '2010-01-10 22:00:00'::timestamp without time zone)
               Rows Removed by Filter: 143200
         ->  Index Scan using idx_measure_created_at on measure m2  (cost=0.57..114708675.64 rows=275345 width=8) (actual time=0.013..0.013 rows=1 loops=856800)
               Index Cond: ((created_at > m.created_at) AND (created_at <= '2010-01-10 22:00:00'::timestamp without time zone))
               Filter: (sensor_id = 15)
               Rows Removed by Filter: 14
 Total runtime: 11859.438 ms
(14 rows)
```

次は `ORDER BY` と `LIMIT 1` を使ったクエリ。

```
EXPLAIN ANALYZE
SELECT s.id, s.name, m.value, m.created_at as measured_at
  FROM sensor s
       INNER JOIN measure m ON m.sensor_id = s.id
 WHERE m.sensor_id = 15
   AND m.created_at <= '2010-1-10 22:00:00'
   AND m.id = (SELECT m2.id
                 FROM measure m2
                WHERE m2.sensor_id = 15
                  AND m2.created_at <= '2010-1-10 22:00:00'
                ORDER BY m2.created_at DESC
                LIMIT 1);

                                                                               QUERY PLAN                                                                               
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=414.84..425.12 rows=1 width=35) (actual time=0.205..0.217 rows=1 loops=1)
   InitPlan 1 (returns $0)
     ->  Limit  (cost=0.57..414.27 rows=1 width=16) (actual time=0.163..0.163 rows=1 loops=1)
           ->  Index Scan Backward using idx_measure_created_at on measure m2  (cost=0.57..341732696.43 rows=826034 width=16) (actual time=0.161..0.161 rows=1 loops=1)
                 Index Cond: (created_at <= '2010-01-10 22:00:00'::timestamp without time zone)
                 Filter: (sensor_id = 15)
                 Rows Removed by Filter: 85
   ->  Seq Scan on sensor s  (cost=0.00..2.25 rows=1 width=13) (actual time=0.022..0.033 rows=1 loops=1)
         Filter: (id = 15)
         Rows Removed by Filter: 99
   ->  Index Scan using measure_pkey on measure m  (cost=0.57..8.59 rows=1 width=26) (actual time=0.011..0.012 rows=1 loops=1)
         Index Cond: (id = $0)
         Filter: ((created_at <= '2010-01-10 22:00:00'::timestamp without time zone) AND (sensor_id = 15))
 Total runtime: 0.285 ms
(14 rows)
```


`EXPLAIN ANALYZE` なので実際にクエリを発行し、そのときの実行計画および処理時間、行数などが出力されている。Total runtime を見ると速度の違いは一目瞭然。圧倒的に後者が速い。

前者では、まず `m.created_at <= '2010-1-10 22:00:00'` で引っ掛ける集合を `Index Scan using idx_measure_created_at` で集めている。これを満たすレコードは `rows=856800` にあるとおり、たくさんある。これを次の `Index Scan using idx_measure_created_at on measure m2` の条件に含めている。これらを `Nested Loop Anti Join` で結合するため、ループの回数は `loops=856800` となっている。つまり 2010-1-10 22:00:00 以前のレコード 856800 件を探すために一度スキャンし、さらにこの中から最大の created_at を持つレコードを探すために 856800 回ループしている。擬似コードに落とすとこんな感じ:

```
m = find_by(created_at <= '2010-1-10 22:00:00')  // m.length=856800
max = m[0]  // max が所望のレコード
for (m2 in m[1..])
  if m2.created_at > max.created_at
    max = m2
```

後者はもっとかんたん。`Index Scan Backward using idx_measure_created_at` によってインデックスを逆順にさかのぼり、`ORDER BY created_at DESC` と `LIMIT 1` によって引っ掛けたいレコードを即座に見つけている。そこから芋づる式に必要なデータを集めている。目的の measure レコードの特定に手間がかからないので速い。

## 他の例 ##

他のバリエーションのクエリを考えてみる。モデルはセンサー、計測データのほうを使う。

センサーごとの最新の計測データを求めてみる。`ORDER BY`, `LIMIT 1` の手法であればかんたん。

```
SELECT m.*
  FROM measure m
       INNER JOIN (SELECT (SELECT m2.id
                             FROM measure m2
                            WHERE m2.sensor_id = s.id
                            ORDER BY m2.created_at DESC
                            LIMIT 1) AS id
                     FROM sensor s) x
         ON m.id = x.id
```

センサーごとの最新の measure.id を INNER JOIN の結合対象としているサブクエリで列挙する。レコード数の少ない sensor で駆動しているので、measure をスキャンする回数を抑えられる。これと measure を結合し、所望の計測データの集合を得る。一番内側のクエリに created\_at に対する条件をつければ、ある時点におけるセンサーごとの最後の計測データを取得できる。

センサー 30 (sensor.id=30) の 2010-1-5 における計測値の最小値と最大値、およびそれぞれの計測日時。同じ値を複数計測していれば、それらすべてを選択する。

```
SELECT m.*, 'max' AS typ
  FROM measure m
 WHERE m.sensor_id = 30
   AND m.created_at BETWEEN '2010-1-5' AND '2010-1-5 23:59:59'
   AND NOT EXISTS (SELECT * FROM measure m2
                    WHERE m2.sensor_id = 30
                      AND m2.created_at BETWEEN '2010-1-5' AND '2010-1-5 23:59:59'
                      AND m2.value > m.value)
UNION ALL
SELECT m.*, 'min' AS typ
  FROM measure m
 WHERE m.sensor_id = 30
   AND m.created_at BETWEEN '2010-1-5' AND '2010-1-5 23:59:59'
   AND NOT EXISTS (SELECT * FROM measure m2
                    WHERE m2.sensor_id = 30
                      AND m2.created_at BETWEEN '2010-1-5' AND '2010-1-5 23:59:59'
                      AND m2.value < m.value)
```

考え方は `NOT EXISTS` と相関サブクエリを使った手法を、ほとんどそのまま適用している。m2.value と m.value を、最大、最小それぞれの文脈に応じて比較している点が、これまでの例と異なっている。残念ながらこのクエリは遅くて使い物にならない。遅い原因はすでに解説した通り。

---

個人的にお気に入りの手法であるところの `NOT EXISTS` と相関サブクエリを使った方法に不利な結論に至ってしまった。この手法のいいところは、SQL 標準機能だけを使っているということ。最近では `LIMIT` 相当の機能も標準化されている (`FETCH FIRST ...`) ものの、古い環境では使えない。LIMIT は SQL 標準に含まれないので、使えない環境もある (Oracle とか)。そんなときには `NOT EXISTS` と相関サブクエリを使った手法が役に立つ。Oracle の場合は `LIMIT` を使うのと似た方法で `ROWNUM` を使う方法も考えられるが、ここでは省略する。

しかしまぁ、`LIMIT` (およびそれ相当の機能) が使える環境であれば、おとなしく `ORDER BY` と `LIMIT 1` を使った方法のほうがいいんじゃないだろうか。パフォーマンスもよいし、わりとかんたんに理解できる点もポイントが高い。順序付ける項目が重複した場合の例外処理も `LIMIT 1` によっておのずとカバーできる。リレーショナルモデル的には美しくない (個人の感想) けど、それは目を瞑れば済む話 (悲)。
