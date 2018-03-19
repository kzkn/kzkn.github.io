+++
title = "はじめての Spring IoC コンテナ"
draft = false
date = "2017-03-15T21:34:43+09:00"

+++

広大な Spring Framework の世界において、その中心 (というより底という表現がしっくりくるかもしれない) にあるのが IoC コンテナです。Spring Boot を使ってお気楽ご気楽にプログラミングできるのも、AOP で宣言的ほげほげできるのも、全部 IoC コンテナの下支えがあってこそ。Spring Boot を使ってアプリケーション開発する場合においても、それを支える IoC コンテナの知識があるのとないのとでは、開発、問題解決の効率が格段に変わってくるでしょう、たぶん。

Java は 10 年ぐらい触っているが、Web アプリケーションの開発に携わる機会に恵まれず、おのずと Spring Framework を触る機会もなかった。最近になって Web 開発案件に携わり、Spring Boot を採用し、Spring 童貞を卒業した。が、Spring 本体であるところの IoC コンテナの知識が乏しく、問題にぶつかるたびに Google と格闘していた。そこで今一度、Spring Boot をよりよく使うためにも、IoC コンテナについてお勉強したのだった。

# 用語 #

まずは Spring の IoC コンテナを語る上で把握しておくべき用語について触れる。

## IoC とは ##

IoC = Inversion of Cotnrol = 制御の反転

ライブラリ vs フレームワークみたいな話だと理解している。ライブラリはアプリケーションから制御されるが、フレームワークはアプリケーションを制御する。(一般的に) フレームワークは IoC に則っていると言える。

A -> B に依存関係があるとき、A が B を呼び出すのが通常の制御、B が A を呼び出すのが反転した制御。GUI フレームワークなんかは反転した制御の典型。アプリは GUI フレームワークに依存しているが、すべての制御は GUI フレームワーク側が行う。例えば Java の Swing なら EDT でループを回すのは GUI フレームワークの仕事。

https://ja.wikipedia.org/wiki/%E5%88%B6%E5%BE%A1%E3%81%AE%E5%8F%8D%E8%BB%A2

> ソフトウェア工学において、制御の反転（Inversion of Control、IoC）とは、コンピュータ・プログラムの中で、個別の目的のために書かれたコード部分が、一般的で再利用可能なライブラリによるフロー制御を受ける形の設計を指す。この設計を採用した ソフトウェアアーキテクチャは、伝統的な手続き型プログラミングと比べると制御の方向が反転している。すなわち、従来の手続き型プログラミングでは、個別に開発するコードが、そのプログラムの目的を表現しており、汎用的なタスクを行う場合に再利用可能なライブラリを呼び出す形で作られる。一方、制御を反転させたプログラミングでは、再利用可能なコードの側が、個別目的に特化したコードを制御する。

## IoC コンテナとは ##

アプリケーションを構成するオブジェクトの組み立てを行う人。オブジェクト同士の依存関係は、オブジェクト自身が解決するのではなく、IoC コンテナが解決する。

http://kakutani.com/trans/fowler/injection.html

> ここで疑問なのは、軽量コンテナは制御のどういった側面を反転させているのか、ということだ。 私がはじめて制御の反転というものに遭遇したとき、それはユーザインタフェースのメインループのことだった。 初期のユーザインターフェースは、アプリケーションプログラムで制御されていた。 「名前の入力」「住所の入力」みたいな一連のコマンドを取り扱いたいとなれば、 プログラムでプロンプトの表示と、それぞれの入力を制御する。 これがグラフィカルなUI(コンソールベースでもいいけど)になると、UIフレームワークにはメインループがあり、フレームワークからスクリーンの様ざまなフィールドの代わりとしてイベントハンドラが提供されている。プログラムではこのイベントハンドラを取り扱う。ここではプログラムの中心となる制御が反転されている。制御は個々のプログラムからフレームワークへと移されているのだ。
>
> 新種のコンテナにおいて反転されているのは、プラグイン実装のルックアップ方法である。 私の素朴なサンプルでいえば、MovieLister は MovieFinder の実装を直接インスタンス化することでルックアップしている。 これだと、ファインダはプラグインではなくなっている。 新種のコンテナが採用しているアプローチには、プラグインを利用するにあたって必ず従わなければならない取り決めが存在する。 この規約があることで、コンテナはMovieFinder 実装を MovieLister オブジェクトにインジェクト(inject: 注入)することが可能になる。
>
> 結論をいえば、このパターンにはもっと明確な名前が必要なように思う。 「制御の反転」という用語では包括的すぎる。これでは混乱する人が出てくるのも無理はない。 様ざまな IoC 支持者と多くの議論を重ねた末、その名前は Dependency Injection (依存オブジェクト注入)に落ち着いた。

DI (Dependency Injection) は IoC の一種である。Spring の IoC コンテナが提供しているのは DI なので、Spring においては IoC コンテナ = DI コンテナと言ってよさそう。

ここでいう **コンテナ** とは、「雑多なオブジェクトを自身の管理下におき、それらを協調させるオブジェクトのこと」と理解している。2000 年代の Java 界隈では何かとコンテナと呼ばれるものがあった (今もある)。Servlet コンテナ、EJB コンテナ、軽量コンテナ etc... Spring の IoC コンテナは、最後の軽量コンテナに属する。今どきコンテナと言えば Docker に代表されるそれだが、Spring の文脈では別の意味となる。

## Bean ##

Spring の IoC コンテナによって管理されるオブジェクトを Bean と呼ぶ。[JavaBeans](https://ja.wikipedia.org/wiki/JavaBeans) とは違う。

Spring の設定とは、すなわち Bean の設定のことを指す。

 * どのような Bean を定義するか
 * Bean にどのようなプロパティを与えるか
 * Bean をどのように初期化するか
 * Bean をどのように破棄するか
 * どの Bean と Bean をつなげるか

といった設定を IoC コンテナに食わせると、IoC コンテナは Bean のオブジェクトツリーを構築し、適切に生成/破棄を行う。

IoC コンテナが扱うオブジェクトは、基本的には POJO である。特定のインタフェースの実装することや、アノテーションをつけることが求められる場合もある。POJO なので、ユニットテストではふつうに new できる。

# コンテナの表現 #

Spring の IoC コンテナは `ApplicationContext` インタフェースで表現されている。実装のバリエーションは[いくつもある](http://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/context/ApplicationContext.html)。

Spring Boot では `SpringApplication` クラスが `ApplicationContext` の実装を選択している。デフォルトでは `AnnotationConfigApplicationContext` か `AnnotationConfigEmbeddedWebApplicationContext` を[使うようになっている](https://github.com/spring-projects/spring-boot/blob/67556ba8eaf22a352b03fe197a0c452f695835a6/spring-boot/src/main/java/org/springframework/boot/SpringApplication.java#L167)。

設定の読み込み、Bean の管理、依存関係の解決などは `ApplicationContext` によって提供される。Spring の中心には常に ApplicationContext がある。

厳密には、Bean の管理と依存関係の解決は `BeanFactory` によって提供される。`ApplicationContext` は `BeanFactory` のスーパーセットである。`ApplicationContext` と `BeanFactory` の比較は[リファレンス](http://docs.spring.io/spring/docs/current/spring-framework-reference/htmlsingle/#context-introduction-ctx-vs-beanfactory)が詳しい。アプリケーション開発においては、よほど特別な理由がない限り `BeanFacotry` を直接使うことはなさそう。

# BeanPostProcessor #

IoC コンテナを拡張するためのインタフェースとして `BeanPostProcessor` がある。このインタフェースは 2 つのメソッドを提供する:

 * `Object postProcessBeforeInitialization(Object bean, String beanName)`
 * `Object postProcessAfterInitialization(Object bean, String beanName)`

いずれも Bean のインスタンスと名前を受け取り、オブジェクトを返す。戻り値のオブジェクトが、与えられた名前の Bean のインスタンスとして使われる。

それぞれ Bean の初期化前と初期化後に呼ばれるメソッドである。ここでいう初期化とは、`InitializingBean` の `afterPropertiesSet` の呼び出しや Bean の `initMethod` に指定したメソッドの呼び出しのことを指す。つまり、IoC コンテナが Bean のインスタンスを生成し、依存関係を解決し、初期化メソッドを呼び出す前後で呼び出されるフックであると言える。

この仕組みは Spring の中で広く使われている。AOP を始め、Bean の Validation、定期実行など。どのような実装があるかは [BeanPostProcessor の Javadoc](http://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/beans/factory/config/BeanPostProcessor.html) が詳しい。

アプリケーション開発でこの仕組みを直接使うことはないかもしれないが、このような仕組みの存在を覚えておくと、Spring がどのようにして魔法のような機能を実現しているか、なんとなく想像できる。例えば AOP なら、メソッドの引数で受け取ったオブジェクトの Proxy を返すように実装すれば、実現できそうである (実際そうなっているかはさておき)。

# Java Config #

かつての Spring は XML による設定だけを提供していたが、最近のバージョンでは Java Config と呼ばれるアノテーションベースの設定方法が用意されている。Spring Boot は、デフォルトで Java Config を使うようになっているので、Java Config による設定についてのみ触れる。

基本となるのは `@Bean` と `@Configuration` である。

## @Configuration ##

`@Configuration` はクラスにつけるアノテーションである。そのクラスが設定を主としたクラスであることを、IoC コンテナに知らせるためのマーカーである。

```java
@Configuration
public class Config {
  // ...
}
```

このクラスの中に、設定を書いていく。

## @Bean ##

`@Bean` はメソッドにつけるアノテーションである。メソッドが Bean 定義であることを IoC コンテナに知らせるためのマーカーである。メソッドの戻り値は IoC コンテナによって管理される Bean となる。

```java
@Configuration
public class Config {
  @Bean
  public MyApiGateway myApiGateway() {
    return new MyApiGateway();
  }
}
```

Bean に依存関係を設定するには、メソッドの引数を使う。

```java
@Configuration
public class Config {
  @Bean
  public HttpClient httpClient() {
    return new HttpClient();
  }
  
  @Bean
  public MyApiGateway myApiGateway(HttpClient httpClient) {
    return new MyApiGateway(httpClient);
  }
}
```

MyApiGateway は HttpClient に依存する。依存する HttpClient もまた Bean として定義されている。MyApiGateway が依存する HttpClient のインスタンスは、IoC コンテナによって与えられる。

## @Scope ##

Bean のライフサイクルは IoC コンテナによって管理される。デフォルトでは、コンテナの起動時にインスタンス化され、シングルトンとして扱われる。すなわちひとつのオブジェクトが全ての場所で共有される。そしてコンテナの終了とともに、インスタンスも破棄される。

Bean のライフサイクルを変えたい (= シングルトンにしたくない) 場合には `@Scope` を使う。Spring では、Bean がいつ生成され、いつ破棄されるかを、Bean の「スコープ」と表現している。

```java
@Configuration
public class Config {
  @Bean
  public HttpClient httpClient() {
    return new HttpClient();
  }
  
  @Bean
  @Scope("prototype")
  public MyApiGateway myApiGateway(HttpClient httpClient) {
    return new MyApiGateway(httpClient);
  }
}
```

デフォルトで用意されているスコープは以下の通り:

 * singleton
    * シングルトン。デフォルト
 * prototype
    * ApplicationContext.getBean するたびに new する。

基本的にはこの 2 つ。Web 向けとして:

 * request
 * session
 * globalSession
 * application
 * websocket

が用意されている。

http://docs.spring.io/spring/docs/current/spring-framework-reference/htmlsingle/#beans-factory-scopes が詳しい。

## @Component ##

`@Component` はクラスにつけるアノテーションである。このアノテーションをつけたクラスが、IoC コンテナの管理対象であることを知らせるためのマーカーである。`@Component` がついたクラスは `@Bean` による Bean 定義を書かずとも、IoC コンテナの管理対象になる。同じような役割の Bean が大量にある場合には、いちいち `@Bean` で Bean を定義していくよりも手軽で使いでがある。

`@Component` はクラスだけでなくアノテーションにもつけることができる (= メタアノテーション)。`@Component` がついたアノテーションをつけたクラスもまた、IoC コンテナの管理対象として扱われる。`@Component` がついたアノテーションはステレオタイプと呼ばれたりもする。

典型的なコンポーネントとして、3 つのステレオタイプが用意されている:

 * `@Controller`
    * Web アプリケーションのコントローラクラスであることを表す
 * `@Service`
    * サービス層のクラスであることを表す
 * `@Repository`
    * 永続層のクラスであることを表す

例えば以下のクラスは `@Bean` による Bean 定義を書かずとも、IoC コンテナによって、適切に DI が行われ、オブジェクトが管理される。

```java
@Service
public class AuthService {
  private UsersRepository users;
  
  public AuthService(UsersRepository users) {
    this.users = users;
  }

  // ...
}
```

## @Autowired ##

かつての XML 設定では Bean の依存関係の解決は、設定ファイルで明示的に指定するのが基本だった。後に [Autowire](http://docs.spring.io/spring/docs/current/spring-framework-reference/htmlsingle/#beans-factory-autowire) と呼ばれる依存関係の自動解決の仕組みが入った。これは XML ファイルによる設定でも使える。Java Config では `@Autowired` アノテーションを使って、Autowire の設定を行う。

Spring 4.3 から、コンストラクタには `@Autowired` を使わなくても [Autowire されるようになった](http://docs.spring.io/spring/docs/current/spring-framework-reference/htmlsingle/#_core_container_improvements_3)。

```java
@Component
public class Spring42 {
  @Autowired
  public Spring42(MyBean obj) { }
}

@Component
public class Spring43 {
  public Spring43(MyBean obj) { }
}
```

フィールドインジェクション、セッターインジェクション (メソッドインジェクション) を使う場合には `@Autowired` を使う。

```java
@Component
public class MyBean1 {
  @Autowired
  private MyBean2 obj;
  
  @Autowired
  public void setup(MyBean3 a, MyBean4 b) { }
}
```

IoC コンテナが MyBean1 を構築する際、`@Autowired` がついたメンバを探す。`@Autowired` がついたメンバの型 (フィールドならその型、メソッドならパラメータの型) を持つオブジェクトに依存するものと判断する。IoC コンテナはこれらの型を自身から探してきて

## @Value ##

`@Value` はフィールドやメソッドのパラメータにつけるアノテーションである。構造を持ったオブジェクトではなく、整数や文字列といった単純な値をコンテナから与えてもらうときに使う。

```java
@Configuration
public class Config {
  @Bean
  public MyApiGateway myApiGateway(@Value("${myapi.baseurl}") String baseUrl) {
    return new MyApiGateway(baseUrl);
  }
}
```

`@Value` の引数には [SpEL](http://docs.spring.io/spring/docs/current/spring-framework-reference/htmlsingle/#expressions) を書く。上の例では `${myapi.baseurl}` としており、これはプロパティ `myapi.baseurl` を `baseUrl` に設定することを表現している。

## @PostConstruct, @PreDestroy ##

Bean の構築後、破棄前にフックをかけることができる。`@PostConstruct` は構築後、`@PreDestroy` は破棄前に呼ばれるメソッドにつけるアノテーションである。これらのアノテーションは Spring 独自ではなく [JSR-250](https://en.wikipedia.org/wiki/JSR_250) で標準化されているアノテーションである。

```java
public class MyApiGateway {
  private HttpClient client;
  
  public MyApiGateway(HttpClient httpClient) {
    this.httpClient = httpClient;
  }

  @PostConstruct
  public void init() {
    httpClient.post("http://mygreatapi.example.com/hello");
  }
  
  @PreDestroy
  public void destroy() {
    httpClient.post("http://mygreatapi.example.com/bye");
  }
}
```

`@PostConstruct` は DI が完了した状態で呼ばれる。

なお、Java Config では Bean 定義を Java プログラムのメソッド内に書くので、Bean を new したあとに初期化メソッドを呼んでしまえば済む話である。

```java
@Bean
public MyApiGateway myApiGateway() {
  MyApiGateway gw = new MyApiGateway();
  gw.init();
  return gw;
}
```

`@Component` がついたクラスの場合にはこのようなことができないので、`@PostConstruct` を使って初期化メソッドを書く。

# Environment #

Spring では実行環境を `Environment` インタフェースによって抽象化している。実行環境には、

 * プロファイル
 * プロパティ
    * 環境変数
    * JVM のシステムプロパティ
    * プロパティファイルによる設定

を含む。

プロファイルは **モード** みたいなもの。よくあるのは、開発中は develop プロファイル、リリース版は production プロファイルを指定する、みたいな感じである。プロファイルごとに有効な設定を切り替えることができる。Bean 定義をプロファイルごとに変えることもできる。

# 終わりに #

まとめは特にない。途中途中、説明が雑になっているのは、長くなりすぎてダレてしまったからであると白状しておく。

これぐらい覚えておけば Spring Boot がどんな感じで動いているのか、なんとなく想像できるんじゃなかろうか。
