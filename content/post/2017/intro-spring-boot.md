+++
title = "はじめての Spring Boot"
draft = false
date = "2017-03-11T15:44:46+09:00"

+++

最近の Spring Framework ベースのアプリケーション開発で欠かせないのが [Spring Boot](https://projects.spring.io/spring-boot/) である。Spring Boot とは、公式によれば:

> Spring Boot makes it easy to create stand-alone, production-grade Spring based Applications that you can "just run". We take an opinionated view of the Spring platform and third-party libraries so you can get started with minimum fuss. Most Spring Boot applications need very little Spring configuration.

であるとのこと。Spring Boot にはいろんな機能が備わっているわけだが、これらはひとえに Spring Framework ベースのアプリケーションをかんたんに作り、かんたんに運用するために用意されている。それでいて出来上がるアプリケーションはオモチャのようなものではなく、紛れもない本物の Spring Framework ベースのアプリケーションである。

このページでは、まずは Spring Boot ベースのかんたんな Web アプリケーションを作ってみることにする。その後、少し話題を変えて、Spring Boot の中身を追ってみたい。今回は起動プロセスをかんたんに調べてみることにした。

## プロジェクトを作る ##

[Spring Initializr](http://start.spring.io/) でプロジェクトのひな形を作ることができる。

ここでは

 * Maven Project
 * Spring Boot 1.5.2
 * Project Metadata
    * group: org.genva
    * artifact: fortune
 * Dependencies
    * web
    * devtools

として、ひな形を作る。fortune.zip が落ちてくるので、適当な場所に展開する。

```
$ unzip fortune.zip
$ tree fortune
fortune
├── mvnw
├── mvnw.cmd
├── pom.xml
└── src
    ├── main
    │   ├── java
    │   │   └── org
    │   │       └── genva
    │   │           └── FortuneApplication.java
    │   └── resources
    │       ├── application.properties
    │       ├── static
    │       └── templates
    └── test
        └── java
            └── org
                └── genva
                    └── FortuneApplicationTests.java

12 directories, 6 files
```

Eclipse 用のプロジェクト設定を生成する。

```
$ cd fortune
$ ./mvnw eclipse:eclipse
```

Maven をインストールしていなくても、そのラッパースクリプトである mvnw を使うことで、自動的に Maven が導入される。

## 起動する ##

プロジェクトを Eclipse で開き、 `org.genva.fortune.FortuneApplication` を Java Application として実行する。

```
15:58:55.047 [main] DEBUG org.springframework.boot.devtools.settings.DevToolsSettings - Included patterns for restart : []
15:58:55.051 [main] DEBUG org.springframework.boot.devtools.settings.DevToolsSettings - Excluded patterns for restart : [/spring-boot-starter/target/classes/, /spring-boot-autoconfigure/target/classes/, /spring-boot-starter-[\w-]+/, /spring-boot/target/classes/, /spring-boot-actuator/target/classes/, /spring-boot-devtools/target/classes/]
15:58:55.052 [main] DEBUG org.springframework.boot.devtools.restart.ChangeableUrls - Matching URLs for reloading : [file:/home/kazuki/sources/writing/spring/fortune/target/test-classes/, file:/home/kazuki/sources/writing/spring/fortune/target/classes/]

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v1.5.2.RELEASE)

2017-03-11 15:58:55.478  INFO 10029 --- [  restartedMain] org.genva.FortuneApplication             : Starting FortuneApplication on carrot with PID 10029 (/home/kazuki/sources/writing/spring/fortune/target/classes started by kazuki in /home/kazuki/sources/writing/spring/fortune)
2017-03-11 15:58:55.479  INFO 10029 --- [  restartedMain] org.genva.FortuneApplication             : No active profile set, falling back to default profiles: default
2017-03-11 15:58:55.571  INFO 10029 --- [  restartedMain] ationConfigEmbeddedWebApplicationContext : Refreshing org.springframework.boot.context.embedded.AnnotationConfigEmbeddedWebApplicationContext@38bed225: startup date [Sat Mar 11 15:58:55 JST 2017]; root of context hierarchy
2017-03-11 15:58:57.303  INFO 10029 --- [  restartedMain] s.b.c.e.t.TomcatEmbeddedServletContainer : Tomcat initialized with port(s): 8080 (http)

(snip)

2017-03-11 15:58:58.780  INFO 10029 --- [  restartedMain] s.b.c.e.t.TomcatEmbeddedServletContainer : Tomcat started on port(s): 8080 (http)
2017-03-11 15:58:58.785  INFO 10029 --- [  restartedMain] org.genva.FortuneApplication             : Started FortuneApplication in 3.707 seconds (JVM running for 4.236)
```

最後のメッセージが表示されれば、アプリケーションの起動が完了している。組み込み Tomcat は :8080 で待ち構えていることが分かる。また、メインスレッドの名前が restartedMain になっていることから、spring-boot-devtools が効いていることが分かる。

## コントローラを追加する ##

コントローラを追加し、HTTP 経由でアプリケーションを叩けるようにする。

```java
@RestController
public class FortuneController {
    @GetMapping
    public String index() {
        return LocalDateTime.now().toString();
    }
}
```

クラスを追加したり、ファイルを保存したりすると、アプリケーションが自動的に再起動する様子がログから分かる。これは spring-boot-devtools によるもの。アプリケーションのクラスローダーと依存ライブラリのクラスローダーが分かれていて、アプリケーションのソースが更新されると、自動的にアプリケーションのクラスローダーだけが破棄、再読み込みされる。アプリケーションのクラスだけが再読み込みされるので、再起動にかかる時間は短く済む。

さて、コントローラにアクセスしてみよう。

```
$ curl http://localhost:8080/
2017-03-11T16:05:26.669
$ curl http://localhost:8080/
2017-03-11T16:05:46.557
```

現在日時が返ってきている。ちゃんと機能しているようだ。

## fortune の出力を返すようにする ##

現在日時を返すだけではつまらないし、せっかくの Spring なので依存性注入も使いたい。そこで fortune (/usr/games/fortune) の出力を応答として返すようにする。このような業務処理 (fortune の出力を得ることを、業務と呼ぶべきかどうかはさておき) は、コントローラのようなプレゼンテーション層ではなくサービスなどのモデル層に書くべき処理である。今回はサービスクラスとして作ることにした。

```java
@Service
public class FortuneService {
    public String get() {
        ProcessBuilder pb = new ProcessBuilder("/usr/games/fortune");
        Process p = null;
        try {
            p = pb.start();
            p.waitFor();
            try (BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
                return br.lines().collect(Collectors.joining("\n"));
            }
        }
        catch (IOException | InterruptedException e) {
            return "MOU DAMEPO";
        }
        finally {
            if (p != null) {
                closeQuietly(p.getErrorStream());
                closeQuietly(p.getOutputStream());
                closeQuietly(p.getInputStream());
                p.destroy();
            }
        }
    }
}
```

/usr/games/fortune のプロセスを起動し、その出力を得るだけのプログラムである。Java でのプロセスの扱いはとても面倒で、かつ間違いが起きやすいので、なるべくなら避けたいものである。`closeQuietly` は例外を握りつぶしつつ `Closeable.close` を呼ぶメソッドで、そういうユーティリティがあるものと思ってほしい。

これを使うよう、コントローラを修正する。層をまたいだ依存関係の設定は、外部 (ここでは Spring) にまかせてしまう (これが依存性注入と呼ばれるもの)。

```java
@RestController
public class FortuneController {
    private FortuneService fortune;

    public FortuneController(FortuneService fortune) {
        this.fortune = fortune;
    }

    @GetMapping
    public String index() {
        return fortune.get();
    }
}
```

改めて curl で叩く。

```
$ curl http://localhost:8080/
You are not dead yet.  But watch for further reports.
$ curl http://localhost:8080/
Wagner's music is better than it sounds.
                -- Mark Twain
```

ありがたいお言葉が返ってくるようになった。

なお、最初に FortuneApplication を起動してから、fortune の結果を得られるようになるまで、Eclipse を使ったアプリケーションの再起動は一度も行わなかった。spring-boot-devtools は素晴らしい。

## パッケージング、デプロイ ##

パッケージングは Maven で package すればおしまい。

```
$ ./mvnw package
$ file target/fortune-0.0.1-SNAPSHOT.jar
target/fortune-0.0.1-SNAPSHOT.jar: Java Jar file data (zip)
```

この jar ファイルは Maven の spring-boot プラグインによって後処理 (repackage) されたもので、特殊なレイアウトになっている。

```
$ unzip -l target/fortune-0.0.1-SNAPSHOT.jar
Archive:  target/fortune-0.0.1-SNAPSHOT.jar
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  2017-03-11 17:03   META-INF/
      563  2017-03-11 17:03   META-INF/MANIFEST.MF
        0  2017-03-11 17:03   BOOT-INF/
        0  2017-03-11 17:03   BOOT-INF/classes/
        0  2017-03-11 16:30   BOOT-INF/classes/org/
        0  2017-03-11 16:30   BOOT-INF/classes/org/genva/
        0  2017-03-11 17:03   BOOT-INF/classes/application.properties
      717  2017-03-11 17:03   BOOT-INF/classes/org/genva/FortuneController.class
      156  2017-03-11 17:03   BOOT-INF/classes/org/genva/FortuneService.class
     2504  2017-03-11 17:03   BOOT-INF/classes/org/genva/UnixFortuneService.class
      699  2017-03-11 17:03   BOOT-INF/classes/org/genva/FortuneApplication.class
        0  2017-03-11 17:03   META-INF/maven/
        0  2017-03-11 17:03   META-INF/maven/org.genva/
        0  2017-03-11 17:03   META-INF/maven/org.genva/fortune/
     1571  2017-03-11 06:53   META-INF/maven/org.genva/fortune/pom.xml
      117  2017-03-11 17:03   META-INF/maven/org.genva/fortune/pom.properties
        0  2017-03-11 17:03   BOOT-INF/lib/
     2346  2017-03-03 15:47   BOOT-INF/lib/spring-boot-starter-web-1.5.2.RELEASE.jar
     2289  2017-03-03 15:46   BOOT-INF/lib/spring-boot-starter-1.5.2.RELEASE.jar
     2310  2017-03-03 15:46   BOOT-INF/lib/spring-boot-starter-logging-1.5.2.RELEASE.jar
   309130  2017-03-01 20:40   BOOT-INF/lib/logback-classic-1.1.11.jar
   475477  2017-03-01 20:39   BOOT-INF/lib/logback-core-1.1.11.jar
    16516  2017-02-24 12:09   BOOT-INF/lib/jcl-over-slf4j-1.7.24.jar
     4597  2017-02-24 12:09   BOOT-INF/lib/jul-to-slf4j-1.7.24.jar
    23647  2017-02-24 12:09   BOOT-INF/lib/log4j-over-slf4j-1.7.24.jar
   273599  2016-02-19 13:13   BOOT-INF/lib/snakeyaml-1.17.jar
     2294  2017-03-03 15:47   BOOT-INF/lib/spring-boot-starter-tomcat-1.5.2.RELEASE.jar
  3015953  2017-01-10 21:03   BOOT-INF/lib/tomcat-embed-core-8.5.11.jar
   239791  2017-01-10 21:03   BOOT-INF/lib/tomcat-embed-el-8.5.11.jar
   241640  2017-01-10 21:03   BOOT-INF/lib/tomcat-embed-websocket-8.5.11.jar
   725129  2016-12-08 10:48   BOOT-INF/lib/hibernate-validator-5.3.4.Final.jar
    63777  2013-04-10 15:02   BOOT-INF/lib/validation-api-1.1.0.Final.jar
    66802  2015-05-28 09:49   BOOT-INF/lib/jboss-logging-3.3.0.Final.jar
    64982  2016-09-27 22:24   BOOT-INF/lib/classmate-1.3.3.jar
  1237433  2017-02-21 01:07   BOOT-INF/lib/jackson-databind-2.8.7.jar
    55784  2016-07-03 22:20   BOOT-INF/lib/jackson-annotations-2.8.0.jar
   282314  2017-02-20 17:01   BOOT-INF/lib/jackson-core-2.8.7.jar
   817936  2017-03-01 08:34   BOOT-INF/lib/spring-web-4.3.7.RELEASE.jar
   380004  2017-03-01 08:32   BOOT-INF/lib/spring-aop-4.3.7.RELEASE.jar
   762747  2017-03-01 08:31   BOOT-INF/lib/spring-beans-4.3.7.RELEASE.jar
  1139269  2017-03-01 08:32   BOOT-INF/lib/spring-context-4.3.7.RELEASE.jar
   915615  2017-03-01 08:34   BOOT-INF/lib/spring-webmvc-4.3.7.RELEASE.jar
   263286  2017-03-01 08:32   BOOT-INF/lib/spring-expression-4.3.7.RELEASE.jar
   667710  2017-03-03 15:34   BOOT-INF/lib/spring-boot-1.5.2.RELEASE.jar
  1045757  2017-03-03 15:41   BOOT-INF/lib/spring-boot-autoconfigure-1.5.2.RELEASE.jar
    41205  2017-02-24 12:08   BOOT-INF/lib/slf4j-api-1.7.24.jar
  1118609  2017-03-01 08:31   BOOT-INF/lib/spring-core-4.3.7.RELEASE.jar
        0  2017-03-11 17:03   org/
        0  2017-03-11 17:03   org/springframework/
        0  2017-03-11 17:03   org/springframework/boot/
        0  2017-03-11 17:03   org/springframework/boot/loader/
     2415  2017-03-03 15:28   org/springframework/boot/loader/LaunchedURLClassLoader$1.class
     1454  2017-03-03 15:28   org/springframework/boot/loader/PropertiesLauncher$ArchiveEntryFilter.class
     1807  2017-03-03 15:28   org/springframework/boot/loader/PropertiesLauncher$PrefixMatchingArchiveFilter.class
     4599  2017-03-03 15:28   org/springframework/boot/loader/Launcher.class
     1165  2017-03-03 15:28   org/springframework/boot/loader/ExecutableArchiveLauncher$1.class
        0  2017-03-11 17:03   org/springframework/boot/loader/jar/
     2002  2017-03-03 15:28   org/springframework/boot/loader/jar/JarFile$1.class
     9657  2017-03-03 15:28   org/springframework/boot/loader/jar/Handler.class
     3350  2017-03-03 15:28   org/springframework/boot/loader/jar/JarEntry.class
     1427  2017-03-03 15:28   org/springframework/boot/loader/jar/JarFile$3.class
     2943  2017-03-03 15:28   org/springframework/boot/loader/jar/CentralDirectoryEndRecord.class
      430  2017-03-03 15:28   org/springframework/boot/loader/jar/CentralDirectoryVisitor.class
     1300  2017-03-03 15:28   org/springframework/boot/loader/jar/JarFile$JarFileType.class
    10924  2017-03-03 15:28   org/springframework/boot/loader/jar/JarFileEntries.class
    12697  2017-03-03 15:28   org/springframework/boot/loader/jar/JarFile.class
     1540  2017-03-03 15:28   org/springframework/boot/loader/jar/JarFileEntries$1.class
      672  2017-03-03 15:28   org/springframework/boot/loader/jar/JarURLConnection$1.class
     1199  2017-03-03 15:28   org/springframework/boot/loader/jar/JarFile$2.class
      262  2017-03-03 15:28   org/springframework/boot/loader/jar/JarEntryFilter.class
     4457  2017-03-03 15:28   org/springframework/boot/loader/jar/AsciiBytes.class
     4602  2017-03-03 15:28   org/springframework/boot/loader/jar/CentralDirectoryParser.class
     2169  2017-03-03 15:28   org/springframework/boot/loader/jar/Bytes.class
     1629  2017-03-03 15:28   org/springframework/boot/loader/jar/ZipInflaterInputStream.class
     1967  2017-03-03 15:28   org/springframework/boot/loader/jar/JarFileEntries$EntryIterator.class
      306  2017-03-03 15:28   org/springframework/boot/loader/jar/FileHeader.class
     3641  2017-03-03 15:28   org/springframework/boot/loader/jar/JarURLConnection$JarEntryName.class
     9111  2017-03-03 15:28   org/springframework/boot/loader/jar/JarURLConnection.class
     5449  2017-03-03 15:28   org/springframework/boot/loader/jar/CentralDirectoryFileHeader.class
        0  2017-03-11 17:03   org/springframework/boot/loader/data/
     1531  2017-03-03 15:28   org/springframework/boot/loader/data/ByteArrayRandomAccessData.class
     3534  2017-03-03 15:28   org/springframework/boot/loader/data/RandomAccessDataFile$DataInputStream.class
     2051  2017-03-03 15:28   org/springframework/boot/loader/data/RandomAccessDataFile$FilePool.class
     1341  2017-03-03 15:28   org/springframework/boot/loader/data/RandomAccessData$ResourceAccess.class
     3390  2017-03-03 15:28   org/springframework/boot/loader/data/RandomAccessDataFile.class
      551  2017-03-03 15:28   org/springframework/boot/loader/data/RandomAccessData.class
     4698  2017-03-03 15:28   org/springframework/boot/loader/LaunchedURLClassLoader.class
     1533  2017-03-03 15:28   org/springframework/boot/loader/JarLauncher.class
     1468  2017-03-03 15:28   org/springframework/boot/loader/MainMethodRunner.class
     1382  2017-03-03 15:28   org/springframework/boot/loader/PropertiesLauncher$1.class
     3128  2017-03-03 15:28   org/springframework/boot/loader/ExecutableArchiveLauncher.class
     1669  2017-03-03 15:28   org/springframework/boot/loader/WarLauncher.class
        0  2017-03-11 17:03   org/springframework/boot/loader/archive/
     1749  2017-03-03 15:28   org/springframework/boot/loader/archive/JarFileArchive$EntryIterator.class
     3792  2017-03-03 15:28   org/springframework/boot/loader/archive/ExplodedArchive$FileEntryIterator.class
     1068  2017-03-03 15:28   org/springframework/boot/loader/archive/ExplodedArchive$FileEntry.class
     1051  2017-03-03 15:28   org/springframework/boot/loader/archive/JarFileArchive$JarFileEntry.class
      302  2017-03-03 15:28   org/springframework/boot/loader/archive/Archive$Entry.class
     7016  2017-03-03 15:28   org/springframework/boot/loader/archive/JarFileArchive.class
     4974  2017-03-03 15:28   org/springframework/boot/loader/archive/ExplodedArchive.class
      906  2017-03-03 15:28   org/springframework/boot/loader/archive/Archive.class
     1438  2017-03-03 15:28   org/springframework/boot/loader/archive/ExplodedArchive$FileEntryIterator$EntryComparator.class
      399  2017-03-03 15:28   org/springframework/boot/loader/archive/Archive$EntryFilter.class
      273  2017-03-03 15:28   org/springframework/boot/loader/archive/ExplodedArchive$1.class
    17141  2017-03-03 15:28   org/springframework/boot/loader/PropertiesLauncher.class
        0  2017-03-11 17:03   org/springframework/boot/loader/util/
     4887  2017-03-03 15:28   org/springframework/boot/loader/util/SystemPropertyUtils.class
---------                     -------
 14428721                     107 files
```

依存ライブラリが jar ファイルのまま内包されていることが分かる。内包する jar ファイルをクラスパスに含めつつアプリケーションの main メソッド (ここでは FortuneApplication.main) を叩くため、spring-boot-loader のクラス群があらかじめ jar ファイル内に展開されている。

この jar ファイルを使ってアプリケーションを起動するには、java コマンドを叩けばいい。

```
$ java -jar target/fortune-0.0.1-SNAPSHOT.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v1.5.2.RELEASE)

2017-03-11 17:08:05.071  INFO 12061 --- [           main] org.genva.FortuneApplication             : Starting FortuneApplication v0.0.1-SNAPSHOT on carrot with PID 12061 (/home/kazuki/sources/writing/spring/fortune/target/fortune-0.0.1-SNAPSHOT.jar started by kazuki in /home/kazuki/sources/writing/spring/fortune)
(snip)
2017-03-11 17:08:07.998  INFO 12061 --- [           main] s.b.c.e.t.TomcatEmbeddedServletContainer : Tomcat started on port(s): 8080 (http)
2017-03-11 17:08:08.002  INFO 12061 --- [           main] org.genva.FortuneApplication             : Started FortuneApplication in 3.364 seconds (JVM running for 3.902)
```

Eclipse から起動したときと異なり、メインスレッドの名前が main となっていることが分かる。spring-boot:repackage により、spring-boot-devtools が除外されているため。特に難しいことは考えることなく、リリースする jar ファイルでは spring-boot-devtools による余計な制御が行われないようになっている。

デプロイするには、この jar ファイルを適当な場所におき、systemd なりから叩くようにすればよい。詳しくは Spring Boot の[リファレンス](http://docs.spring.io/spring-boot/docs/current/reference/html/deployment-install.html)参照。

ここでは紹介しないが、war ファイルとしてパッケージングし、任意の Servlet コンテナにデプロイすることもできる。詳しくは (やはり) [リファレンス](http://docs.spring.io/spring-boot/docs/current/reference/html/build-tool-plugins-maven-plugin.html#build-tool-plugins-maven-packaging)を参照。

## 組み込み Tomcat の起動プロセスを追う ##

少し Spring Boot の中を覗いてみることにする。

Spring Boot は、Auto Configuration とそこから駆動される便利クラス群から成り立っている。まずは組み込み Tomcat が使われることを決定付ける Auto Configuration を見てみる。

Eclipse で `org.apache.catalina.startup.Tomcat` クラスの参照を探すと、 `org.springframework.boot.autoconfigure.web.EmbeddedTomcat` というクラスが見つかる。パッケージ名に autoconfigure とあることから、これが Tomcat を使うよう決定づける Auto Configuration であると推測できる。

```java
/**
 * Nested configuration if Tomcat is being used.
 */
@Configuration
@ConditionalOnClass({ Servlet.class, Tomcat.class })
@ConditionalOnMissingBean(value = EmbeddedServletContainerFactory.class, search = SearchStrategy.CURRENT)
public static class EmbeddedTomcat {

	@Bean
	public TomcatEmbeddedServletContainerFactory tomcatEmbeddedServletContainerFactory() {
		return new TomcatEmbeddedServletContainerFactory();
	}

}
```

`EmbeddedServletContainerFactory` の実装として、 `TomcatEmbeddedServletContainerFactory` を Bean 定義している。こいつが Tomcat のインスタンスを作っているものと推測できる。なお、この設定 (`EmbeddedTomcat`) が有効になるのは、 `javax.servlet.Servlet` と `org.apache.catalina.startup.Tomcat` がクラスパス内に存在し、かつ `EmbeddedServletContainerFactory` の Bean 定義がない場合に限る。独自に `EmbeddedServletContainerFactory` の Bean を定義したり、Web 環境でない場合には、この設定は有効とならない。このように、実行時の環境、条件に応じて設定の有効/無効が自動的に切り替わることから、Auto Configuration と呼ばれている。

次に `TomcatEmbeddedServletContainerFactory` を追う。

```java
@Override
public EmbeddedServletContainer getEmbeddedServletContainer(
		ServletContextInitializer... initializers) {
	Tomcat tomcat = new Tomcat();
    // (snip)
	return getTomcatEmbeddedServletContainer(tomcat);
}
```

Tomcat のインスタンスを作り、`TomcatEmbeddedServletContainer` でラップして返している。

このメソッドの参照を Eclipse で探すと、`EmbeddedWebApplicationContext` が見つかる。ソースを読むと、`onRefresh` メソッド経由で `getEmbeddedServletContainer` を呼び出していることが分かる。

```java
@Override
protected void onRefresh() {
	super.onRefresh();
	try {
		createEmbeddedServletContainer();
	}
	catch (Throwable ex) {
		throw new ApplicationContextException("Unable to start embedded container",
				ex);
	}
}
```

`onRefresh` は、Spring の IoC コンテナを `refresh` したときに呼び出されるフックである。ApplicationContext の実装ごとの、特別な Bean の準備するために呼び出される。アプリケーションの起動時はもちろん、spring-boot-devtools でアプリケーションのクラスローダーを再読み込みするときにも呼び出される。以上が Servlet コンテナの構築の流れとなる。

続けて、起動の流れを追う。`TomcatEmbeddedServletContainer.start` の参照を探すと、先ほどと同様に `EmbeddedWebApplicationContext` が見つかる。さらに追っていくと、`finishRefresh` 経由で呼び出していることが分かる。

```java
@Override
protected void finishRefresh() {
	super.finishRefresh();
	EmbeddedServletContainer localContainer = startEmbeddedServletContainer();
	if (localContainer != null) {
		publishEvent(
				new EmbeddedServletContainerInitializedEvent(this, localContainer));
	}
}
```

`finishRefresh` は IoC コンテナの `refresh` が完了するタイミングで呼び出されるフックである。すなわち Bean 定義の読み込みや設定がひと通り終わったタイミングで Servlet コンテナが動き始める。

FortuneApplication の main メソッドで呼び出している `SpringApplication.run` では、実際に利用する ApplicationContext の決定が行われる。Web 環境で使われるデフォルトの ApplicationContext の実装は、`org.springframework.boot.context.embedded.AnnotationConfigEmbeddedWebApplicationContext` となっている。`AnnotationConfigEmbeddedWebApplicationContext` は `EmbeddedWebApplicationContext` のサブクラスである。

```java
public static final String DEFAULT_WEB_CONTEXT_CLASS = "org.springframework."
		+ "boot.context.embedded.AnnotationConfigEmbeddedWebApplicationContext";

(snip)

protected ConfigurableApplicationContext createApplicationContext() {
	Class<?> contextClass = this.applicationContextClass;
	if (contextClass == null) {
		try {
			contextClass = Class.forName(this.webEnvironment
					? DEFAULT_WEB_CONTEXT_CLASS : DEFAULT_CONTEXT_CLASS);
		}
		catch (ClassNotFoundException ex) {
			throw new IllegalStateException(
					"Unable create a default ApplicationContext, "
							+ "please specify an ApplicationContextClass",
					ex);
		}
	}
	return (ConfigurableApplicationContext) BeanUtils.instantiate(contextClass);
}
```

これにより、

 * IoC コンテナの実装として `EmbeddedWebApplicationContext` が使われ、
 * `onRefresh` で Tomcat のインスタンスが作られ、
 * `finishRefresh` で Tomcat が動き出す

ということが分かった。

Tomcat の起動プロセスがわかったところで「だからなんだ」という話なのだが、黒魔術だらけの Spring Boot であっても、順を追って調べれば、どうにかその中身を理解できるということを試したかった。中身についての知識や、解析方法がわかっていれば、何か問題や課題にぶつかったとき、落ち着いて対処することができる。